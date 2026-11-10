# SAFE — AI-Enhanced Honeypots Lab

Proyecto de tesis de maestría (UPPA, Seguridad Informática 2026).  
**Autores:** Miguel E. Mendoza Chavarría & Mario C. Velez Zamarrón

## Hipótesis

Un honeypot SSH aumentado con LLM (Cowrie + Ollama) captura TTPs MITRE ATT&CK
más ricos y genera mayor engagement depth que un honeypot convencional (Cowrie shell),
a costa de mayor latencia y menor estabilidad.

---

## Dos condiciones experimentales

| | Condición A | Condición B |
|---|---|---|
| Contenedor | `safe-honeypot` | `safe-honeypot-llm` |
| Backend Cowrie | `shell` | `llm` (Ollama) |
| Logs | `logs/cowrie.json` | `logs-b/cowrie.json` |
| Latencia (piloto) | ~1 500 ms | ~40 000 ms (CPU) |
| Estabilidad (piloto) | 100 % | 78 % (timeouts Ollama a 60 s) |

Ambas condiciones corren en la misma red Docker interna (`safe-net`, `internal: true`).
La Condición B además conecta a `llm-net` para alcanzar Ollama en el host vía
`host.docker.internal:11434`.

---

## Estado del experimento (Semana 47, 9 Nov 2026)

| Semana | Estado | Qué se hizo |
|--------|--------|-------------|
| 43 | ✅ | Infraestructura base, Condición A operacional |
| 44 | ✅ | Condición B + 4 bug fixes (BUG-01..04) |
| 45 | ✅ | 30 escenarios MITRE ATT&CK, 30/30 OK en ambas condiciones |
| 46 | ✅ | `parse_metrics.py` + piloto sobre 30 escenarios |
| 47 | ✅ | Instructivo de recolección masiva (10 rondas × 2 condiciones) |
| 48–49 | ⏳ | Recolección masiva pendiente + análisis estadístico + paper V0 |

**Siguiente acción concreta:** ejecutar las 10 rondas de recolección según
`instructivo/semana-47-recoleccion-masiva/` y verificar ≥300 `cowrie.command.input`
por condición antes de exportar el CSV final a `resultados/`.

---

## Estructura del repo

```
SAFE-cowrie/
├── docker-compose.yml          # 4 servicios: honeypot, honeypot-llm, attacker, log-collector
├── honeypot/
│   ├── cowrie.cfg              # Condición A (backend=shell)
│   ├── cowrie-llm.cfg          # Condición B (backend=llm)
│   ├── userdb.txt              # Credenciales SSH (compartidas)
│   ├── llm_protocol_patch.py  # Parche BUG-01..03
│   └── llm_session_patch.py   # Parche BUG-04 (TTY log sesiones exec)
├── attacker/Dockerfile         # Ubuntu 22.04 + herramientas de ataque
├── scenarios/
│   ├── run_all.sh              # Ejecuta s01–s30; TIMEOUT auto por condición
│   └── s01–s30/               # Scripts individuales MITRE ATT&CK
├── parse_metrics.py            # Parser: engagement depth, CTI, latencia, estabilidad
├── resultados/                 # CSVs de salida (metricas_semana46_piloto.csv)
├── instructivo/                # Guía paso a paso por semana/etapa
│   ├── 00-preparacion-host/
│   ├── semana-43-condicion-a/
│   ├── semana-44-condicion-b/
│   └── semana-47-recoleccion-masiva/
└── docs/
    └── reporte_fase1.html      # Informe técnico Semanas 43–44
```

---

## Bugs corregidos en el módulo LLM de Cowrie 3.1.3

- **BUG-01** — Race condition EOF: canal SSH se cerraba antes de recibir respuesta LLM
- **BUG-02** — Comandos exec no se registraban en `cowrie.json`
- **BUG-03** — Ollama anteponía `"assistant\n\n"` a sus respuestas
- **BUG-04** — Sesiones exec etiquetadas como interactivas → hash `sha256("")` →
  duplicados descartados (fix en `llm_session_patch.py`)

---

## Métricas del experimento (`parse_metrics.py`)

| Métrica | Descripción |
|---------|-------------|
| `engagement_depth` | Número de comandos por sesión |
| `cti_richness` | Técnicas ATT&CK únicas detectadas (keyword matching, 50 reglas) |
| `tactic_count` | Tácticas ATT&CK únicas (9 posibles) |
| `latency_p50/p95` | Latencia por sesión en ms |
| `stability` | % sesiones sin timeout (umbral: 60 000 ms) |

Mapeo MITRE: keyword matching sobre `cowrie.command.input.input`; no depende de
`session.params` (ausente en Condición B).

---

## Comandos frecuentes

```bash
# Levantar el entorno
docker compose up -d

# Verificar Condición A
docker exec safe-attacker sshpass -p "admin" \
  ssh -o StrictHostKeyChecking=no safe-honeypot -p 2222 "id"

# Verificar Condición B
docker exec safe-attacker sshpass -p "admin" \
  ssh -o StrictHostKeyChecking=no safe-honeypot-llm -p 2222 "id"

# Correr los 30 escenarios (Condición A)
docker exec safe-attacker bash /scenarios/run_all.sh safe-honeypot

# Correr los 30 escenarios (Condición B)
docker exec safe-attacker bash /scenarios/run_all.sh safe-honeypot-llm

# Parsear métricas
python3 parse_metrics.py logs/cowrie.json logs-b/cowrie.json --csv resultados/metricas.csv
```

---

## Consideraciones importantes

- Cowrie está **pinned a 3.1.3** — los parches en `honeypot/` son para esa versión.
- Ollama corre en el **host Mac** (no en Docker); en CPU tarda ~40 s por respuesta
  con `llama3.2:3b`. Con GPU bajaría a ~2 s.
- `safe-net` tiene `internal: true` — ni honeypots ni atacante tienen internet.
- Los directorios `logs/` y `logs-b/` están en `.gitignore`; los datos de experimentos
  se commitean en `resultados/` como CSV.
- El timeout de Cowrie para el LLM es 60 s (`LLM_TIMEOUT_MS = 60_000` en el parser).
  Sesiones que superan ese tiempo cuentan como inestables pero el `cowrie.command.input`
  igualmente se registra en `cowrie.json`.
