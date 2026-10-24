# safe-honeypot-lab

**SAFE Project — AI-Enhanced Honeypots** · UPPA Máster Seguridad Informática 2026  
Miguel E. Mendoza Chavarría & Mario C. Velez Zamarrón

## Objetivo

Comparar un honeypot SSH convencional (Cowrie shell, **Condición A**) contra un honeypot híbrido determinista-LLM (Cowrie + Ollama, **Condición B**), midiendo engagement depth, riqueza CTI, TTPs MITRE ATT&CK, latencia y estabilidad en un entorno de laboratorio aislado.

## Estructura

```
.
├── docker-compose.yml          # 4 servicios, 2 redes Docker
├── honeypot/
│   ├── cowrie.cfg              # Condición A (backend=shell)
│   ├── cowrie-llm.cfg          # Condición B (backend=llm, Ollama)
│   ├── userdb.txt              # Credenciales SSH compartidas
│   └── llm_protocol_patch.py  # Parche: 3 bugs corregidos en el módulo LLM
├── attacker/
│   └── Dockerfile              # Ubuntu 22.04 + herramientas de ataque
├── logs/                       # Logs Condición A (gitignored)
├── logs-b/                     # Logs Condición B (gitignored)
└── docs/
    ├── reporte_fase1.html      # Informe técnico Semanas 43–44
    └── instructivo_semana44.html  # Guía paso a paso para recrear el entorno
```

## Requisitos

- Docker Desktop (macOS, Apple Silicon o Intel)
- [Ollama](https://ollama.com) con modelo `llama3.2:3b`
- 16 GB RAM mínimo

## Inicio rápido

```bash
# 1. Instalar Ollama y descargar el modelo
ollama pull llama3.2:3b

# 2. Crear directorios de logs con permisos correctos
mkdir -p logs logs-b && chmod 777 logs logs-b

# 3. Levantar el entorno
docker compose up -d

# 4. Verificar Condición A (shell estático)
docker exec safe-attacker sshpass -p "admin" \
  ssh -o StrictHostKeyChecking=no safe-honeypot -p 2222 "id"

# 5. Verificar Condición B (LLM ~300ms)
docker exec safe-attacker sshpass -p "admin" \
  ssh -o StrictHostKeyChecking=no safe-honeypot-llm -p 2222 "id"
```

Ver `docs/instructivo_semana44.html` para la guía completa paso a paso.

## Arquitectura de red

```
[safe-attacker] ──safe-net (internal)──► [safe-honeypot]      (Condición A)
                                        ──► [safe-honeypot-llm]  (Condición B)
                                                   │
                                              llm-net (bridge)
                                                   │
                                        [Ollama en host Mac :11434]
```

`safe-net` tiene `internal: true` — sin internet para atacantes ni honeypots.  
`llm-net` permite al honeypot LLM alcanzar Ollama via `host.docker.internal`.

## Cronograma

| Semana | Responsable | Tarea |
|--------|-------------|-------|
| 43 | Miguel | Infraestructura base (Condición A) ✅ |
| 44 | Miguel | Honeypot LLM (Condición B) + 3 bug fixes ✅ |
| 45 | Mario | 30 escenarios MITRE ATT&CK |
| 46 | Miguel | Script replay + parser de métricas + piloto |
| 47 | Mario | 600 sesiones (30 × ≥10 × 2 condiciones) |
| 48–49 | Ambos | Procesamiento de datos + paper V0 |

## Bugs corregidos en el módulo LLM de Cowrie

1. **BUG-01** — Race condition EOF: el canal SSH se cerraba antes de recibir la respuesta LLM
2. **BUG-02** — Los comandos exec no se registraban en `cowrie.json`
3. **BUG-03** — Ollama anteponía `"assistant\n\n"` a sus respuestas

Ver `docs/reporte_fase1.html` para análisis detallado.
