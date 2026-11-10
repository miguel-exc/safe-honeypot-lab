---
name: grill-with-docs
description: A relentless interview to sharpen a plan or design, which also creates docs (ADR's and glossary) as we go.
---

# Grill With Docs

A relentless interview to sharpen a plan or design. Combines grilling (challenging questions) with domain modeling (capturing decisions as ADRs and glossary entries).

## Process

1. **Ask hard questions** about the plan or design. Challenge assumptions. Surface hidden constraints. Push until the plan is tight.

2. **Capture decisions** as they emerge:
   - ADRs (Architecture Decision Records) for significant technical choices
   - Glossary entries for domain terms that need shared definitions

3. **Keep grilling** until the design has no major open questions.

## Grilling rules

- Ask one question at a time. Wait for the answer before asking the next.
- Never accept "it depends" without a follow-up: "depends on what?"
- Surface the riskiest assumption first.
- When the user says "probably" or "I think", ask what it would take to know for sure.
- When the user proposes a solution, ask what problem it solves, then ask if there's a simpler way to solve that problem.

## Domain modeling rules

After each significant answer, check if it introduces:
- A new term that needs a definition (→ add to GLOSSARY.md)
- A decision that forecloses alternatives (→ write an ADR)
- A constraint that affects architecture (→ note it, may need an ADR)

## Output

When done, produce:
- A summary of the design decisions made
- Any new ADRs (save as `docs/adr/NNNN-<slug>.md`)
- Any new GLOSSARY.md entries
