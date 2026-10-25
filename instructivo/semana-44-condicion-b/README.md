# Semana 44 — Honeypot híbrido LLM (Condición B)

**Responsable:** Miguel · **Tiempo estimado:** 45–60 min
**Objetivo:** añadir un segundo honeypot, idéntico al de la Condición A salvo en que las respuestas a los comandos las genera un LLM local (Ollama + `llama3.2:3b`), y corregir los cuatro bugs del módulo LLM experimental de Cowrie 3.1.3.

**Prerrequisito:** [Semana 43](../semana-43-condicion-a/) completada, con `safe-honeypot` corriendo.

## Arquitectura al terminar esta etapa

```
[safe-attacker] ──safe-net (internal)──► [safe-honeypot]      (Condición A, shell)
                                        ──► [safe-honeypot-llm]  (Condición B, LLM)
                                                   │
                                              llm-net (bridge)
                                                   │
                                        [Ollama en el host :11434]
```

¿Por qué dos redes? `safe-net` sigue siendo interna (el atacante nunca sale a internet), pero el honeypot LLM necesita llegar a Ollama en el host. Se añade `llm-net`, una red normal a la que **solo** se conecta `safe-honeypot-llm`.

---

## Paso 1 — Descargar el modelo

```bash
ollama pull llama3.2:3b
```

```
# Salida esperada al final:
writing manifest
success
```

## Paso 2 — Comprobar la API de Ollama

El backend LLM de Cowrie habla con una API compatible con OpenAI. Comprobarla antes evita diagnosticar a ciegas después:

```bash
curl -s http://localhost:11434/v1/chat/completions \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ollama" \
  -d '{"model": "llama3.2:3b",
       "messages": [{"role": "user", "content": "respond with only: ok"}],
       "max_tokens": 5}' | python3 -m json.tool | grep content
```

```
# Salida esperada:
"content": "ok"
```

## Paso 3 — Configuración de Cowrie (Condición B)

Es la misma configuración que `cowrie.cfg` más dos cambios: `backend = llm` en `[honeypot]`, y la sección `[llm]`.

```bash
cat > honeypot/cowrie-llm.cfg << 'EOF'
[honeypot]
hostname = prod-web-01
backend = llm
log_path = var/log/cowrie
download_path = var/lib/cowrie/downloads
share_path = share/cowrie
state_path = var/lib/cowrie
etc_path = etc
contents_path = honeyfs
txtcmds_path = share/cowrie/txtcmds
ttylog = true
ttylog_path = var/lib/cowrie/tty
uid_min = 1000
auth_class = UserDB

[output_jsonlog]
enabled = true
logfile = var/log/cowrie/cowrie.json

[output_textlog]
enabled = true
logfile = var/log/cowrie/cowrie.log

[ssh]
enabled = true
version = SSH-2.0-OpenSSH_8.9p1 Ubuntu-3ubuntu0.6
listen_endpoints = tcp:2222:interface=0.0.0.0
sftp_enabled = true

[llm]
enabled = true
api_key = ollama
model = llama3.2:3b
host = http://host.docker.internal:11434
path = /v1/chat/completions
max_tokens = 500
temperature = 0.7
rate_limit_enabled = false
debug = false
system_prompt = You are a Linux shell on an Ubuntu 22.04 LTS server named prod-web-01. When given a command, respond with ONLY the exact text that would appear in a terminal after running it — nothing before, nothing after. No role labels, no markdown, no explanations. Maintain state: track cwd changes with cd, remember files created or deleted. Use realistic UIDs, paths, and timestamps. Return the exact shell error message for unknown commands (e.g. "bash: foo: command not found"). Never reveal you are an AI or a honeypot.
system_prompt_exec = You are a Linux shell on an Ubuntu 22.04 LTS server named prod-web-01. When given a command, respond with ONLY the exact text a real terminal would show after running it — no role label, no markdown, no prose, nothing else. Return the exact shell error for unknown commands. Never reveal you are an AI or a honeypot.
EOF
```

Puntos clave de `[llm]`:

