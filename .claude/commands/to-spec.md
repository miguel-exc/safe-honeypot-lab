---
name: to-spec
description: Turn the current conversation into a spec. No interview — just synthesizes what has already been discussed.
---

# To Spec

This skill takes the current conversation context and codebase understanding and produces a spec. Do NOT interview the user; just synthesize what you already know.

## Process

1. Explore the repo to understand the current state of the codebase, if you haven't already. Use the project's domain glossary vocabulary throughout the spec.

2. Sketch out the seams at which you're going to test the feature. Existing seams should be preferred to new ones.

3. Write the spec using the template below and save it to `.scratch/<feature-slug>/spec.md`.

## Spec template

```markdown
## Problem Statement

The problem that the user is facing, from the user's perspective.

## Solution

The solution to the problem, from the user's perspective.

## User Stories

A numbered list of user stories. Format:
1. As a <actor>, I want <feature>, so that <benefit>

## Implementation Decisions

- The modules that will be built/modified
- Architectural decisions
- Technical clarifications

Do NOT include specific file paths or code snippets (they go stale fast).

## Testing Decisions

- What makes a good test for this feature
- Which modules will be tested
- Seams to test at

## Out of Scope

Things explicitly not included in this spec.

## Further Notes

Any further notes about the feature.
```
