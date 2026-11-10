---
name: to-tickets
description: Break a plan, spec, or the current conversation into tracer-bullet tickets saved as local files under .scratch/.
---

# To Tickets

Break a plan, spec, or conversation into a set of **tickets**: tracer-bullet vertical slices, each declaring the tickets that **block** it.

## Process

### 1. Gather context

Work from whatever is already in the conversation context. If the user passes a reference (a spec path), read its full body.

### 2. Explore the codebase (optional)

If you have not already explored the codebase, do so to understand the current state. Look for opportunities to prefactor. "Make the change easy, then make the easy change."

### 3. Draft vertical slices

Break the work into **tracer bullet** tickets:

- Each slice cuts a narrow but COMPLETE path through every layer
- A completed slice is demoable or verifiable on its own
- Each slice is sized to fit in a single fresh context window
- Any prefactoring should be done first

Give each ticket its **blocking edges**: the other tickets that must complete before it can start.

### 4. Present to user for approval

Show the breakdown as a numbered list. For each ticket, show:
- **Title**: short descriptive name
- **Blocked by**: which other tickets must complete first
- **What it delivers**: the end-to-end behaviour this ticket makes work

Iterate until the user approves.

### 5. Write tickets as local files

Write one file per ticket under `.scratch/<feature-slug>/issues/<NN>-<slug>.md`, numbered from `01` in dependency order (blockers first).

```markdown
# <NN>: <Ticket title>

**What to build:** the end-to-end behaviour this ticket makes work.

**Blocked by:** ticket numbers/titles that gate this one, or "None (can start immediately)".

**Status:** ready-for-agent

- [ ] Acceptance criterion 1
- [ ] Acceptance criterion 2
```