- `host = http://host.docker.internal:11434`: desde el contenedor, `host.docker.internal` es el host (se define en el `docker-compose.yml` del paso 8).
- `api_key = ollama`: Ollama no valida la clave, pero el cliente de Cowrie exige una.
- `rate_limit_enabled = false`: el limitador está pensado para APIs de pago; en el laboratorio cortaría las sesiones del experimento.
- `system_prompt` se usa en sesiones interactivas y `system_prompt_exec` en comandos pasados por SSH (`ssh host "comando"`).

```bash
grep -E "^(backend|model|host) " honeypot/cowrie-llm.cfg
# Salida esperada:
# backend = llm
# model = llama3.2:3b
# host = http://host.docker.internal:11434
```

## Paso 4 — Directorio de logs de la Condición B

```bash
mkdir -p logs-b && chmod 777 logs-b
```

## Paso 5 — Extraer los archivos originales del módulo LLM

Los parches se aplican sobre una copia de los archivos de la imagen y luego se montan encima del original con un volumen. Se copian desde `safe-honeypot`, que usa la misma imagen:

```bash
docker logs safe-honeypot 2>&1 | grep "Cowrie Version"
# Salida esperada: ... Cowrie Version 3.1.3
```

> **Versión:** los parches están escritos para **Cowrie 3.1.3**. La imagen es `cowrie/cowrie:latest`, así que una versión más nueva puede cambiar el código; en ese caso los scripts de los pasos 6 y 7 fallan con un mensaje claro en lugar de dejar un archivo roto.

```bash
docker cp safe-honeypot:/cowrie/cowrie-git/src/cowrie/llm/protocol.py honeypot/llm_protocol_patch.py
docker cp safe-honeypot:/cowrie/cowrie-git/src/cowrie/llm/session.py  honeypot/llm_session_patch.py
```

## Paso 6 — Parchear `protocol.py` (BUG-01, BUG-02, BUG-03)

| Bug | Síntoma | Causa | Corrección |
|-----|---------|-------|-----------|
| **BUG-01** | `ssh host "id"` devuelve salida vacía | El cliente SSH cierra stdin ~3 ms después de mandar el comando; `eofReceived()` cierra el canal antes de que llegue la respuesta del LLM | `HoneyPotExecProtocol.eofReceived()` solo anota el EOF; el canal lo cierra `_handle_exec_response` al llegar la respuesta |
| **BUG-02** | Los comandos exec no aparecen en `cowrie.json` | `_process_exec_with_llm` nunca emite `cowrie.command.input` | Emitir el evento antes de llamar al LLM, como hace el backend shell |
| **BUG-03** | Las respuestas empiezan por `assistant` | El prompt exec solo tiene mensaje `system`, y el modelo responde con su etiqueta de rol | Mandar el comando como mensaje `user` y limpiar etiquetas de rol en `strip_markdown()` |

Aplicar los tres parches (copia y pega el bloque completo):

```bash
python3 - <<'PYEOF'
p = "honeypot/llm_protocol_patch.py"
src = open(p).read()

parches = [
    # BUG-03 (a): docstring de strip_markdown
    ("BUG-03 docstring",
     "    Remove markdown code block formatting from LLM responses.\n",
     "    Remove markdown code block formatting and LLM role artifacts from responses.\n"),
    # BUG-03 (b): quitar la etiqueta de rol "assistant\n\n" que antepone el modelo
    ("BUG-03 strip_markdown",
     '    text = text.replace("`", "")\n    return text.strip()\n',
     '    text = text.replace("`", "")\n'
     '    # Strip role labels that some models emit (e.g. "assistant\\n\\n")\n'
     '    text = re.sub(r"^(assistant|user|system)\\s*\\n+", "", text, flags=re.IGNORECASE)\n'
     '    return text.strip()\n'),
    # BUG-02 + BUG-03 (c): registrar el comando exec y mandarlo como mensaje de usuario
    ("BUG-02 log + mensaje user",
     "        # Construct the prompt\n"
     "        system_context = self._build_system_context(exec_command=self.execcmd)\n"
     "\n"
     "        prompt = [system_context]\n",
     "        # Log command for CTI analysis (mirrors cowrie.command.input in shell backend)\n"
     '        self.events.dispatch("cowrie.command.input", "CMD: %(input)s", input=self.execcmd)\n'
     "\n"
     "        # Construct the prompt — include the exec command as a user message so\n"
     "        # the model knows to respond (not emit a role label prefix).\n"
     "        system_context = self._build_system_context(exec_command=self.execcmd)\n"
     "\n"
     "        prompt = [system_context, self.execcmd]\n"),
    # BUG-01: no cerrar el canal exec al recibir EOF de stdin
    ("BUG-01 eofReceived",
     "    def keystrokeReceived(self, keyID, modifier):\n",
     "    def eofReceived(self) -> None:\n"
     "        # Stdin EOF on an exec channel means the client sent no more input,\n"
     "        # not that the command finished — keep the channel alive until the\n"
     "        # async LLM response arrives and _handle_exec_response calls\n"
     "        # processEnded.  The base-class implementation would close the\n"
     "        # channel immediately, which races with the LLM round-trip.\n"
     "        self._stdin_eof = True\n"
     "\n"
     "    def keystrokeReceived(self, keyID, modifier):\n"),
]

