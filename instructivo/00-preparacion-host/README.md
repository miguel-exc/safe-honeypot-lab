# Etapa 0 — Preparación del host

**Objetivo:** dejar la máquina anfitriona con Docker, Docker Compose y Ollama funcionando, de forma que los contenedores puedan alcanzar a Ollama.
**Tiempo estimado:** 15–30 min.

Sigue **solo la sección de tu sistema operativo** (A o B) y después la verificación común (C).

---

## A. macOS (configuración original del proyecto)

### A1. Docker Desktop

1. Descarga Docker Desktop desde https://www.docker.com/products/docker-desktop/ (elige Apple Silicon o Intel).
2. Instálalo y ábrelo. Espera a que el icono de la ballena en la barra de menú indique *Docker Desktop is running*.
3. En *Settings → Resources* asigna al menos 4 GB de RAM a Docker.

```bash
docker --version
docker compose version
```

### A2. Ollama

Descarga el `.dmg` desde https://ollama.com/download y arrástralo a Aplicaciones. Al abrirlo queda como servicio en la barra de menú.

En macOS, Docker Desktop resuelve `host.docker.internal` hacia el Mac automáticamente, así que **no hace falta configurar nada más**. Salta a la sección C.

---

## B. Linux (Ubuntu / Debian)

En Linux hay que hacer a mano tres cosas que en macOS resuelve Docker Desktop.

### B1. Docker Engine y el plugin Compose

```bash
sudo apt update
sudo apt install -y docker.io docker-compose-v2
sudo systemctl enable --now docker
```

### B2. Permitir usar Docker sin `sudo`

```bash
sudo usermod -aG docker $USER
```

> **Importante:** el grupo nuevo solo aplica a sesiones nuevas. **Cierra sesión y vuelve a entrar** (o reinicia). Abrir otra terminal no basta.

Comprobación (tras volver a entrar):

```bash
docker ps
# Salida esperada: una tabla vacía con cabecera CONTAINER ID ... (sin "permission denied")
```

### B3. Ollama

```bash
curl -fsSL https://ollama.com/install.sh | sh
```

### B4. Hacer que Ollama sea accesible desde los contenedores

Por defecto Ollama en Linux escucha solo en `127.0.0.1`, y los contenedores no pueden llegar ahí. Se configura para escuchar en todas las interfaces:

```bash
sudo mkdir -p /etc/systemd/system/ollama.service.d
sudo nano /etc/systemd/system/ollama.service.d/override.conf
```

Contenido del archivo:

```ini
[Service]
Environment="OLLAMA_HOST=0.0.0.0:11434"
```

Guarda (`Ctrl+O`, Enter, `Ctrl+X`) y reinicia el servicio:

```bash
sudo systemctl daemon-reload
sudo systemctl restart ollama
ss -ltn | grep 11434
# Salida esperada:
# LISTEN 0  4096  *:11434  *:*
```

> **Seguridad:** `0.0.0.0` expone Ollama también a tu red local. Si la máquina está en una red compartida, bloquea el puerto 11434 desde fuera con el firewall (p. ej. `sudo ufw deny in on <interfaz-wifi> to any port 11434`).

### B5. Advertencia de rendimiento

Si la máquina no tiene una GPU soportada por Ollama (NVIDIA, o AMD con ROCm), el modelo corre en CPU. Comprueba:

```bash
ollama run llama3.2:3b "hola" >/dev/null; curl -s localhost:11434/api/ps | grep -o '"size_vram":[0-9]*'
# "size_vram":0  → el modelo corre solo en CPU
```

En CPU la Condición B tarda **~10–15 s por comando** en lugar de ~300 ms. Sirve para desarrollar y probar, pero **las mediciones de latencia y la recolección de la Semana 47 deben hacerse en la misma máquina de referencia** (el Mac) para que los resultados sean comparables.

---

## C. Verificación común

```bash
docker --version
docker compose version
ollama --version
curl -s http://localhost:11434/api/version
# Salida esperada: {"version":"..."}
```

Cuando los cuatro comandos respondan, continúa con la [Semana 43](../semana-43-condicion-a/).

## Problemas frecuentes

| Síntoma | Causa | Solución |
|---------|-------|----------|
| `docker: unknown command: docker compose` | Falta el plugin Compose | `sudo apt install docker-compose-v2` (Linux) o actualizar Docker Desktop (macOS) |
| `permission denied while trying to connect to the docker API` | El usuario no está en el grupo `docker` o no se volvió a iniciar sesión | Repetir B2 y **cerrar sesión**; mientras tanto usar `sudo docker ...` |
| `sudo: A terminal is required to authenticate` | Se ejecutó `sudo` desde una herramienta sin terminal interactiva | Ejecutar el comando en una terminal normal |
| `curl localhost:11434` no responde | Ollama no está corriendo | macOS: abrir la app Ollama. Linux: `sudo systemctl start ollama` |
