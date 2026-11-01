# Semana 46 — Parser de métricas y piloto

**Responsable:** Miguel · **Tiempo estimado:** 60–90 min  
**Objetivo:** instalar `parse_metrics.py`, ejecutarlo sobre los logs de la Semana 45 y verificar que produce las métricas del experimento antes de la recogida masiva (Semana 47).

**Prerrequisito:** [Semana 45](../semana-45-escenarios-mitre/) completada — `logs/cowrie.json` y `logs-b/cowrie.json` con datos de los 30 escenarios.

---

## Qué mide el experimento

Cuatro métricas por condición (A = shell estático, B = LLM híbrido):

| Métrica | Definición | Campo en cowrie.json |
|---------|-----------|---------------------|
| **Engagement depth** | Duración media de sesión (ms) | `duration_ms` en `cowrie.session.closed` |
| **Riqueza CTI** | Técnicas ATT&CK distintas capturadas | keyword matching sobre `input` |
| **Latencia de respuesta** | Distribución de `duration_ms` (p50, p95) | `duration_ms` en `cowrie.session.closed` |
| **Estabilidad** | % sesiones sin timeout LLM (< 60 000 ms) | `duration_ms` en `cowrie.session.closed` |

### Diferencias estructurales entre condiciones

| Campo | Condición A | Condición B |
|-------|-------------|-------------|
| `cowrie.session.params` | presente | **ausente** |
| `cowrie.command.failed` | presente | **ausente** |
| `cowrie.session.file_download` | posible | ausente |
| `duration_ms` | presente | presente |

> El parser no depende de `cowrie.session.params` (ausente en B).

---

## Paso 1 — Verificar datos disponibles

```bash
wc -l logs/cowrie.json logs-b/cowrie.json
```

Salida esperada (valores de la Semana 45):

```
  675 logs/cowrie.json
  322 logs-b/cowrie.json
  997 total
```

Resumen de eventos:

```bash
python3 -c "
import json
from collections import Counter
for label, path in [('A','logs/cowrie.json'),('B','logs-b/cowrie.json')]:
    lines = [json.loads(l) for l in open(path)]
    c = Counter(o['eventid'] for o in lines)
    print(f'Condición {label}:')
    for k,v in sorted(c.items(), key=lambda x: -x[1]):
        print(f'  {k:35} {v}')
"
```

Verifica que `cowrie.command.input` aparece en ambas condiciones (82 en A, 46 en B tras la Semana 45).

---

## Paso 2 — Confirmar que parse_metrics.py está en el repositorio

El archivo `parse_metrics.py` en la raíz del repositorio ya está incluido en el repo desde la Semana 46.

```bash
ls -l parse_metrics.py
python3 parse_metrics.py --help
```

Salida esperada:

```
usage: parse_metrics.py [-h] [--csv FILE] log_a log_b
```

---

## Paso 3 — Ejecutar el parser

```bash
python3 parse_metrics.py logs/cowrie.json logs-b/cowrie.json
```

### Resultado piloto (Semana 45 — 30 escenarios × 2 condiciones)

```
Métrica                              Cond. A (shell)       Cond. B (LLM)
--------------------------------------------------------------------------
Sesiones con comandos                             82                  46
Comandos totales                                  82                  46
Cmds / sesión (media)                            1.0                 1.0
Duración media (ms)                             1482               40109
Duración p50 (ms)                                183               44985
Duración p95 (ms)                               9993               60037
Sesiones con timeout LLM                           0                  10
Estabilidad (%)                                100.0                78.3
Tácticas ATT&CK                                    9                   9
Técnicas ATT&CK                                   26                  26

Técnicas A: T1003.008, T1005, T1007, T1016, T1036.005, T1049, T1053.003, T1057,
            T1059.004, T1059.006, T1068, T1070.002, T1070.003, T1070.006, T1082,
            T1087.001, T1098.004, T1105, T1136.001, T1496, T1518.001, T1546.004,
            T1548.001, T1548.003, T1552.001, T1552.003
Técnicas B: (idénticas)
```

### Interpretar los números

| Observación | Significado |
|-------------|-------------|
| Sesiones A=82 vs B=46 | La Condición A acumuló sesiones de ejecuciones anteriores; en B se borraron los logs antes del piloto. No afecta la métrica de latencia por sesión. |
| Duración media A=1 482 ms vs B=40 109 ms | Diferencia de 27×. En A el shell responde en < 200 ms; en B Ollama tarda entre 6 s y 60 s. |
| p95 B = 60 037 ms | Los 10 timeouts cuentan como sesiones de 60 s exactos — Cowrie corta la conexión HTTP a Ollama a los 60 s. |
| Estabilidad A=100 % vs B=78.3 % | 10/46 sesiones de B terminaron por timeout de Ollama. El comando **sí fue registrado** en el log; solo falta la respuesta del LLM. |
| Técnicas A = Técnicas B = 26 | Esperado: ambas condiciones ejecutaron los mismos 30 escenarios. |