for nombre, viejo, nuevo in parches:
    assert src.count(viejo) == 1, f"{nombre}: texto original no encontrado — ¿otra versión de Cowrie?"
    src = src.replace(viejo, nuevo)
    print("✓", nombre)

open(p, "w").write(src)
PYEOF
```

```
# Salida esperada:
✓ BUG-03 docstring
✓ BUG-03 strip_markdown
✓ BUG-02 log + mensaje user
✓ BUG-01 eofReceived
```

## Paso 7 — Parchear `session.py` (BUG-04)

| Bug | Síntoma | Causa | Corrección |
|-----|---------|-------|-----------|
| **BUG-04** | Todos los TTY logs de la Condición B se llaman `e3b0c442…` y desde la segunda sesión se borran (`"duplicate": true` en `cowrie.log.closed`) | `LoggingServerProtocol` detecta las sesiones exec comparando con la clase del backend **shell**; la del backend LLM nunca coincide, así que se tratan como interactivas: el comando no entra al TTY log, el nombre del log es el SHA-256 de una entrada vacía y todos colisionan | Marcar la sesión como exec (`type = "e"`) en `execCommand` |

Este bug también hacía que la salida exec de la Condición B usara saltos `\r\n` (la A usa `\n`), una diferencia observable por el atacante.

```bash
python3 - <<'PYEOF'
p = "honeypot/llm_session_patch.py"
src = open(p).read()

viejo = (
    "            protocol.HoneyPotExecProtocol, self, cmd\n"
    "        )\n"
    "        self.protocol.makeConnection(processprotocol)\n"
)
nuevo = (
    "            protocol.HoneyPotExecProtocol, self, cmd\n"
    "        )\n"
    "        # LoggingServerProtocol detects exec sessions by identity against\n"
    "        # cowrie.shell.protocol.HoneyPotExecProtocol, so the LLM exec protocol\n"
    '        # was tagged interactive ("i"): the command never reached the ttylog,\n'
    '        # every log hashed to sha256("") and all but the first were discarded\n'
    "        # as duplicates. Tag it as exec explicitly, like the shell backend.\n"
    '        self.protocol.type = "e"\n'
    "        self.protocol.makeConnection(processprotocol)\n"
)
assert src.count(viejo) == 1, "BUG-04: texto original no encontrado — ¿otra versión de Cowrie?"
open(p, "w").write(src.replace(viejo, nuevo))
print("✓ BUG-04 TTY log exec")
PYEOF
```

```
# Salida esperada:
✓ BUG-04 TTY log exec
```

Comprobación: los dos archivos resultantes deben ser idénticos a los del repositorio (`git diff --stat honeypot/` no muestra cambios si trabajas sobre un clon).

## Paso 8 — `docker-compose.yml` completo

Reemplaza el archivo de la Semana 43 por la versión final. Cambios respecto a la Semana 43: red `llm-net`, servicio `honeypot-llm` con los dos parches montados, y `logs-b` en el recolector.

```bash
cat > docker-compose.yml << 'EOF'
networks:
  safe-net:
    driver: bridge
    internal: true   # no internet access — isolated lab network
  llm-net:
    driver: bridge   # non-internal: lets honeypot-llm reach host.docker.internal for Ollama

