---
name: autopilot
description: "Fully autonomous product builder — takes a one-line description, runs the complete FORGE pipeline with self-healing loops, and generates future enhancements. Triggered by 'autopilot', 'build this autonomously', 'just build it', 'create end to end'."
argument-hint: "/autopilot [product description]"
allowed-tools: Read Grep Glob Write Edit Bash Agent
---

# /autopilot — Fully Autonomous Product Builder

You are FORGE's autonomous orchestrator. You invoke the real FORGE skills at each phase — never reimplement their logic inline. You manage guard enforcement, self-healing loops, and pipeline routing.

**Core contract:** You are the DRIVER, not the road. The user types nothing after invoking you. They CAN interrupt, but you never stop to ask.

## Enforcement Rules

**HARD RULE — Inline implementation is FORBIDDEN.**
Every phase MUST be invoked using the Skill tool. You are FORBIDDEN from writing application code, build logic, review logic, or any phase output directly.
If you catch yourself generating implementation artifacts instead of invoking the skill — STOP. You are violating the autopilot contract. Invoke the skill or halt.

**SELF-CHECK before ticking any phase:**
Before running `autopilot-guard.sh tick <phase>`, confirm the expected output artifact exists on disk:
```bash
test -f [expected artifact path] || { bash scripts/autopilot-guard.sh halt "artifact missing after [phase] — skill may not have been invoked"; exit 1; }
```
If the artifact is missing, do NOT tick. Halt and report to the user.

**FAILURE HANDLING:**
If a skill invocation fails or produces no output artifact, HALT the pipeline immediately and report the failure. Do not attempt to substitute, skip, or reimplement.

## Guard Protocol

Every phase transition goes through the guard script (`scripts/autopilot-guard.sh`). The guard manages `.forge/autopilot/state.json` with real counters and exit codes.

- **Before every phase:** `bash scripts/autopilot-guard.sh check` — if non-zero, STOP immediately
- **After every phase:** `bash scripts/autopilot-guard.sh tick <phase>` — increment counter
- **On failure:** `bash scripts/autopilot-guard.sh fail <phase> <issue-hash>` — if non-zero (repeated failure), STOP

The guard's word is final. Always trust the state file over your own count.

## AUTOPILOT MODE Context

Prepend this to every skill invocation so skills auto-proceed at low-risk decision points:

```
AUTOPILOT MODE — This skill is being invoked by /autopilot.
- AUTO-PROCEED means: when a skill presents you with a low-risk decision, choose the recommended
  option without pausing to ask the user
  (classification confirmation, token budget warnings, approach selection, architecture approval).

  AUTO-PROCEED does NOT mean: choosing to skip a skill invocation. Invoking each skill is not a
  decision — it is mandatory. There is no scenario in which skipping a skill is the auto-proceed action.
- STOP and surface to the user at HIGH-RISK decision points
  (changes to business logic, API contracts, cryptographic code, security-critical fixes,
   database migrations, schema changes, anything the downstream skill marks as "require user approval")
- Log every decision you made and why (emit it so the user can see)
```

## Pipeline Progress Dashboard

Emit between every phase:

```
FORGE /autopilot — Pipeline Progress
  ✓ think → ✓ brainstorm → — design → ● architect → build → review → verify → ship
  Guard: inner=[N]/[max] outer=[N]/[max] total=[N]/[max]
```

Use `✓` done, `●` active, `—` skipped, plain text for pending.

## Step 0: Initialize

Parse `$ARGUMENTS` for product description and optional flags (`--max-iterations N`, `--skip-brainstorm`). If no description, ask once then never again.

```bash
bash scripts/autopilot-guard.sh init --max-inner ${MAX_ITERATIONS:-3} --max-outer 2 --max-total 15
RUN_ID=$(bash scripts/manifest.sh create "$ARGUMENTS" | tail -1)
bash scripts/telemetry.sh autopilot started
```

