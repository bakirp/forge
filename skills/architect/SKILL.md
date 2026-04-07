---
name: architect
description: "Lock architecture before building. Queries memory bank for past decisions, produces a locked architecture doc with data flow, API contracts, edge cases, and test strategy. Called by /think for feature and epic tasks. Use when planning architecture, designing systems, or before building features — triggered by 'plan the architecture', 'design the system', 'how should we structure'."
argument-hint: "[task description or /think output]"
allowed-tools: Read Grep Glob Write Bash
---

# /architect — Lock Architecture Before Build

You produce a locked architecture document that /build consumes directly. No code is written in this phase — only decisions.

## Step 1: Recall Past Decisions

Run `/memory-recall` with the current task context. This reads the memory bank, ranks entries by relevance (project match, tag overlap, category), and surfaces the top 5 past decisions.

If `/memory-recall` surfaces relevant entries, treat them as constraints or prior art for this architecture session. Note any anti-patterns — these are things that failed before and should be avoided.

If the memory bank is empty or no relevant entries are found, proceed silently.

## Step 2: Analyze the Codebase

Before designing, understand what exists:
- Read project structure (directories, key files)
- Identify existing patterns (naming, architecture style, test patterns)
- Check for existing APIs, data models, config files
- Note the tech stack and dependencies

## Step 3: Produce the Architecture Doc

Write a structured architecture document. This is the contract that /build must follow.

### Architecture Doc Format

```markdown
# Architecture: [Task Name]

## Status: LOCKED
> This document was produced by FORGE /architect. Changes require re-running /architect.

## Overview
[1-2 sentences: what we're building and why]

## Data Flow
[Describe how data moves through the system. Use text diagrams if helpful.]

Input → [Step 1] → [Step 2] → Output

## API Contracts
[Define every new or modified API surface]

### [Endpoint/Function Name]
- Input: [types]
- Output: [types]  
- Errors: [error cases]
- Auth: [requirements]

## Component Boundaries
[What modules/files are created or modified, and what each is responsible for]

| Component | Responsibility | Creates/Modifies |
|-----------|---------------|-----------------|
| ... | ... | ... |

## Edge Cases
[List every edge case identified. Each must have a handling strategy.]

1. [Edge case] → [How it's handled]
2. ...

## Test Strategy
[What gets tested and how]

- Unit tests: [what]
- Integration tests: [what]
- Edge case tests: [which edge cases from above get explicit tests]

## Dependencies
[New packages, services, or infrastructure required]

## Security Considerations
[Auth, data handling, input validation, OWASP relevance]

## Deferred
[What was explicitly decided NOT to build now, and why]
```

## Step 4: Write the Doc

Save the architecture doc to the project:

```
.forge/architecture/[task-name-slugified].md
```

Create the directory if it doesn't exist.

## Step 5: Present and Lock

Before claiming the architecture doc is complete, show evidence it was written:
```bash
head -5 .forge/architecture/[task-name-slugified].md
```
Output must include the file path and the `## Status: LOCKED` line. Do not claim the architecture is complete without showing this output.

Show the user the full architecture doc. Say:

```
FORGE /architect → Architecture locked.

Key decisions:
- [Decision 1]
- [Decision 2]  
- [Decision 3]

Files to create/modify: [count]
Test coverage: [summary]

Ready for /build. Override any decision? (or say "build" to proceed)
```

Wait for user approval. If they request changes, update the doc and re-present.

## Step 6: Remember Key Decisions

Run `/memory-remember` to store the key architectural decisions from this session. It will:
- Extract decisions from the architecture doc just produced
- Present them for user confirmation
- Deduplicate against existing entries
- Append confirmed decisions to the memory bank

After storing:
```
FORGE /architect — Decisions stored to memory bank:
- [decision 1]
- [decision 2]
```

## Rules

- Never write implementation code — architecture only
- Always check memory bank before designing (when available)
- The architecture doc is a contract — /build must follow it exactly
- Every edge case must have a handling strategy
- Every API must have defined error cases
- If the user says "just build it", push back once — then comply if they insist

### Telemetry
After the architecture doc is locked, log the phase transition:
```bash
bash scripts/telemetry.sh architect completed
bash scripts/telemetry.sh phase-transition architect
```

### Error Handling
If memory recall fails or returns no results: proceed without memory context and note "No prior decisions found." If codebase scanning fails: ask the user to narrow the scope. Never produce an architecture doc based on assumptions when evidence is unavailable.