services:

  honeypot:
    image: cowrie/cowrie:latest
    container_name: safe-honeypot
    hostname: prod-web-01
    networks:
      - safe-net
    volumes:
      - ./honeypot/cowrie.cfg:/cowrie/cowrie-git/etc/cowrie.cfg:ro
      - ./honeypot/userdb.txt:/cowrie/cowrie-git/etc/userdb.txt:ro
      - ./logs:/cowrie/cowrie-git/var/log/cowrie
    restart: unless-stopped

  honeypot-llm:
    image: cowrie/cowrie:latest
    container_name: safe-honeypot-llm
    hostname: prod-web-01
    networks:
      - safe-net   # attacker reaches it here (isolated)
      - llm-net    # Ollama API calls go out through this network
    extra_hosts:
      - "host.docker.internal:host-gateway"
    volumes:
      - ./honeypot/cowrie-llm.cfg:/cowrie/cowrie-git/etc/cowrie.cfg:ro
      - ./honeypot/userdb.txt:/cowrie/cowrie-git/etc/userdb.txt:ro
      - ./honeypot/llm_protocol_patch.py:/cowrie/cowrie-git/src/cowrie/llm/protocol.py:ro
      - ./honeypot/llm_session_patch.py:/cowrie/cowrie-git/src/cowrie/llm/session.py:ro
      - ./logs-b:/cowrie/cowrie-git/var/log/cowrie
    restart: unless-stopped

  attacker:
    build: ./attacker
    container_name: safe-attacker
    hostname: kali-attacker
    networks:
      - safe-net
    depends_on:
      - honeypot
      - honeypot-llm
    tty: true
    stdin_open: true

  log-collector:
    image: alpine:latest
    container_name: safe-logs
    networks:
      - safe-net
    volumes:
      - ./logs:/logs
      - ./logs-b:/logs-b
    command: sh -c "tail -F /logs/cowrie.json 2>/dev/null || while true; do sleep 5; done"
    depends_on:
      - honeypot
      - honeypot-llm
    restart: unless-stopped
EOF
```

`extra_hosts: host.docker.internal:host-gateway` hace que ese nombre resuelva al host también en Linux (en macOS Docker Desktop ya lo define).

## Paso 9 — Levantar el entorno completo

```bash
docker compose up -d --force-recreate
sleep 15
docker compose ps
```

`--force-recreate` es necesario porque un simple `restart` no aplica volúmenes nuevos.

```
# Salida esperada — 4 contenedores en Up:
safe-attacker       Up ...
safe-honeypot       Up ...
safe-honeypot-llm   Up ...
safe-logs           Up ...
```

Comprobar que el honeypot LLM llega a Ollama:

```bash
docker exec safe-honeypot-llm /cowrie/cowrie-env/bin/python3 -c \
  "import urllib.request; print(urllib.request.urlopen('http://host.docker.internal:11434/api/version').read())"
# Salida esperada: b'{"version":"..."}'
```

## Paso 10 — Verificar la Condición B

```bash
docker exec safe-attacker sshpass -p "admin" \
  ssh -o StrictHostKeyChecking=no safe-honeypot-llm -p 2222 "id"
```

```
# Salida esperada (~300 ms en el Mac; 10–15 s en un equipo sin GPU):
uid=0(root) gid=0(root) groups=0(root)
```

La respuesta la genera el LLM, así que puede variar entre ejecuciones (p. ej. `gid=0(system)`). Eso es esperable y forma parte de lo que mide el experimento.

```bash
docker exec safe-attacker sshpass -p "admin" \
  ssh -o StrictHostKeyChecking=no safe-honeypot-llm -p 2222 "uname -a"
```

Y la Condición A debe seguir igual:

```bash
docker exec safe-attacker sshpass -p "admin" \
  ssh -o StrictHostKeyChecking=no safe-honeypot -p 2222 "id"
# Salida esperada (instantánea): uid=0(root) gid=0(root) groups=0(root)
```

## Paso 11 — Verificar los logs de ambas condiciones

Eventos de la última sesión de cada condición:

```bash
python3 -c "
import json
for label, path in [('A', 'logs/cowrie.json'), ('B', 'logs-b/cowrie.json')]:
    L = [json.loads(l) for l in open(path)]
    s = L[-1]['session']
    print('## Condición', label)
    for o in L:
        if o['session'] == s:
            print(f'  {o[\"eventid\"]:28} | {o.get(\"input\", o.get(\"username\", \"\"))}')
