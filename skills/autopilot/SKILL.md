---
name: autopilot
description: "Fully autonomous product builder — takes a one-line description, runs the complete FORGE pipeline with self-healing loops, and generates future enhancements. Triggered by 'autopilot', 'build this autonomously', 'just build it', 'create end to end'."
argument-hint: "/autopilot [product description]"
allowed-tools: Read Grep Glob Write Edit Bash Agent
---

# /autopilot — Fully Autonomous Product Builder

**Inline implementation is FORBIDDEN. Every phase MUST invoke its skill via the Skill tool.** You are the DRIVER — if you catch yourself generating implementation artifacts instead of invoking the skill, STOP. The user types nothing after invoking you; they CAN interrupt, but you never stop to ask.

> Shared rules: `skills/shared/rules.md`
> Compliance & telemetry: `skills/shared/compliance-telemetry.md` (skill_name=`autopilot`)

## Enforcement Rules

Before ticking any phase, confirm the expected artifact exists:
```bash
test -f [expected artifact] || { bash scripts/autopilot-guard.sh halt "artifact missing after [phase]"; exit 1; }
```
If missing, log via `bash scripts/compliance-log.sh autopilot phase-skipped critical "Artifact missing after [phase]"` and do NOT tick. If a skill fails or produces no artifact, HALT and report — never substitute or reimplement. No pausing between phases — the entire pipeline (Steps 1-10) is one continuous execution block until Step 10 completes or the guard halts.

## Guard Protocol

All phase transitions use `scripts/autopilot-guard.sh` (state: `.forge/autopilot/state.json`):
- **Before:** `bash scripts/autopilot-guard.sh check` — non-zero = STOP
- **After:** `bash scripts/autopilot-guard.sh tick <phase>`
- **Failure:** `bash scripts/autopilot-guard.sh fail <phase> <issue-hash>` — non-zero (repeated) = STOP

The guard's word is final. Always trust the state file over your own count.

## AUTOPILOT MODE Context

Prepend to every skill invocation:
```
AUTOPILOT MODE — This skill is being invoked by /autopilot.
- AUTO-PROCEED at low-risk decisions (classification, token budget, approach selection, architecture approval).
  AUTO-PROCEED does NOT authorize skipping a skill invocation — invoking each skill is mandatory, not a decision.
- STOP and surface HIGH-RISK decisions (business logic, API contracts, crypto, security, DB migrations, schema changes).
- Log every decision and why.
```

## Pipeline Progress Dashboard

Emit between every phase: `FORGE /autopilot — Pipeline Progress` with `[mark] think -> brainstorm -> design -> architect -> build -> review -> verify -> ship` and guard counters. Marks: `done`/`active`/`skipped`/plain.

## Step 0: Initialize

Parse `$ARGUMENTS` for description and optional flags (`--max-iterations N`, `--skip-brainstorm`). If no description, ask once.
```bash
bash scripts/autopilot-guard.sh init --max-inner ${MAX_ITERATIONS:-3} --max-outer 2 --max-total 15
RUN_ID=$(bash scripts/manifest.sh create "$ARGUMENTS" | tail -1)
bash scripts/telemetry.sh autopilot started
```

## Steps 1-4: Phase Invocations

Each phase: (1) `guard check` (2) invoke skill with AUTOPILOT MODE (3) verify artifact (4) `guard tick` (5) `manifest phase/artifact` (6) emit dashboard.

**Step 1 — Think:** Invoke `/think [description]`: "Just classify and return." Pipeline by classification:
| Classification | Pipeline |
|---|---|
| TINY (no UI) | build -> review -> verify -> ship |
| TINY (with UI) | ask user -> (design ->) build -> review -> verify -> ship |
| FEATURE (no UI) | brainstorm -> architect -> build -> review -> verify -> ship |
| FEATURE/EPIC (with UI) | brainstorm -> design -> architect -> build -> review -> verify -> ship |

