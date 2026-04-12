---
name: architect
description: "Lock architecture before building. Queries memory bank for past decisions, produces a locked architecture doc with data flow, API contracts, edge cases, and test strategy. Called by /think for feature and epic tasks. Use when planning architecture, designing systems, or before building features — triggered by 'plan the architecture', 'design the system', 'how should we structure'."
argument-hint: "[task description or /think output]"
allowed-tools: Read Grep Glob Write Bash
---

# /architect — Lock Architecture Before Build

Never write implementation code — architecture only. You produce a locked architecture document that /build consumes directly. All decisions, no code.

> **Shared protocols apply.** See `skills/shared/rules.md` for evidence-before-claims, scope discipline, artifact integrity.

## Step 1: Recall Past Decisions

Run `/memory-recall` with the current task context. If relevant entries found, treat as constraints/prior art and note anti-patterns to avoid. If nothing relevant, proceed silently.

## Step 1.5: Load Brainstorm Artifact (if exists)

Check `ls .forge/brainstorm/*.md 2>/dev/null | head -1`. If found, extract selected approach, rejected alternatives, constraints, and trade-offs to avoid re-exploring rejected paths. If absent, proceed.

## Step 2: Analyze the Codebase

Before designing, understand what exists: project structure, existing patterns (naming, architecture, tests), APIs, data models, config files, tech stack, and dependencies.

## Step 3: Produce the Architecture Doc

Write a structured architecture document. This is the contract /build must follow.

### Architecture Doc Format

# Architecture: [Task Name]
## Status: LOCKED
> Produced by FORGE /architect. Changes require re-running /architect.
## Overview
[1-2 sentences: what and why]
## Data Flow
[How data moves. Text diagrams if helpful.] Input -> [Step 1] -> [Step 2] -> Output
## API Contracts
### [Endpoint/Function Name]
- Input: [types] | Output: [types] | Errors: [cases] | Auth: [requirements]
## Component Boundaries
| Component | Responsibility | Creates/Modifies |
|-----------|---------------|-----------------|
## Edge Cases
1. [Edge case] -> [Handling strategy]
## Test Strategy
- Unit: [what] | Integration: [what] | Edge case tests: [which]
## Dependencies
[New packages, services, or infrastructure required]
## Security Considerations
[Auth, data handling, input validation, OWASP relevance]
## Deferred
[What was explicitly decided NOT to build now, and why]

## Step 4: Write and Lock

Create directory and save: `mkdir -p .forge/architecture` then write to `.forge/architecture/[task-name-slugified].md`.

Verify the file was written:
```bash
head -5 .forge/architecture/[task-name-slugified].md
```

Output must include the file path and `## Status: LOCKED` line. Show evidence before claiming completion. Present the full doc to the user:
```
FORGE /architect -> Architecture locked.
Key decisions: [list top 3]
Files to create/modify: [count] | Test coverage: [summary]
Ready for /build. Override any decision? (or say "build" to proceed)
```

Wait for user approval. If they request changes, update the doc and re-present.

## Step 5: Remember Key Decisions

Run `/memory-remember` to store key architectural decisions. After storing, confirm: `FORGE /architect — Decisions stored to memory bank: [list decisions]`.

## Rules, Compliance & Routing

- The architecture doc is a contract — /build must follow it exactly.
- Every edge case must have a handling strategy; every API must have defined error cases.
- If the user says "just build it", push back once — then comply if they insist.

> See `skills/shared/compliance-telemetry.md` for the full protocol. Log violations via `scripts/compliance-log.sh`.

| rule_key | severity | trigger |
|----------|----------|---------|
| `implementation-in-arch` | major | Implementation code written during architecture phase |
| `memory-not-checked` | minor | Memory bank not checked before designing |
| `missing-edge-case-handling` | major | Edge cases missing handling strategies |
| `missing-api-errors` | major | APIs missing defined error cases |

**Telemetry:** `bash scripts/telemetry.sh architect completed` then `bash scripts/telemetry.sh phase-transition architect`

**Error handling:** If memory recall fails, proceed without and note "No prior decisions found." If codebase scanning fails, ask the user to narrow scope. Never produce an architecture doc based on assumptions when evidence is unavailable.

> See `skills/shared/workflow-routing.md` for the full routing table. After /architect, the next step is `/build`.
