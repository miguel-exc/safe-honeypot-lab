# Semana 43 — Infraestructura base (Condición A)

**Responsable:** Miguel · **Tiempo estimado:** 30–45 min
**Objetivo:** levantar una red Docker aislada con un contenedor atacante y un honeypot SSH Cowrie con shell emulado (**Condición A**), y comprobar que cada comando queda registrado en `logs/cowrie.json`.

**Prerrequisito:** [Etapa 0](../00-preparacion-host/) completada.

## Arquitectura al terminar esta etapa

```
[safe-attacker] ──safe-net (internal: true)──► [safe-honeypot]  (Cowrie shell, :2222)
                                                       │
                                                  ./logs/  ◄── [safe-logs]
```

`safe-net` es una red **interna**: ningún contenedor tiene salida a internet.

---

## Paso 1 — Crear la estructura de carpetas

```bash
mkdir -p safe-honeypot-lab/{honeypot,attacker,logs}
cd safe-honeypot-lab
```

Todos los pasos siguientes se ejecutan dentro de `safe-honeypot-lab/`.

## Paso 2 — Imagen del atacante

El atacante es un Ubuntu 22.04 con las herramientas que usarán los escenarios: cliente SSH, `sshpass` (para pasar contraseñas sin interacción), `nmap`, `hydra`, `netcat`, etc.

```bash
cat > attacker/Dockerfile << 'EOF'
FROM ubuntu:22.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && apt-get install -y \
    openssh-client \
    sshpass \
    nmap \
    hydra \
    netcat-openbsd \
    curl \
    wget \
    python3 \
    python3-pip \
    iputils-ping \
    dnsutils \
    vim \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /scenarios

CMD ["sleep", "infinity"]
EOF
```

`sleep infinity` mantiene el contenedor vivo para poder ejecutar comandos en él con `docker exec`.

## Paso 3 — Credenciales aceptadas por el honeypot

Formato `usuario:uid:contraseña`. `*` acepta cualquier contraseña; `!` la rechaza siempre.

```bash
cat > honeypot/userdb.txt << 'EOF'
# Cowrie userdb - format: username:uid:password
# * = accept any password, ! = reject always
root:0:root
root:0:toor
root:0:1234
root:0:password
root:0:123456
root:0:admin
root:0:!
admin:1000:admin
admin:1000:password
admin:1000:1234
admin:1000:*
ubuntu:1000:ubuntu
ubuntu:1000:password
ubuntu:1000:*
EOF
```

Son credenciales débiles típicas de campañas de fuerza bruta, para que los escenarios consigan acceso.

## Paso 4 — Configuración de Cowrie (Condición A)

```bash
cat > honeypot/cowrie.cfg << 'EOF'
[honeypot]
hostname = prod-web-01
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
EOF
```

Puntos clave:

- `hostname = prod-web-01` y el banner `SSH-2.0-OpenSSH_8.9p1 Ubuntu-3ubuntu0.6` dan la persona de un servidor web Ubuntu 22.04 de producción.
- `auth_class = UserDB` hace que Cowrie use el `userdb.txt` del paso 3.
- Sin la clave `backend`, Cowrie usa el **shell emulado** (backend `shell`), que es la Condición A.
- `ttylog = true` guarda una grabación de cada sesión en `var/lib/cowrie/tty`.

## Paso 5 — Directorio de logs

Cowrie corre dentro del contenedor con un UID distinto al tuyo, así que el directorio montado debe ser escribible por cualquiera:

```bash
chmod 777 logs
ls -ld logs
# Salida esperada: drwxrwxrwx ... logs
```

## Paso 6 — `docker-compose.yml` (versión Semana 43)

```bash
cat > docker-compose.yml << 'EOF'
networks:
  safe-net:
    driver: bridge
    internal: true   # no internet access — isolated lab network

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

  attacker:
    build: ./attacker
    container_name: safe-attacker
    hostname: kali-attacker
    networks:
      - safe-net
    depends_on:
      - honeypot
    tty: true
    stdin_open: true

  log-collector:
    image: alpine:latest
    container_name: safe-logs
    networks:
      - safe-net
    volumes:
      - ./logs:/logs
    command: sh -c "tail -F /logs/cowrie.json 2>/dev/null || while true; do sleep 5; done"
    depends_on:
      - honeypot
    restart: unless-stopped
EOF
```

