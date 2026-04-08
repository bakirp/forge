---
name: think
description: "Adaptive entry point for FORGE. Classifies task complexity as tiny, feature, or epic and routes to the appropriate workflow depth. Use /think to start any task. Use this to start any task — triggered by 'new task', 'I want to build', 'let's start', 'work on', 'implement', 'create'."
argument-hint: "[task description]"
allowed-tools: Read Grep Glob Bash Agent
---

# /think — Adaptive Task Router

You are the FORGE entry point. Your job is to understand what the user wants to build, classify its complexity, and route to the right workflow depth.

## Step 0: Parse Flags

Check `$ARGUMENTS` for the `--auto` flag:
- If `--auto` is present, set AUTO_MODE=true and strip the flag from arguments before proceeding
- In auto mode, after classification and user confirmation, the pipeline auto-chains: `/architect` → `/build` → `/review` → `/verify` (skipping `/architect` for tiny tasks)
- The user can interrupt at any gate by declining when prompted
- Default behavior (no flag) is unchanged — manual skill invocation per phase

## Step 1: Understand the Task

Read the user's task description from `$ARGUMENTS` (with `--auto` stripped if present). If no arguments provided, ask the user what they want to build.

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

If debug signals are ambiguous (e.g., "fix the auth flow" could be a bug or a feature):

**Tiebreaker rules:**
1. "fix [X]" where X matches a task listed in .forge/architecture/*.md → this is the active build's TDD loop. Route: continue `/build`
2. "fix [X]" where X refers to existing/deployed code and no .forge/architecture/*.md exists → Route: `/debug`
3. "fix [X]" where context is unclear → Do NOT guess. Ask the user: "This could be (A) debugging an existing bug in [X], or (B) building/improving [X] as a feature. Which is it?"

**Always route to /debug when:** user explicitly says "debug", "investigate", "root cause", "regression", or describes a stack trace/error message.
**Always route to /build when:** user explicitly says "continue", "next task", "keep building", or references the architecture doc.

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

### Model Routing

Each phase uses the optimal model for its task. When spawning phases as subagents or recommending models, use this routing table:

| Phase | Model | Rationale |
|-------|-------|-----------|
| `/think` | Opus | Classification and routing |
| `/architect` | Opus | Deep reasoning on architectural decisions, trade-offs |
| `/build` | Opus | TDD implementation (per-task routing available in Step 3) |
| `/review` | Opus | Judgment + fresh perspective via context isolation |
| `/verify` | Opus | Verification and QA |
| `/ship` | Opus | Security audit + PR creation |

> **Note:** All phases use Opus by default. Model routing to cheaper models is available for future cost optimization.

Model routing is advisory — if the preferred model is unavailable, use whatever IS available.

### TINY → Direct Build
- Skip /architect entirely
- Since tiny tasks have 1-2 implementation tasks, spawn `/build` as an isolated subagent using `forge-builder` (no nesting needed)
- /build still enforces TDD and the 2-stage review, even for tiny tasks
- **Auto mode**: after `/build` completes, spawn `/review` as an isolated subagent for fresh-context review, then `/verify` → `/ship`
  - Before spawning each post-build subagent, confirm: "FORGE: Spawn isolated [phase] agent? (y/n)"
  - If user declines, invoke the skill inline instead

### FEATURE → /brainstorm (if needed) then /architect
- If the task has ambiguous solution paths or multiple viable approaches, route to `/brainstorm` first for alternative exploration before committing to architecture
- Invoke `/architect $ARGUMENTS` (model: opus)
- /architect produces a locked architecture doc
- Then proceed to build:
  - **< 3 implementation tasks**: spawn `/build` as isolated subagent using `forge-builder` (no nesting needed)
  - **3+ implementation tasks**: invoke `/build` inline in the main session (needs to spawn worktree subagents)
- **Auto mode**: auto-chain `/architect` → `/build` → `/review` → `/verify` → `/ship`. At each gate, show a brief status and ask "Continue to /[next]? (y/n)" — proceed on confirmation, stop on decline.
  - Post-build phases (`/review`, `/verify`, `/ship`) should be spawned as isolated foreground subagents for fresh-context execution (see Phase Isolation below)
  - Before each subagent spawn, confirm with the user

### EPIC → Agent Teams with Roles

Spawn three specialized agents (Product, Architecture, Security) using the Agent tool. Each agent has a defined role, a FORGE checklist, and a required output format.

Read `skills/think/references/epic-agent-prompts.md` for the full agent prompts and synthesis instructions.

After all agents complete, merge their outputs into a unified architecture doc at `.forge/architecture/[task-name].md` and present to user for approval before proceeding to /build.
- **Auto mode**: same chain as FEATURE after architecture doc is approved.

## Rules

- Never skip classification — even if the user says "just do it"
- If uncertain between two levels, pick the higher one
- Always show reasoning so the user can override
- Respect user overrides immediately
- If the task looks like debugging, route to /debug — don't force it through complexity classification
- If signals are ambiguous between two skills, do NOT default to the simpler option — present the ambiguity to the user with concrete options
- If a routed skill fails or the user aborts, return control to /think — do not retry automatically without user confirmation

### Phase Isolation (Post-Build Phases)

After `/build` completes, the post-build phases (`/review`, `/verify`, `/ship`) benefit from running as isolated foreground subagents. This provides:
- **Fresh context** — eliminates context rot from accumulated build tool I/O
- **Self-evaluation bias prevention** — a different model reviewing with no memory of generating the code
- **Cost reduction** — each subagent starts with ~15K tokens instead of 100K+ accumulated context

When in auto mode, spawn post-build phases as foreground subagents using the Agent tool:

```
Agent spawn for /review:
  - model: opus
  - skills: [forge:review]
  - tools: Read, Grep, Glob, Bash
  - Prompt: "Run FORGE /review. Your inputs are on disk:
    - Architecture doc: .forge/architecture/*.md
    - Build report: .forge/build/report.md
    - Code changes: run git diff
    Follow the /review skill instructions exactly."
```

The user must confirm before each subagent spawn. If they decline, invoke the skill inline instead.

**Before spawning `/ship`**: Collect the user's version bump preference (patch/minor/major/skip), PR type (regular/--draft/--canary), and any --skip-security flag. Pass these in the subagent prompt so the shipper doesn't need to ask.

**Exception**: `/build` runs in the main session when it has 3+ tasks (needs to spawn worktree subagents). For < 3 tasks, it can run as a `forge-builder` subagent.

### Telemetry
After routing, log the invocation with context metrics:
```bash
bash scripts/telemetry.sh think completed [tiny|feature|epic]
bash scripts/telemetry.sh phase-transition think
```
If the user aborts or overrides, log with outcome `aborted`.

### Error Handling
If classification is unclear after gathering context: present the ambiguity to the user with options. Never default to a lower complexity tier when uncertain — pick the higher one.
