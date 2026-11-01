# Semana 45 — 30 escenarios MITRE ATT&CK

**Responsable:** Mario · **Tiempo estimado:** 60–90 min  
**Objetivo:** montar los 30 escenarios de ataque post-autenticación SSH, cada uno mapeado a técnicas MITRE ATT&CK, y verificar que se ejecutan correctamente contra ambas condiciones.

**Prerrequisito:** [Semana 44](../semana-44-condicion-b/) completada (los 4 contenedores en `Up`).

---

## Resumen de los 30 escenarios

| Grupo | Escenarios | Táctica ATT&CK |
|-------|-----------|----------------|
| Descubrimiento | S01–S08 | Discovery (TA0007) |
| Acceso a credenciales | S09–S13 | Credential Access (TA0006) |
| Persistencia | S14–S17 | Persistence (TA0003) |
| Escalada de privilegios | S18–S20 | Privilege Escalation (TA0004) |
| Evasión de defensas | S21–S24 | Defense Evasion (TA0005) |
| Ejecución / descarga | S25–S27 | Execution (TA0002) + Command & Control (TA0011) |
| Recolección | S28–S29 | Collection (TA0009) |
| Impacto | S30 | Impact (TA0040) |

La tabla completa (técnicas ATT&CK, comandos, nivel de complejidad) está en [`scenarios/README.md`](scenarios/README.md).

---

## Paso 1 — Añadir el volumen de escenarios al atacante

El servicio `attacker` de la Semana 44 no tenía volumen para scripts. Hay que añadir uno que monte la carpeta `scenarios/` del repositorio en `/scenarios` dentro del contenedor:

```bash
# Edita docker-compose.yml — añade estas líneas bajo el servicio attacker:
#   volumes:
#     - ./scenarios:/scenarios:ro
```

Edición exacta (copia y pega):

```bash
python3 - <<'PYEOF'
p = "docker-compose.yml"
src = open(p).read()

viejo = (
    "  attacker:\n"
    "    build: ./attacker\n"
    "    container_name: safe-attacker\n"
    "    hostname: kali-attacker\n"
    "    networks:\n"
    "      - safe-net\n"
    "    depends_on:\n"
    "      - honeypot\n"
    "      - honeypot-llm\n"
    "    tty: true\n"
    "    stdin_open: true\n"
)
nuevo = (
    "  attacker:\n"
    "    build: ./attacker\n"
    "    container_name: safe-attacker\n"
    "    hostname: kali-attacker\n"
    "    networks:\n"
    "      - safe-net\n"
    "    depends_on:\n"
    "      - honeypot\n"
    "      - honeypot-llm\n"
    "    volumes:\n"
    "      - ./scenarios:/scenarios:ro\n"
    "    tty: true\n"
    "    stdin_open: true\n"
)
assert src.count(viejo) == 1, "Texto original no encontrado — ¿ya aplicado?"
open(p, "w").write(src.replace(viejo, nuevo))
print("✓ volumen scenarios añadido")
PYEOF
```

```
# Salida esperada:
✓ volumen scenarios añadido
```

## Paso 2 — Crear la carpeta de escenarios

```bash
mkdir -p scenarios
```

Copia los scripts del repositorio (si estás siguiendo el instructivo sobre el clon del repo, ya están en `instructivo/semana-45-escenarios-mitre/scenarios/`):

```bash
cp instructivo/semana-45-escenarios-mitre/scenarios/*.sh scenarios/
chmod +x scenarios/*.sh
ls scenarios/*.sh | wc -l
# Salida esperada: 31   (30 escenarios + run_all.sh)
```

## Paso 3 — Recrear el contenedor atacante

Los volúmenes no se aplican con `restart`; hay que recrear el contenedor:

```bash
docker compose up -d --force-recreate attacker
sleep 5
docker compose ps attacker
```

```
# Salida esperada:
NAME            IMAGE                         STATUS
safe-attacker   safe-honeypot-lab-attacker    Up ...
```

Verificar que el volumen está montado:

```bash
docker exec safe-attacker ls /scenarios/ | head -5
# Salida esperada: s01_system_info.sh  s02_network_discovery.sh  ...
```

## Paso 4 — Formato de cada escenario

Cada script acepta un argumento opcional: el nombre del contenedor-honeypot objetivo (por defecto `safe-honeypot`, la Condición A).

```
./scenarios/sNN_nombre.sh [safe-honeypot | safe-honeypot-llm]
```

Internamente, cada script:

1. Define `TARGET` y construye el alias `SSH`.
2. Ejecuta los comandos de la secuencia con `$SSH "comando"`.
3. Imprime `[OK]` o `[FAIL]` según el código de salida del último comando.

