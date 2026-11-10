---
name: handoff
description: Compact the current conversation into a handoff document for another agent or session to pick up.
argument-hint: "What will the next session be used for?"
---

# Handoff

Write a handoff document summarising the current conversation so a fresh agent can continue the work.

## Instructions

1. Save the document to `$TMPDIR/safe-handoff-<date>.md` (not the workspace).

2. Include:
   - **Current state**: what was accomplished in this session
   - **Next action**: the single most important thing to do next
   - **Open questions**: unresolved decisions or blockers
   - **Suggested skills**: which `.claude/commands/` skills the next session should use
   - **References**: paths or URLs to relevant artifacts (don't duplicate content)

3. Do not duplicate content already in `CLAUDE.md`, commits, or specs. Reference them by path instead.

4. Redact any sensitive information.

5. If the user passed arguments, treat them as a description of what the next session will focus on and tailor the doc accordingly.

## Notes for SAFE project

Always reference:
- `CLAUDE.md` for full project context
- `instructivo/semana-47-recoleccion-masiva/` for the data collection steps
- `parse_metrics.py` for the metrics pipeline
- `resultados/` for existing CSV outputs
