# Semana 47 — Recolección masiva: 600 sesiones

**Responsable:** Mario · **Tiempo estimado:** ~8 h (planificar en dos sesiones o de noche)  
**Objetivo:** ejecutar 30 escenarios × 10 rondas × 2 condiciones = 600 sesiones y conservar los logs para el análisis estadístico de las Semanas 48–49.

**Prerrequisito:** [Semana 46](../semana-46-replay-metricas/) completada — piloto validado, `resultados/metricas_semana46_piloto.csv` presente.

> **Máquina de referencia:** ejecutar en el Mac con aceleración GPU (Ollama en Metal). En un equipo con Ollama en CPU la latencia de la Condición B no es comparable con los datos del piloto. Ver [00-preparacion-host](../00-preparacion-host/).

---

## Paso 1 — Verificar que el entorno está en pie

```bash
docker ps --format "table {{.Names}}\t{{.Status}}"
```

Salida esperada (los 4 servicios en `Up`):

```
NAMES                    STATUS
safe-honeypot            Up X minutes
safe-honeypot-llm        Up X minutes
safe-attacker            Up X minutes
safe-log-collector       Up X minutes
```

Si algún contenedor no aparece:

```bash
# Desde la raíz del repositorio
docker compose up -d
```

---

## Paso 2 — Verificar acceso a los escenarios

```bash
# El volumen ./scenarios:/scenarios:ro debe estar montado en el attacker
docker exec safe-attacker ls /scenarios/ | head -5

# Prueba rápida con el escenario 1 en Condición A
docker exec safe-attacker bash /scenarios/s01_system_info.sh safe-honeypot
```

Debe terminar con `[OK]`. Si devuelve `[FAIL]`, el honeypot no responde — revisar con `docker compose logs safe-honeypot`.

---

## Paso 3 — Limpiar logs antes de la recolección

Los logs actuales son del piloto de la Semana 45/46. Truncarlos sin borrar los ficheros (el volumen Docker necesita que existan):

```bash
# Desde la raíz del repositorio
> logs/cowrie.json
> logs-b/cowrie.json
echo "Logs truncados — $(date)"
```

Verificar que quedaron vacíos:

```bash
wc -l logs/cowrie.json logs-b/cowrie.json
# Debe mostrar: 0 logs/cowrie.json  0 logs-b/cowrie.json
```

---

## Paso 4 — Recolección Condición A (10 rondas · ~15 min total)

Ejecutar desde la máquina host (no dentro de un contenedor):

```bash
for i in $(seq 1 10); do
    echo "=== Ronda $i/10 — Condición A ==="
    docker exec safe-attacker bash /scenarios/run_all.sh safe-honeypot
    sleep 5
done
```

Tiempo estimado: ~8 s/escenario × 30 escenarios × 10 rondas = ~40 min.  
Verifica al terminar que se acumularon sesiones:

```bash
python3 -c "
import json
from collections import Counter
lines = [json.loads(l) for l in open('logs/cowrie.json')]
c = Counter(o['eventid'] for o in lines)
print(f'Condición A: {c[\"cowrie.command.input\"]} comandos, {c[\"cowrie.session.connect\"]} sesiones')
"
```

Valor esperado: **≥ 300 `cowrie.command.input`** (10 rondas × 30 escenarios).

---

## Paso 5 — Recolección Condición B (10 rondas · ~7 h total)

> La Condición B usa Ollama (TIMEOUT=180 s/escenario). 30 escenarios × ~80 s media = ~40 min/ronda × 10 rondas ≈ **7 horas**. Planificar de noche o en dos sesiones (ver nota al pie).

```bash
for i in $(seq 1 10); do
    echo "=== Ronda $i/10 — Condición B ==="
    docker exec safe-attacker bash /scenarios/run_all.sh safe-honeypot-llm
    sleep 5
done
```

Para dejarlo corriendo sin supervisión en segundo plano y registrar el progreso:

```bash
# Opción recomendada: nohup + log
nohup bash -c '
  for i in $(seq 1 10); do
    echo "=== Ronda $i/10 — Condición B ===" >> /tmp/ronda_b.log
    docker exec safe-attacker bash /scenarios/run_all.sh safe-honeypot-llm >> /tmp/ronda_b.log 2>&1
    sleep 5
  done
  echo "Condición B TERMINADA — $(date)" >> /tmp/ronda_b.log
' &
echo "PID: $!"
```

Seguir el progreso en otra terminal:

```bash
tail -f /tmp/ronda_b.log
```

Verificar al terminar:

```bash
python3 -c "
import json
from collections import Counter
lines = [json.loads(l) for l in open('logs-b/cowrie.json')]
c = Counter(o['eventid'] for o in lines)
print(f'Condición B: {c[\"cowrie.command.input\"]} comandos, {c[\"cowrie.session.connect\"]} sesiones')
"
```

Valor esperado: **≥ 300 `cowrie.command.input`**.

> **Nota sobre rondas partidas:** si la Condición B se ejecuta en dos sesiones, NO truncar `logs-b/cowrie.json` entre ellas — el parser acumula todas las sesiones del fichero. Anotar cuántas rondas se completaron en cada sesión para el paper.

---

## Paso 6 — Verificación final y exportación

Una vez completadas las 10 rondas de ambas condiciones, ejecutar el parser completo:

```bash
python3 parse_metrics.py logs/cowrie.json logs-b/cowrie.json
```

Rango esperado (600 sesiones totales):

| Métrica | Cond. A | Cond. B |
|---------|---------|---------|
| Sesiones con comandos | ~300 | ~300 |
| Duración media (ms) | < 2 000 | 30 000–50 000 |
| Estabilidad (%) | ~100 % | 70–90 % |
| Técnicas ATT&CK | 26 | 26 |

Exportar el CSV final:

```bash
python3 parse_metrics.py logs/cowrie.json logs-b/cowrie.json \
    --csv resultados/metricas_semana47_final.csv
cat resultados/metricas_semana47_final.csv
```

---

## Paso 7 — Guardar los logs y hacer commit

Los ficheros `logs/` y `logs-b/` están en `.gitignore`. Copiarlos a `resultados/` para conservarlos en el repo:

```bash
cp logs/cowrie.json  resultados/cowrie_A_semana47.json
cp logs-b/cowrie.json resultados/cowrie_B_semana47.json
```

Commit:

```bash
git add resultados/
git add instructivo/semana-47-recoleccion/README.md
git commit -m "feat: Semana 47 — 600 sesiones recolectadas

Recolección masiva: 30 escenarios × 10 rondas × 2 condiciones.
Logs en resultados/cowrie_A_semana47.json y cowrie_B_semana47.json.
Métricas preliminares en resultados/metricas_semana47_final.csv.

Co-Authored-By: Claude Sonnet 4.6 <noreply@anthropic.com>"
```

---

## Checklist de la semana

- [ ] `docker ps` — 4 contenedores en `Up`
- [ ] `s01_system_info.sh safe-honeypot` devuelve `[OK]`
- [ ] Logs truncados (`wc -l` = 0 en ambos)
- [ ] Condición A — 10 rondas completadas, ≥ 300 `cowrie.command.input`
- [ ] Condición B — 10 rondas completadas, ≥ 300 `cowrie.command.input`
- [ ] `parse_metrics.py` sin errores — tabla de 600 sesiones
- [ ] CSV `resultados/metricas_semana47_final.csv` exportado
- [ ] Logs copiados a `resultados/` y commit pusheado
- [ ] Miguel informado — datos listos para Semanas 48–49
