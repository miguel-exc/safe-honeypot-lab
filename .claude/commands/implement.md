---
name: implement
description: Implement a piece of work based on a spec or set of tickets.
---

# Implement

Implement the work described by the user in the spec or tickets.

## Process

1. If the user passes a ticket reference, fetch it and state its title before starting. If the reference is ambiguous, ask.

2. Explore the repo to understand the current state of the codebase. Use the project's domain glossary vocabulary throughout the implementation.

3. Use TDD (see `tdd.md`) where possible, at pre-agreed seams.

4. Run typechecking regularly, single test files regularly, and the full test suite once at the end.

5. Once done, review the work for correctness and simplification.

6. Commit your work to the current branch.

## Notes for SAFE project

- For `parse_metrics.py` changes: test against fixture JSON logs in `tests/fixtures/`
- For Docker/Cowrie changes: verify with `docker compose up -d` and a manual SSH exec check
- For scenario scripts (`scenarios/s*.sh`): test via `docker exec safe-attacker bash /scenarios/run_all.sh safe-honeypot` (Condición A, fast) before Condición B