> **Ruta importante:** la imagen oficial de Cowrie instala en `/cowrie/cowrie-git/`, **no** en `/cowrie/`. Si los volúmenes apuntan a `/cowrie/etc/...`, Cowrie ignora la configuración sin dar error.

## Paso 7 — Levantar el entorno

```bash
docker compose up -d --build
docker compose ps
```

La primera vez tarda unos minutos (descarga la imagen de Cowrie y construye la del atacante).

```
# Salida esperada:
NAME            IMAGE                        STATUS
safe-attacker   safe-honeypot-lab-attacker   Up ...
safe-honeypot   cowrie/cowrie:latest         Up ...
safe-logs       alpine:latest                Up ...
```

Espera ~10 s a que Cowrie arranque y comprueba:

```bash
docker logs safe-honeypot 2>&1 | grep "Ready to accept SSH"
# Salida esperada: ... [cowrie.ssh.factory.CowrieSSHFactory#info] Ready to accept SSH connections
```

## Paso 8 — Verificar la Condición A

Desde el atacante, conectar por SSH al honeypot y ejecutar comandos:

```bash
docker exec safe-attacker sshpass -p "admin" \
  ssh -o StrictHostKeyChecking=no safe-honeypot -p 2222 "id && hostname"
```

```
# Salida esperada (instantánea):
uid=0(root) gid=0(root) groups=0(root)
prod-web-01
```

Comprobar el aislamiento (el atacante **no** debe tener internet):

```bash
docker exec safe-attacker curl -s -m 5 https://example.com || echo "sin internet: OK"
# Salida esperada: sin internet: OK
```

## Paso 9 — Verificar los logs

```bash
python3 -c "
import json
for line in open('logs/cowrie.json').readlines()[-8:]:
    o = json.loads(line)
    print(f'{o[\"eventid\"]:28} | {o.get(\"input\", o.get(\"username\", \"\"))}')
"
```

```
# Salida esperada (debe aparecer cowrie.command.input):
cowrie.session.connect       |
cowrie.client.version        |
cowrie.client.kex            |
cowrie.login.success         | root
cowrie.session.params        |
cowrie.command.input         | id && hostname
cowrie.log.closed            |
cowrie.session.closed        |
```

`cowrie.command.input` es el evento clave del experimento: sin él no se puede medir engagement ni TTPs.

## Checklist de cierre

- [ ] Los 3 contenedores en `Up`
- [ ] `id && hostname` responde `uid=0(root)...` y `prod-web-01`
- [ ] El atacante no tiene salida a internet
- [ ] `logs/cowrie.json` contiene `cowrie.command.input`

Continúa con la [Semana 44](../semana-44-condicion-b/).

## Problemas frecuentes

| Síntoma | Causa | Solución |
|---------|-------|----------|
| `safe-honeypot` se reinicia en bucle | `PermissionError` al escribir en `logs/` | `chmod 777 logs` y `docker compose restart honeypot` |
| El hostname sale `svr04` en lugar de `prod-web-01` | La configuración no se montó (ruta `/cowrie/` en vez de `/cowrie/cowrie-git/`) | Revisar los volúmenes del paso 6 y `docker compose up -d --force-recreate honeypot` |
| `Permission denied, please try again` en SSH | Contraseña no listada en `userdb.txt` | Usar una de las del paso 3 (p. ej. `root` / `admin`) |
| `ssh: Could not resolve hostname safe-honeypot` | El atacante no está en `safe-net` o el honeypot está caído | `docker compose ps` y `docker network inspect safe-honeypot-lab_safe-net` |
| `logs/cowrie.json` no existe | Cowrie aún no arrancó o no puede escribir | Esperar 10 s; si sigue, ver `docker logs safe-honeypot` |