Ejemplo de cabecera (S01):

```bash
#!/usr/bin/env bash
# S01 — System Information Discovery
# Tactic : Discovery (TA0007)
# Technique: T1082 System Information Discovery
TARGET="${1:-safe-honeypot}"
SSH="sshpass -p admin ssh -o StrictHostKeyChecking=no -o ConnectTimeout=30 ${TARGET} -p 2222"
```

> Los scripts se ejecutan **dentro** del contenedor `safe-attacker` (que comparte `safe-net` con los honeypots), no desde el host. Ver el Paso 5.

## Paso 5 — Ejecutar un escenario a mano

Contra la Condición A (shell estático, instantáneo):

```bash
docker exec safe-attacker bash /scenarios/s01_system_info.sh safe-honeypot
```

Contra la Condición B (backend LLM, ~300 ms por comando en Mac con GPU):

```bash
docker exec safe-attacker bash /scenarios/s01_system_info.sh safe-honeypot-llm
```

Ejemplo de salida:

```
=== S01 System Information Discovery — safe-honeypot ===
uid=0(root) gid=0(root) groups=0(root)
root
Linux prod-web-01 5.15.0 #1 SMP x86_64 GNU/Linux
prod-web-01
Sun Nov  1 00:00:00 UTC 2026
[OK]
```

## Paso 6 — Ejecutar todos los escenarios contra una condición

```bash
# Condición A
docker exec safe-attacker bash /scenarios/run_all.sh safe-honeypot

# Condición B (tarda más por las llamadas al LLM)
docker exec safe-attacker bash /scenarios/run_all.sh safe-honeypot-llm
```

`run_all.sh` registra el tiempo por escenario y escribe un resumen al final:

```
=== RUN ALL — safe-honeypot ===
S01 system_info            OK  0.4 s
S02 network_discovery      OK  0.3 s
...
S30 crypto_miner           OK  0.4 s
---
30/30 OK  · total 12.3 s
```

## Paso 7 — Verificar los logs tras un escenario

Los eventos de la última sesión de cada condición:

```bash
python3 -c "
import json
for label, path in [('A', 'logs/cowrie.json'), ('B', 'logs-b/cowrie.json')]:
    lines = [json.loads(l) for l in open(path)]
    last_session = lines[-1]['session']
    inputs = [o.get('input','') for o in lines
              if o['session'] == last_session and o['eventid'] == 'cowrie.command.input']
    print(f'Condición {label} — {len(inputs)} comandos:')
    for i in inputs: print('  ', i)
"
```

Cada comando del escenario debe aparecer como `cowrie.command.input`. Si alguno falta, el script tiene un error de sintaxis o el honeypot no responde a ese comando.

## Checklist de cierre

- [ ] `docker-compose.yml` actualizado con el volumen `scenarios/`
- [ ] 31 scripts presentes en `scenarios/` (`ls scenarios/*.sh | wc -l` → 31)
- [ ] `docker exec safe-attacker ls /scenarios/` lista los scripts
- [ ] `s01_system_info.sh safe-honeypot` devuelve `[OK]` en < 2 s
- [ ] `s01_system_info.sh safe-honeypot-llm` devuelve `[OK]` (puede tardar ~2–5 s)
- [ ] `logs/cowrie.json` y `logs-b/cowrie.json` contienen `cowrie.command.input` del escenario

Continúa con la [Semana 46](../semana-46-replay-metricas/).

## Problemas frecuentes

| Síntoma | Causa | Solución |
|---------|-------|----------|
| `ls /scenarios/` está vacío | El volumen no se montó o el contenedor no se recreó | `docker compose up -d --force-recreate attacker` |
| `sshpass: not found` | La imagen del atacante no tiene `sshpass` | La imagen incluye `sshpass` desde la Semana 43; si falta, reconstruir con `docker compose build --no-cache attacker` |
| `bash: /scenarios/sNN.sh: Permission denied` | Script sin bit de ejecución en el host | `chmod +x scenarios/*.sh` en el host |
| El escenario devuelve `[FAIL]` en la Condición A | El comando no está en los `txtcmds` de Cowrie (devuelve error) | Esperado para comandos reales como `cat /etc/shadow`; Cowrie devuelve "command not found" — cuenta como interacción válida |
| La Condición B tarda > 60 s por escenario | Ollama en CPU con modelo grande | Verificar que Ollama usa la GPU (ver Semana 44, Paso 1); para pruebas, `ConnectTimeout` en los scripts puede ampliarse a 90 |
| `AssertionError: Texto original no encontrado` (Paso 1) | El volumen ya estaba en `docker-compose.yml` | No hace falta reaplicar; verificar con `grep scenarios docker-compose.yml` |