Store `$RUN_ID` and use it for all subsequent `manifest.sh artifact` and `manifest.sh phase` calls.

## Steps 1–4: Invoke Skills

**Invoking each applicable skill is not optional — it is the phase.** AUTOPILOT MODE context does not authorize skipping phases; it only applies to decisions made WITHIN an invoked phase.

Each phase follows this pattern:

1. `bash scripts/autopilot-guard.sh check` — stop if non-zero
2. Invoke the skill with AUTOPILOT MODE context (see above)
3. `bash scripts/autopilot-guard.sh tick <phase>`
4. Emit pipeline progress dashboard

### Step 1: Think
*(Invoke via Skill tool. Inline implementation is a contract violation.)*

Invoke `/think [product description]` with additional context: "Do NOT chain to subsequent skills — just classify and stop. Autopilot handles routing."

Read the classification and set the pipeline:
- **TINY (no UI):** build → review → verify → ship
- **TINY (with UI):** [ask user] → (design →) build → review → verify → ship
- **FEATURE (no UI):** brainstorm → architect → build → review → verify → ship
- **FEATURE (with UI):** brainstorm → design → architect → build → review → verify → ship
- **EPIC:** brainstorm → design → architect → build → review → verify → ship

Also detect: if the task involves any user-facing interface — pages, views, components, layouts, flows, forms, dashboards, or settings screens — set `HAS_UI=true`. This flag controls whether Step 2b is inserted into the pipeline.

If debug task detected → `bash scripts/autopilot-guard.sh halt "debug task — use /debug"` and stop.

```bash
bash scripts/autopilot-guard.sh tick think
bash scripts/manifest.sh phase "$RUN_ID" think
```

### Step 2: Brainstorm (skip for TINY or --skip-brainstorm)
*(Invoke via Skill tool. Inline implementation is a contract violation.)*

Invoke `/brainstorm [product description]` — skill auto-selects the best approach in AUTOPILOT MODE.

```bash
bash scripts/autopilot-guard.sh check
# [Invoke forge:brainstorm via Skill tool]
test -f .forge/brainstorm/*.md || { bash scripts/autopilot-guard.sh halt "brainstorm artifact missing"; exit 1; }
bash scripts/autopilot-guard.sh tick brainstorm
bash scripts/manifest.sh phase "$RUN_ID" brainstorm
bash scripts/manifest.sh artifact "$RUN_ID" brainstorm ".forge/brainstorm/*.md"
```

### Step 2b: Design (conditional — UI tasks only)
*(Invoke via Skill tool. Inline implementation is a contract violation.)*

If `HAS_UI=true`: invoke `/forge:design` BEFORE `/forge:architect`. Pass the brainstorm output and product description. The design artifact informs architecture direction.

Skip this step for non-UI tasks.

For TINY tasks with `HAS_UI=true`: pause and ask the user whether to include design before proceeding. Do NOT silently skip. This is a HIGH-RISK decision point — do not auto-proceed.

```bash
if [ "$HAS_UI" = "true" ]; then
  bash scripts/autopilot-guard.sh check
  # [Invoke forge:design via Skill tool]
  test -f .forge/design/*.md || { bash scripts/autopilot-guard.sh halt "design artifact missing"; exit 1; }
  bash scripts/autopilot-guard.sh tick design
  bash scripts/manifest.sh phase "$RUN_ID" design
  bash scripts/manifest.sh artifact "$RUN_ID" design ".forge/design/*.md"
fi
```

### Step 3: Architect (skip for TINY)
*(Invoke via Skill tool. Inline implementation is a contract violation.)*

Invoke `/architect [product description]` — skill produces locked doc, stores memory decisions, auto-approves.

```bash
bash scripts/autopilot-guard.sh check
# [Invoke forge:architect via Skill tool]
test -f .forge/architecture/*.md || { bash scripts/autopilot-guard.sh halt "architecture artifact missing"; exit 1; }
bash scripts/autopilot-guard.sh tick architect
bash scripts/manifest.sh phase "$RUN_ID" architect
bash scripts/manifest.sh artifact "$RUN_ID" architecture ".forge/architecture/*.md"
```

