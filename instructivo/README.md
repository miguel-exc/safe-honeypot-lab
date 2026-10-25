# Instructivo — montaje manual paso a paso

Guía para construir el laboratorio **safe-honeypot-lab** desde cero, a mano, sin scripts de automatización ni agentes de IA. Cada carpeta corresponde a una etapa del cronograma del proyecto y se sigue en orden: cada etapa parte del estado que deja la anterior.

| Etapa | Carpeta | Contenido | Estado |
|-------|---------|-----------|--------|
| 0 | [`00-preparacion-host/`](00-preparacion-host/) | Docker, Compose y Ollama en macOS o Linux | ✅ |
| Semana 43 | [`semana-43-condicion-a/`](semana-43-condicion-a/) | Red aislada, atacante y honeypot Cowrie shell (Condición A) | ✅ |
| Semana 44 | [`semana-44-condicion-b/`](semana-44-condicion-b/) | Honeypot Cowrie + LLM (Condición B) y parches BUG-01 a BUG-04 | ✅ |
| Semana 45 | [`semana-45-escenarios-mitre/`](semana-45-escenarios-mitre/) | 30 escenarios MITRE ATT&CK | ⏳ Pendiente |
| Semana 46 | [`semana-46-replay-metricas/`](semana-46-replay-metricas/) | Script de replay, parser de métricas y piloto | ⏳ Pendiente |
| Semana 47 | [`semana-47-recoleccion/`](semana-47-recoleccion/) | 600 sesiones (30 × ≥10 × 2 condiciones) | ⏳ Pendiente |
| Semanas 48–49 | [`semana-48-49-analisis-paper/`](semana-48-49-analisis-paper/) | Procesamiento de datos y paper V0 | ⏳ Pendiente |

## Convenciones

- Todos los comandos se ejecutan desde la raíz del proyecto (la carpeta que contiene `docker-compose.yml`), salvo que se indique lo contrario.
- `# Salida esperada` muestra lo que debe aparecer si el paso salió bien. Si no coincide, no avances: revisa la sección **Problemas frecuentes** de esa etapa.
- En Linux, si tu usuario no está en el grupo `docker`, antepón `sudo` a los comandos `docker`.
- Los archivos que se crean en cada paso son los mismos que están en la raíz del repositorio; si solo quieres levantar el entorno ya armado, basta con el **Inicio rápido** del [README principal](../README.md).