---

## Paso 4 — Exportar CSV para análisis estadístico

```bash
python3 parse_metrics.py logs/cowrie.json logs-b/cowrie.json --csv resultados/metricas.csv
```

```bash
# Verifica el CSV
cat resultados/metricas.csv
```

Salida esperada:

```
condicion,sessions_with_cmds,total_commands,cmds_per_session,duration_mean_ms,...
A_shell,82,82,1.00,1482,183,9993,0,100.0,9,26,...
B_llm,46,46,1.00,40109,44985,60037,10,78.3,9,26,...
```

El CSV tiene una fila por condición con todas las métricas. Se carga directamente en R o pandas para las pruebas estadísticas del paper.

---

## Paso 5 — Preparar Semana 47 (recogida masiva)

Mario ejecutará `run_all.sh` en modo **batch**: 10 repeticiones de los 30 escenarios por condición = 600 sesiones totales. Antes de que empiece:

### 5a. Limpiar los logs actuales

```bash
# Trunca los logs (no los elimina — los ficheros deben existir para el volumen Docker)
> logs/cowrie.json
> logs-b/cowrie.json
echo "Logs truncados. $(date)"
```

Verifica que los contenedores siguen corriendo:

```bash
docker ps --format "table {{.Names}}\t{{.Status}}"
```

### 5b. Verificar que el attacker tiene acceso a los escenarios

```bash
docker exec safe-attacker ls /scenarios/ | head -5
docker exec safe-attacker bash /scenarios/s01_system_info.sh safe-honeypot
```

Debe responder `[OK]`.

### 5c. Protocolo para la recogida masiva

Mario ejecuta desde el contenedor `safe-attacker`:

```bash
# Cada condición por separado — NO en paralelo (comparten logs)

# Condición A — 10 rondas
for i in $(seq 1 10); do
    echo "=== Ronda $i/10 — Condición A ===" 
    bash /scenarios/run_all.sh safe-honeypot
    sleep 5
done

# Condición B — 10 rondas  
for i in $(seq 1 10); do
    echo "=== Ronda $i/10 — Condición B ===" 
    bash /scenarios/run_all.sh safe-honeypot-llm
    sleep 5
done
```

> La Condición B tarda ~40 min por ronda (30 escenarios × ~80 s media con TIMEOUT=180). Las 10 rondas: ~400 min ≈ 7 h. Planificar en la noche o en dos sesiones.

### 5d. Verificar tras la recogida

```bash
# Debería mostrar ~300 cowrie.command.input por condición
python3 -c "
import json
from collections import Counter
for label, path in [('A','logs/cowrie.json'),('B','logs-b/cowrie.json')]:
    lines = [json.loads(l) for l in open(path)]
    c = Counter(o['eventid'] for o in lines)
    print(f'{label}: {c[\"cowrie.command.input\"]} comandos, {c[\"cowrie.session.connect\"]} sesiones')
"
```

Ejecutar el parser final:

```bash
python3 parse_metrics.py logs/cowrie.json logs-b/cowrie.json --csv resultados/metricas_final.csv
```

---

## Checklist de la semana

- [ ] `wc -l logs/cowrie.json logs-b/cowrie.json` — datos disponibles
- [ ] `python3 parse_metrics.py --help` — script accesible
- [ ] `python3 parse_metrics.py logs/cowrie.json logs-b/cowrie.json` — tabla piloto correcta
- [ ] `--csv resultados/metricas.csv` exportado y verificado
- [ ] Logs truncados y contenedores verificados para Semana 47
- [ ] Mario informado del protocolo de recogida masiva

---

## Commit de esta semana

```bash
git add parse_metrics.py instructivo/semana-46-replay-metricas/README.md
git commit -m "feat: Semana 46 — parse_metrics.py y piloto 30 escenarios

Parser parse_metrics.py: extrae engagement depth, riqueza CTI (26
técnicas ATT&CK), latencia (p50/p95) y estabilidad desde cowrie.json.
Piloto sobre Semana 45: A=1 482 ms media vs B=40 109 ms, estabilidad
A=100 % vs B=78.3 % (10/46 timeouts Ollama a 60 s).

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```