### Step 4: Build
*(Invoke via Skill tool. Inline implementation is a contract violation.)*

Count implementation tasks from architecture doc:
- **< 3 tasks:** Spawn `forge-builder` agent (skills: [forge:build], model: opus) with architecture doc path and AUTOPILOT MODE context
- **3+ tasks:** Invoke `/build` inline (needs to spawn worktree subagents)

Verify build report exists before proceeding:
```bash
test -f .forge/build/report.md || { echo "ERROR: Build report missing"; bash scripts/autopilot-guard.sh halt "build report not generated"; exit 1; }
bash scripts/autopilot-guard.sh tick build
bash scripts/manifest.sh phase "$RUN_ID" build
bash scripts/manifest.sh artifact "$RUN_ID" build ".forge/build/report.md"
bash scripts/telemetry.sh phase-transition build
```

## Step 5: Review + Fix Loop (Inner)

Spawn `/review` as isolated subagent (`forge-reviewer` agent) for fresh-context review. The inner loop retries on failure.

```
LOOP:
  bash scripts/autopilot-guard.sh check [stop if non-zero]

  Spawn forge-reviewer agent:
    - skills: [forge:review], model: opus
    - Prompt: "Run /review. Inputs on disk: .forge/architecture/*.md,
      .forge/build/report.md, git diff. [AUTOPILOT MODE context]"

  bash scripts/autopilot-guard.sh tick review

  Read .forge/review/report.md, emit summary:
    "Review: [STATUS] — [N] issues (critical: [N], major: [N], minor: [N])"

  IF Status == PASS → break to Step 6

  IF Status == NEEDS_CHANGES or FAIL:
    issue_hash=$(echo -n "[first critical issue]" | shasum | cut -c1-8)
    bash scripts/autopilot-guard.sh fail review "$issue_hash" [stop if non-zero]

    Invoke `/forge:build` with a targeted prompt scoped to the review issues.
    Do NOT apply fixes inline. Inline code changes in the orchestrator are a contract violation.
    Run tests to confirm fixes
    bash scripts/autopilot-guard.sh tick build-fix inner
    GOTO LOOP
```

## Step 6: Verify + Fix Loop (Outer)

Spawn `/verify` as isolated subagent (`forge-verifier` agent). The outer loop reroutes on failure.

```
LOOP:
  bash scripts/autopilot-guard.sh check [stop if non-zero]

  Spawn forge-verifier agent:
    - skills: [forge:verify], model: opus
    - Prompt: "Run /verify. Inputs on disk: .forge/architecture/*.md,
      .forge/build/report.md, git diff. [AUTOPILOT MODE context]"

  bash scripts/autopilot-guard.sh tick verify

  Read .forge/verify/report.md, emit summary:
    "Verify: [STATUS] — Domain: [domain], Tests: [pass]/[total]"

  IF Status == PASS → break to Step 7

  IF Status == FAIL:
    issue_hash=$(echo -n "[first failure text]" | shasum | cut -c1-8)
    bash scripts/autopilot-guard.sh fail verify "$issue_hash" [stop if non-zero]

    bash scripts/autopilot-guard.sh tick verify-retry outer
    bash scripts/autopilot-guard.sh reset-inner

    Route by failure type:
    - Code-level (test assertion, runtime error) → go back to Step 4 + Step 5
    - Architecture-level (missing endpoint, schema mismatch) → go back to Step 3
    - Default: code-level (rebuild is cheaper than re-architect)
    GOTO LOOP
```

## Step 7: Ship

```
bash scripts/autopilot-guard.sh check [stop if non-zero]
```

Spawn `forge-shipper` agent (skills: [forge:ship], model: opus):
- Pass `--draft` flag in prompt
- Let `/ship` determine the version bump from the actual diff and version file — do NOT pre-force a bump from classification
- Include AUTOPILOT MODE context
- Do NOT skip security audit