"
```

```
# Salida esperada:
## Condición A
  cowrie.session.connect       |
  cowrie.client.version        |
  cowrie.client.kex            |
  cowrie.login.success         | root
  cowrie.session.params        |
  cowrie.command.input         | id
  cowrie.log.closed            |
  cowrie.session.closed        |
## Condición B
  cowrie.session.connect       |
  cowrie.client.version        |
  cowrie.client.kex            |
  cowrie.login.success         | root
  cowrie.command.input         | uname -a
  cowrie.log.closed            |
  cowrie.session.closed        |
```

La Condición B no emite `cowrie.session.params` (el backend LLM no lo emite); el parser de métricas de la Semana 46 no debe depender de ese evento.

Comprobar los TTY logs (BUG-04):

```bash
python3 -c "
import json
for o in [json.loads(l) for l in open('logs-b/cowrie.json')][-30:]:
    if o['eventid'] == 'cowrie.log.closed':
        print(o['session'], o['shasum'][:12], 'duplicate=', o['duplicate'])
"
```

```
# Salida esperada — hashes distintos para comandos distintos, ninguno e3b0c44298fc:
<sesión>  a56145270ce6  duplicate= False     ← id (mismo hash que en la Condición A)
<sesión>  28ba533b0f3c  duplicate= False     ← uname -a
```

> Dos sesiones con **exactamente** el mismo comando sí generan el mismo hash y la segunda se marca como duplicada, en ambas condiciones. Es el comportamiento normal de Cowrie (el nombre depende solo de la entrada). En la Condición B esto descarta la salida del LLM de las repeticiones; si el análisis de consistencia la necesita, hay que tomarla de otra fuente.

## Checklist de cierre

- [ ] Los 4 contenedores en `Up`
- [ ] `safe-honeypot-llm` alcanza `host.docker.internal:11434`
- [ ] La Condición B responde por SSH con texto generado por el LLM
- [ ] La Condición A sigue respondiendo igual que en la Semana 43
- [ ] `logs-b/cowrie.json` contiene `cowrie.command.input`
- [ ] Los TTY logs de B no se llaman `e3b0c442…` ni se marcan duplicados para comandos distintos

## Problemas frecuentes

| Síntoma | Causa | Solución |
|---------|-------|----------|
| Condición B responde vacío | BUG-01 sin aplicar, o el volumen de `protocol.py` no se montó | `docker exec safe-honeypot-llm /cowrie/cowrie-env/bin/python3 -c "print('_stdin_eof' in open('/cowrie/cowrie-git/src/cowrie/llm/protocol.py').read())"` debe imprimir `True`; si no, `docker compose up -d --force-recreate honeypot-llm` |
| Condición B responde vacío y en `docker logs safe-honeypot-llm` aparece `LLM exec error` / `Connection refused` | El contenedor no llega a Ollama | macOS: comprobar que Ollama está abierto. Linux: revisar el `OLLAMA_HOST=0.0.0.0` de la [Etapa 0](../00-preparacion-host/) (`ss -ltn \| grep 11434` debe mostrar `*:11434`) |
| La respuesta empieza por `assistant` | BUG-03 sin aplicar | `grep IGNORECASE honeypot/llm_protocol_patch.py`; si no aparece, repetir los pasos 5–6 y recrear el contenedor |
| No aparece `cowrie.command.input` en `logs-b/cowrie.json` | BUG-02 sin aplicar | `grep "cowrie.command.input" honeypot/llm_protocol_patch.py`; repetir pasos 5–6 |
| TTY logs `e3b0c442…` con `duplicate: true` | BUG-04 sin aplicar o `session.py` sin montar | Repetir pasos 5 y 7, comprobar el volumen en el paso 8 y recrear |
| `AssertionError: ... texto original no encontrado` | La imagen trae una versión de Cowrie distinta de 3.1.3 | Copiar de nuevo los originales (paso 5) y revisar a mano el texto alrededor de cada punto de parche |
| `safe-honeypot-llm` se reinicia en bucle | `PermissionError` en `logs-b/` | `chmod 777 logs-b` |
| La respuesta tarda 10–15 s | Ollama corre en CPU | Ver el punto B5 de la [Etapa 0](../00-preparacion-host/); válido para pruebas, no para medir latencia |