Set `HAS_UI=true` for user-facing interface tasks. Debug -> `guard halt "debug task — use /debug"`.

**Step 2 — Brainstorm** (skip TINY/`--skip-brainstorm`): Invoke `/brainstorm [description]`. Artifact: `.forge/brainstorm/*.md`

**Step 2b — Design** (UI only): If `HAS_UI=true`: invoke `/forge:design` BEFORE `/forge:architect`. TINY+UI: ask user (HIGH-RISK). Artifact: `.forge/design/*.md`

**Step 3 — Architect** (skip TINY): Invoke `/architect [description]` — locked doc, stores decisions, auto-approves. Artifact: `.forge/architecture/*.md`

**Step 4 — Build:** Tasks from arch doc: **< 3** -> spawn `forge-builder` agent (skills: [forge:build], model: opus); **3+** -> `/build` inline.
```bash
FEATURE_NAME=$(bash scripts/manifest.sh resolve-feature-name)
test -f .forge/build/${FEATURE_NAME}.md || { bash scripts/autopilot-guard.sh halt "build report not generated"; exit 1; }
bash scripts/autopilot-guard.sh tick build
bash scripts/manifest.sh phase "$RUN_ID" build
bash scripts/manifest.sh artifact "$RUN_ID" build ".forge/build/${FEATURE_NAME}.md"
```

## Steps 5-6: Review/Verify Loops

**Retry template:** `guard check` -> spawn subagent with AUTOPILOT MODE -> `guard tick` -> read artifact -> IF PASS break; IF FAIL: `issue_hash=$(echo -n "[first issue]" | shasum | cut -c1-8)`, `guard fail <phase> "$issue_hash"` [stop if non-zero], fix, `guard tick <fix-phase>`, GOTO LOOP.

**Step 5 — Review + Fix (Inner):** Agent `forge-reviewer` (skills: [forge:review]). Inputs: architecture, build report, git diff. On FAIL: invoke `/forge:build` with targeted fix (never fix inline). Tick `build-fix inner`.

**Step 6 — Verify + Fix (Outer):** Agent `forge-verifier` (skills: [forge:verify]). Same inputs. On FAIL: `guard tick verify-retry outer`, `guard reset-inner`, route: code-level (test/runtime) -> Step 4+5; architecture-level (endpoint/schema) -> Step 3. Default: code-level.

## Steps 7-10: Ship & Wrap-up

**Step 7 — Ship:** Spawn `forge-shipper` (skills: [forge:ship], model: opus) with `--draft`. `/ship` determines version bump — do NOT pre-force. Do NOT skip security audit. If auto-fixes security -> re-run Steps 5+6. Then: `bash scripts/autopilot-guard.sh tick ship && bash scripts/manifest.sh phase "$RUN_ID" ship`

**Step 8 — Future Enhancements:** Generate `.forge/autopilot/future-enhancements.md` (deferred items, 5-10 enhancements by impact/effort, tech debt, perf, security).
```bash
mkdir -p .forge/autopilot
bash scripts/artifact-discover.sh all > .forge/autopilot/artifacts-inventory.md
bash scripts/manifest.sh artifact "$RUN_ID" future-enhancements ".forge/autopilot/future-enhancements.md"
```

**Step 9 — Memory:** Invoke `/memory-remember` with key decisions. Fallback: direct write with dedup (`grep`), safe JSON (`jq -n -c`), validation (`tail -1 | jq empty`).

**Step 10 — Final Report:**
```bash
bash scripts/autopilot-guard.sh complete
bash scripts/autopilot-guard.sh status
bash scripts/telemetry.sh autopilot completed
bash scripts/telemetry.sh phase-transition autopilot
```
Emit: Task, Classification, Pipeline, Iterations, PR URL, Artifacts, Top 3 enhancements. End with `Run /retro to reflect on this session.`

**What's Next:** run `/retro`. See `skills/shared/workflow-routing.md`.
