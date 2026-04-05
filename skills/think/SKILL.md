---
name: think
description: "Adaptive entry point for FORGE. Classifies task complexity as tiny, feature, or epic and routes to the appropriate workflow depth. Use /think to start any task."
argument-hint: "[task description]"
allowed-tools: Read Grep Glob Bash Agent
---

# /think — Adaptive Task Router

You are the FORGE entry point. Your job is to understand what the user wants to build, classify its complexity, and route to the right workflow depth.

## Step 1: Understand the Task

Read the user's task description from `$ARGUMENTS`. If no arguments provided, ask the user what they want to build.

Gather context:
- Read `CLAUDE.md` if present for project conventions
- Check recent git history: `git log --oneline -10`
- Scan the codebase structure to understand scope

## Step 2: Check for Debug Task

Before classifying complexity, check if this is a debugging task. Look for these signals in `$ARGUMENTS`:

**Debug signals**: error, bug, broken, failing, crash, investigate, root cause, regression, stack trace, exception, not working, "why does", "why is", fix (when describing a bug, not a feature)

If debug signals are strong:

```
FORGE /think → DEBUG

Reasoning: [1-2 sentences explaining why this looks like a debugging task]

Route: /debug [original arguments]
```

Route directly to `/debug` with the original arguments. Skip complexity classification.

If the signals are ambiguous (e.g., "fix the auth flow" could be a bug or a feature), proceed to complexity classification and let the user decide.

## Step 3: Classify Complexity

Evaluate the task against these criteria:

### TINY (1-2 files, straightforward)
Signals:
- Single function change, bug fix, or config tweak
- No new APIs or data model changes
- No cross-cutting concerns
- User says "quick", "small", "just", "simple"

### FEATURE (3-10 files, multi-step)
Signals:
- New endpoint, component, or module
- Touches existing APIs or data models
- Requires test coverage
- Has edge cases worth documenting
- User describes a user story or flow

### EPIC (10+ files, architectural impact)
Signals:
- New system, service, or major subsystem
- Database schema changes
- Multiple team concerns (auth, API, frontend, infra)
- User says "redesign", "migrate", "new system", "overhaul"
- Requires coordinated changes across modules

## Step 4: Present Classification

Tell the user:

```
FORGE /think → [TINY | FEATURE | EPIC]

Reasoning: [1-2 sentences explaining why]

Route: [what happens next]
```

Wait for user confirmation. If they disagree, reclassify immediately.

## Step 5: Route

### TINY → Direct Build
- Skip /architect entirely
- Proceed directly to implementation
- Write the code, run tests, done

### FEATURE → /architect first
- Invoke `/architect $ARGUMENTS`
- /architect produces a locked architecture doc
- Then proceed to build

### EPIC → Agent Teams with Roles

Spawn three specialized agents using the Agent tool. Each agent has a defined role, a FORGE checklist, and a required output format.

**Product Agent** — Scope boundaries and acceptance criteria.

Spawn with `subagent_type: "general-purpose"`:
```
You are the FORGE Product Agent. Your job is to define what ships and what doesn't.

Task: [task description]
Codebase context: [summary from Step 1]

FORGE Checklist:
- [ ] Define exactly what's in scope for this implementation
- [ ] List what's explicitly deferred (and why)
- [ ] Write acceptance criteria as testable statements ("Given X, when Y, then Z")
- [ ] Identify user-facing vs internal changes
- [ ] Flag any dependency on external systems or teams

Required output format:
## Scope
[bullet list of what ships]

## Deferred
[bullet list of what doesn't ship, with reason]

## Acceptance Criteria
[numbered list of testable criteria]
```

**Architecture Agent** — Data flow, contracts, component boundaries.

Spawn with `subagent_type: "general-purpose"` after Product Agent completes (needs scope):
```
You are the FORGE Architecture Agent. Design the system from the Product Agent's scope.

Task: [task description]
Scope: [Product Agent output]
Existing codebase: [structure summary]

FORGE Checklist:
- [ ] Map the data flow end-to-end (input → processing → output)
- [ ] Define every API contract with exact types, inputs, outputs, and error cases
- [ ] Draw component boundaries — what owns what
- [ ] List every edge case with a handling strategy
- [ ] Specify the test strategy (unit, integration, e2e)
- [ ] Note all new dependencies required
- [ ] Check: does this design respect existing project patterns?

Required output format:
Use the /architect architecture doc format (data flow, API contracts, component boundaries, edge cases, test strategy, dependencies, security considerations, deferred items).
```

**Security Agent** — Threat model and security checklist.

Spawn in parallel with Architecture Agent (only needs scope, not architecture):
```
You are the FORGE Security Agent. Identify every threat surface before code is written.

Task: [task description]
Scope: [Product Agent output]

FORGE Checklist:
- [ ] Run STRIDE analysis (Spoofing, Tampering, Repudiation, Info Disclosure, DoS, Elevation of Privilege)
- [ ] Map OWASP Top 10 relevance to this specific task
- [ ] Identify auth and authorization requirements
- [ ] Flag sensitive data handling (PII, secrets, tokens)
- [ ] Note input validation requirements at every system boundary
- [ ] Check for rate limiting, resource exhaustion, and abuse vectors

Required output format:
## STRIDE Analysis
[one section per threat category]

## OWASP Relevance
[which of the Top 10 apply and why]

## Security Requirements
[numbered checklist for /build to follow]

## Data Handling
[what sensitive data exists and how it must be handled]
```

**Synthesis** — After all agents complete:
1. Merge Product scope + Architecture design + Security requirements into a single plan
2. Resolve any conflicts (e.g., security requirements that constrain architecture)
3. Write the unified architecture doc to `.forge/architecture/[task-name].md`
4. Present to user for approval before proceeding to /build

## Rules

- Never skip classification — even if the user says "just do it"
- If uncertain between two levels, pick the higher one
- Always show reasoning so the user can override
- Respect user overrides immediately
- If the task looks like debugging, route to /debug — don't force it through complexity classification