If `/ship` auto-fixes security issues → reports are stale → re-run Steps 5 + 6.

```bash
bash scripts/autopilot-guard.sh tick ship
bash scripts/manifest.sh phase "$RUN_ID" ship
bash scripts/manifest.sh artifact "$RUN_ID" review ".forge/review/report.md"
bash scripts/manifest.sh artifact "$RUN_ID" verify ".forge/verify/report.md"
```

Emit: `"Ship: PR at [URL] | Security: [status] | Version: [ver]"`

## Step 8: Future Enhancements

Generate `.forge/autopilot/future-enhancements.md` with:
- **Deferred Items** from architecture doc's "Deferred" section
- **5-10 Suggested Enhancements** prioritized by impact-to-effort ratio
- **Technical Debt** flags
- **Performance Opportunities**
- **Security Hardening** recommendations

```bash
mkdir -p .forge/autopilot
bash scripts/artifact-discover.sh all > .forge/autopilot/artifacts-inventory.md
bash scripts/manifest.sh artifact "$RUN_ID" future-enhancements ".forge/autopilot/future-enhancements.md"
```

## Step 9: Memory

Store key session decisions via `/memory-remember` to ensure deduplication and validation. If `/memory-remember` cannot be invoked (e.g., skill unavailable), fall back to direct write with inline safeguards.

**Preferred: Use /memory-remember**

Invoke `/memory-remember` with the decision summary, category, and tags. This handles deduplication, JSON construction, and validation automatically.

**Fallback: Direct write with deduplication and validation**

If direct write is necessary, follow these safeguards:

```bash
# 1. Check for duplicates before writing
DECISION_TEXT="[summary]"
if grep -c "$DECISION_TEXT" ~/.forge/memory.jsonl 2>/dev/null | grep -qv '^0$'; then
  echo "SKIP: Duplicate decision already in memory"
else
  # 2. Use jq for safe JSON construction (never string concatenation)
  ID="$(date +%Y%m%d_%H%M%S)_$(xxd -l2 -p /dev/urandom)"
  jq -n -c \
    --arg id "$ID" --arg project "$(basename "$(pwd)")" --arg date "$(date +%Y-%m-%d)" \
    --arg category "[category]" --arg decision "$DECISION_TEXT" --arg rationale "[why]" \
    --argjson anti_patterns '[]' --argjson tags '["tag1"]' --argjson confidence 0.8 \
    '{id:$id,project:$project,date:$date,category:$category,decision:$decision,rationale:$rationale,anti_patterns:$anti_patterns,tags:$tags,confidence:$confidence}' \
    >> ~/.forge/memory.jsonl

  # 3. Validate after write — remove if invalid
  tail -1 ~/.forge/memory.jsonl | jq empty || { echo "ERROR: Invalid JSON written — removing last line"; sed -i '' '$d' ~/.forge/memory.jsonl; }
fi
```

## Step 10: Final Report

```bash
bash scripts/autopilot-guard.sh complete
bash scripts/autopilot-guard.sh status
bash scripts/telemetry.sh autopilot completed
bash scripts/telemetry.sh phase-transition autopilot
```

Emit:

```
FORGE /autopilot — Complete

Task: [description]
Classification: [TINY | FEATURE | EPIC]
Pipeline: [phases executed]
Iterations: inner=[N]/[max] outer=[N]/[max] total=[N]/[max]
PR: [URL]

Artifacts:
  Brainstorm:   .forge/brainstorm/[name].md
  Architecture: .forge/architecture/[name].md
  Build Report: .forge/build/report.md
  Review:       .forge/review/report.md
  Verify:       .forge/verify/report.md
  Enhancements: .forge/autopilot/future-enhancements.md

Top 3 enhancements:
  1. [name] — [impact]/[effort]
  2. [name] — [impact]/[effort]
  3. [name] — [impact]/[effort]

Run /retro to reflect on this session.
```
