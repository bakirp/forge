# FORGE Skill & Agent Trigger Map

Complete reference of who triggers whom, what artifacts flow where, and where the gaps are.

Last updated: 2026-04-09 (v0.0.1)

---

## Master Pipeline Diagram

```
USER ENTRY POINTS
  │
  ├─ /think [task] ─────────────────────────────────────────────────────────────┐
  │    │                                                                        │
  │    ├─ TINY ──────────────────────── forge-builder agent ─── /build ─────┐   │
  │    │                                                                    │   │
  │    ├─ FEATURE ── /brainstorm ── /architect ── /build ──────────────────┤   │
  │    │                                                                    │   │
  │    ├─ EPIC ── /brainstorm ── Agent Teams ── /architect ── /build ──────┤   │
  │    │                          ├─ forge-product                          │   │
  │    │                          ├─ forge-architect                        │   │
  │    │                          └─ forge-security                         │   │
  │    │                                                                    │   │
  │    │  (--auto mode continues the chain below)                           │   │
  │    │                                                                    ▼   │
  │    ├─ forge-reviewer agent ─── /review ─────────────────────────────────┤   │
  │    ├─ forge-verifier agent ─── /verify ── /browse ──────────────────────┤   │
  │    └─ forge-shipper agent ──── /ship ───────────────────────────────────┘   │
  │                                                                             │
  ├─ /autopilot [description] ─────────────────────────────────────────────────┐│
  │    │                                                                       ││
  │    ├─ /think (classify only) ───── same routing as above                   ││
  │    ├─ /brainstorm (skip for TINY)                                          ││
  │    ├─ /architect (skip for TINY)                                           ││
  │    ├─ /build (inline or forge-builder)                                     ││
  │    ├─ /review ←→ fix loop (forge-reviewer, max 3 inner iterations)         ││
  │    ├─ /verify ←→ fix loop (forge-verifier, max 2 outer iterations)         ││
  │    ├─ /ship (forge-shipper, --draft)                                       ││
  │    └─ /memory-remember (store decisions)                                   ││
  │                                                                            ││
  ├─ /debug [bug] ── standalone, no downstream chain                           ││
  │                                                                            ││
  ├─ /design [sub] ── standalone hub, user-driven (not auto-wired)              ││
  │    ├─ /design consult                                                      ││
  │    ├─ /design explore                                                      ││
  │    ├─ /design review                                                       ││
  │    ├─ /design audit                                                        ││
  │    └─ /design polish                                                       ││
  │                                                                            ││
  └─ Standalone skills (user-invoked directly):                                ││
       /memory, /retro, /evolve, /browse, /benchmark,                          ││
       /canary, /deploy, /worktree, /finish,                                   ││
       /careful, /freeze, /document-release, /forge                            ││
```

---

## Per-Skill Trigger Diagrams

### /think

```
TRIGGERED BY          TRIGGERS                    SPAWNS (agents)
─────────────         ────────                    ───────
User (direct)    ───► /debug (if debug signals)   forge-builder (TINY)
/autopilot       ───► /brainstorm (if ideation)   forge-reviewer (--auto)
                      /architect (FEATURE/EPIC)    forge-verifier (--auto)
                      /build (via forge-builder)   forge-shipper (--auto)
                                                   forge-product (EPIC)
                                                   forge-architect (EPIC)
                                                   forge-security (EPIC)

READS                          WRITES
─────                          ──────
CLAUDE.md                      (none)
.forge/architecture/*.md
```

### /architect

```
TRIGGERED BY          TRIGGERS                    SPAWNS (agents)
─────────────         ────────                    ───────
/think (FEATURE) ───► /memory-recall              (none)
/think (EPIC)    ───► /memory-remember
/autopilot

READS                               WRITES
─────                               ──────
~/.forge/memory.jsonl               .forge/architecture/[task].md
.forge/brainstorm/*.md (if exists)
```

### /brainstorm

```
TRIGGERED BY          TRIGGERS                    SPAWNS (agents)
─────────────         ────────                    ───────
User (direct)    ───► /memory-recall              (none)
/think
/autopilot

READS                          WRITES
─────                          ──────
~/.forge/memory.jsonl          .forge/brainstorm/[task].md
```

### /build

```
TRIGGERED BY          TRIGGERS                    SPAWNS (agents)
─────────────         ────────                    ───────
User (direct)    ───► (none — skills)             Worktree subagents (3+ tasks)
/think
/autopilot
forge-builder agent

READS                                   WRITES
─────                                   ──────
.forge/architecture/*.md                .forge/build/report.md
.forge/config.json                      .forge/context/task-{n}.md
.forge/context/task-{n}.md

SCRIPTS: quality-gate.sh (detect-runner, path-map, path-diff, reusability-search, coverage)
         context-prune.sh (clean, extract, conventions, estimate)
         telemetry.sh, manifest.sh
```

### /review (code review)

```
TRIGGERED BY          TRIGGERS (routes)           SPAWNS (agents)
─────────────         ────────                    ───────
User (direct)    ───► /review-request             (none)
/think (--auto)       /review-response
/autopilot            /review-adversarial
forge-reviewer agent

READS                                   WRITES
─────                                   ──────
.forge/build/report.md                  .forge/review/report.md
.forge/architecture/*.md

SCRIPTS: quality-gate.sh (dry-check, path-map, reusability-search, coverage)
         telemetry.sh
```

### /review adversarial

```
TRIGGERED BY          TRIGGERS                    SPAWNS (agents)
─────────────         ────────                    ───────
User (direct)    ───► (none)                      forge-adversarial-reviewer
/review routing

READS                                   WRITES
─────                                   ──────
.forge/build/report.md                  .forge/review/adversarial.md
.forge/architecture/*.md
```

### /verify

```
TRIGGERED BY          TRIGGERS                    SPAWNS (agents)
─────────────         ────────                    ───────
User (direct)    ───► /browse (web domain)        (none)
/think (--auto)
/autopilot
forge-verifier agent

READS                                   WRITES
─────                                   ──────
.forge/build/report.md                  .forge/verify/report.md
.forge/architecture/*.md
.forge/browse/report.md

SCRIPTS: quality-gate.sh (coverage), telemetry.sh
```

### /ship

```
TRIGGERED BY          TRIGGERS                    SPAWNS (agents)
─────────────         ────────                    ───────
User (direct)    ───► (none)                      (none)
/think (--auto)
/autopilot
forge-shipper agent

READS                                   WRITES
─────                                   ──────
.forge/review/report.md (REQUIRED)      .forge/releases/v[ver]/summary.md
.forge/verify/report.md (REQUIRED)      PR (via gh CLI)
.forge/review/adversarial.md (optional)
.forge/build/report.md
.forge/architecture/*.md

SCRIPTS: telemetry.sh
```

### /debug

```
TRIGGERED BY          TRIGGERS                    SPAWNS (agents)
─────────────         ────────                    ───────
User (direct)    ───► (none)                      (none)
/think (debug signals)

READS                          WRITES
─────                          ──────
(source code, logs)            .forge/debug/report.md
```

### /browse

```
TRIGGERED BY          TRIGGERS                    SPAWNS (agents)
─────────────         ────────                    ───────
User (direct)    ───► (none)                      (none)
/verify (web domain)

READS                          WRITES
─────                          ──────
(project files for URL)        .forge/browse/report.md
                               .forge/browse/flows.spec.js
                               .forge/browse/screenshots/
```

### /memory

```
TRIGGERED BY          TRIGGERS (routes)           SPAWNS (agents)
─────────────         ────────                    ───────
User (direct)    ───► /memory-remember            (none)
/architect            /memory-recall
/brainstorm           /memory-forget
/retro
/evolve
/autopilot

READS                          WRITES
─────                          ──────
~/.forge/memory.jsonl          ~/.forge/memory.jsonl
```

### /retro

```
TRIGGERED BY          TRIGGERS                    SPAWNS (agents)
─────────────         ────────                    ───────
User (direct)    ───► /memory-remember            (none)

READS                                   WRITES
─────                                   ──────
.forge/architecture/*.md                ~/.forge/retros/[date]_[project].json
.forge/verify/report.md
~/.forge/retros/*.json (trend analysis)
```

### /evolve

```
TRIGGERED BY          TRIGGERS                    SPAWNS (agents)
─────────────         ────────                    ───────
User (direct)    ───► /memory-remember            (none)

READS                                   WRITES
─────                                   ──────
~/.forge/retros/*.json                  ~/.forge/retros/evolve_[date].json
~/.forge/telemetry.jsonl                skills/[skill]/SKILL.md (edits)
~/.forge/memory.jsonl
skills/[skill]/SKILL.md

SCRIPTS: tests/test-routing.sh, test-blocking.sh, test-artifacts.sh (validation)
```

### /autopilot

```
TRIGGERED BY          TRIGGERS                    SPAWNS (agents)
─────────────         ────────                    ───────
User (direct)    ───► /think (classify only)      forge-builder (< 3 tasks)
                      /brainstorm (not TINY)      forge-reviewer (review loop)
                      /architect (not TINY)       forge-verifier (verify loop)
                      /build (inline or agent)    forge-shipper (ship)
                      /review (via agent loop)    forge-product (EPIC)
                      /verify (via agent loop)    forge-architect (EPIC)
                      /ship (via agent)           forge-security (EPIC)
                      /memory-remember

READS                                   WRITES
─────                                   ──────
.forge/build/report.md                  .forge/autopilot/state.json
.forge/review/report.md                 .forge/autopilot/future-enhancements.md
.forge/verify/report.md                 ~/.forge/memory.jsonl
.forge/architecture/*.md

SCRIPTS: autopilot-guard.sh, manifest.sh, telemetry.sh
```

### /design (hub)

```
TRIGGERED BY          TRIGGERS (routes)           SPAWNS (agents)
─────────────         ────────                    ───────
User (direct)    ───► /design-consult             (none)
                      /design-explore
                      /design-review
                      /design-audit
                      /design-polish

                      (NO skill outside /design triggers these)
```

### /design consult

```
TRIGGERED BY          TRIGGERS                    SPAWNS (agents)
─────────────         ────────                    ───────
/design hub      ───► (none)                      (none)

READS                                        WRITES
─────                                        ──────
skills/design/references/principles.md       .forge/design/consult-[topic].md
skills/design/references/typography.md
skills/design/references/color-and-contrast.md
skills/design/references/motion-design.md

SCRIPTS: telemetry.sh
```

### /design explore

```
TRIGGERED BY          TRIGGERS                    SPAWNS (agents)
─────────────         ────────                    ───────
/design hub      ───► (none)                      (none)

READS                                        WRITES
─────                                        ──────
skills/design/references/principles.md       .forge/design/explore-[topic].md
skills/design/references/typography.md
skills/design/references/color-and-contrast.md
```

### /design review

```
TRIGGERED BY          TRIGGERS                    SPAWNS (agents)
─────────────         ────────                    ───────
/design hub      ───► (none)                      (none)

READS                                        WRITES
─────                                        ──────
skills/design/references/principles.md       .forge/design/review-[topic].md
```

### /design audit

```
TRIGGERED BY          TRIGGERS                    SPAWNS (agents)
─────────────         ────────                    ───────
/design hub      ───► (none)                      (none)

READS                                        WRITES
─────                                        ──────
skills/design/references/principles.md       .forge/design/audit-[topic].md
skills/design/references/interaction-design.md
skills/design/references/responsive-design.md

SCRIPTS: telemetry.sh
```

### /design polish

```
TRIGGERED BY          TRIGGERS                    SPAWNS (agents)
─────────────         ────────                    ───────
/design hub      ───► (none)                      (none)

READS                                        WRITES
─────                                        ──────
skills/design/references/principles.md       .forge/design/polish-[topic].md
skills/design/references/typography.md
skills/design/references/color-and-contrast.md
.forge/design/consult-*.md (if exists)

SCRIPTS: telemetry.sh
```

### /worktree

```
TRIGGERED BY          TRIGGERS                    SPAWNS (agents)
─────────────         ────────                    ───────
User (direct)    ───► (none)                      (none)
/build (subagents)

READS                          WRITES
─────                          ──────
(git state)                    .forge/worktrees/[branch]/
```

### /finish

```
TRIGGERED BY          TRIGGERS                    SPAWNS (agents)
─────────────         ────────                    ───────
User (direct)    ───► (none)                      (none)

READS                          WRITES
─────                          ──────
.forge/review/report.md        (git merge, branch cleanup)
.forge/verify/report.md
```

### /benchmark

```
TRIGGERED BY          TRIGGERS                    SPAWNS (agents)
─────────────         ────────                    ───────
User (direct)    ───► (none)                      (none)

READS                               WRITES
─────                               ──────
.forge/benchmark/baseline.json      .forge/benchmark/report.md
                                    .forge/benchmark/baseline.json (optional)
```

### /canary, /deploy

```
TRIGGERED BY          TRIGGERS                    SPAWNS (agents)
─────────────         ────────                    ───────
User (direct)    ───► (none)                      (none)

READS                          WRITES
─────                          ──────
(deployment config)            .forge/deploy/last-deploy.json (/deploy)
```

### /careful, /freeze

```
TRIGGERED BY          TRIGGERS                    SPAWNS (agents)
─────────────         ────────                    ───────
User (direct)    ───► (none)                      (none)

Session-scoped only. No persistent artifacts.
```

### /document-release

```
TRIGGERED BY          TRIGGERS                    SPAWNS (agents)
─────────────         ────────                    ───────
User (direct)    ───► (none)                      (none)

READS                          WRITES
─────                          ──────
PR diff, release notes         Project docs (README, CHANGELOG, etc.)
```

### /forge

```
TRIGGERED BY          TRIGGERS                    SPAWNS (agents)
─────────────         ────────                    ───────
User (direct)    ───► (none)                      (none)

Read-only overview skill. No artifacts.
```

---

## Per-Agent Trigger Diagrams

### forge-builder

```
SPAWNED BY                MODEL    SKILLS        READS                          WRITES
──────────                ─────    ──────        ─────                          ──────
/think (TINY)             opus     forge:build   .forge/architecture/*.md       .forge/build/report.md
/autopilot (< 3 tasks)                           .forge/config.json             .forge/context/task-{n}.md
```

### forge-reviewer

```
SPAWNED BY                MODEL    SKILLS         READS                          WRITES
──────────                ─────    ──────         ─────                          ──────
/think (--auto)           opus     forge:review   .forge/build/report.md         .forge/review/report.md
/autopilot (Step 5)                               .forge/architecture/*.md
```

### forge-verifier

```
SPAWNED BY                MODEL    SKILLS         READS                          WRITES
──────────                ─────    ──────         ─────                          ──────
/think (--auto)           opus     forge:verify   .forge/build/report.md         .forge/verify/report.md
/autopilot (Step 6)                               .forge/architecture/*.md       .forge/browse/report.md
                                                  .forge/review/report.md        .forge/browse/screenshots/
```

### forge-shipper

```
SPAWNED BY                MODEL    SKILLS       READS                          WRITES
──────────                ─────    ──────       ─────                          ──────
/think (--auto)           opus     forge:ship   .forge/review/report.md        .forge/releases/v[ver]/summary.md
/autopilot (Step 7)                             .forge/verify/report.md        PR (via gh)
                                                .forge/build/report.md
                                                .forge/architecture/*.md
                                                .forge/review/adversarial.md
```

### forge-adversarial-reviewer

```
SPAWNED BY                MODEL    SKILLS         READS                          WRITES
──────────                ─────    ──────         ─────                          ──────
/review adversarial       opus     forge:review   .forge/build/report.md         .forge/review/adversarial.md
                                                  .forge/architecture/*.md
```

### forge-product, forge-architect, forge-security (Epic Agent Teams)

```
SPAWNED BY                EXECUTION ORDER
──────────                ───────────────
/think (EPIC)             1. forge-product (first, defines scope)
/autopilot (EPIC)         2. forge-architect + forge-security (parallel, consume product output)
                          3. Outputs synthesized into architecture doc for /build
```

---

## Artifact Flow Diagram

```
                    ~/.forge/memory.jsonl
                    ┌──── written by: /architect, /memory, /autopilot, /evolve, /retro
                    └──── read by:    /architect, /brainstorm, /memory, /evolve

                    ~/.forge/retros/*.json
                    ┌──── written by: /retro
                    └──── read by:    /evolve, /retro (trend)

                    ~/.forge/telemetry.jsonl
                    ┌──── written by: all skills (via telemetry.sh)
                    └──── read by:    /evolve

.forge/brainstorm/*.md ──written──► /brainstorm ──read──► /architect (Step 1.5)

.forge/architecture/*.md ──written──► /architect
                         ──read────► /build, /review, /verify, /ship, /retro
                                     forge-builder, forge-reviewer, forge-verifier, forge-shipper

.forge/build/report.md ──written──► /build
                       ──read────► /review, /verify, /ship, /autopilot, /finish
                                   forge-reviewer, forge-verifier, forge-shipper

.forge/review/report.md ──written──► /review
                        ──read────► /ship, /autopilot, /finish
                                    forge-shipper

.forge/review/adversarial.md ──written──► /review adversarial
                             ──read────► /ship (advisory)

.forge/verify/report.md ──written──► /verify
                        ──read────► /ship, /autopilot, /finish
                                    forge-shipper

.forge/browse/report.md ──written──► /browse
                        ──read────► /verify

.forge/design/consult-*.md ──written──► /design consult
                           ──read────► /design polish
                           ──user-driven──► pass path to /architect for design-aware architecture

.forge/design/explore-*.md ──written──► /design explore
                           ──read────► user (comparison reference)

.forge/design/review-*.md ──written──► /design review
                          ──read────► user (design quality gate)

.forge/design/audit-*.md ──written──► /design audit
                         ──read────► user (quality measurement)

.forge/design/polish-*.md ──written──► /design polish
                          ──read────► user (change log)
```

---

## Design Integration Status

`/design` is a **standalone suite** — no main pipeline skill reads `.forge/design/` artifacts automatically. This is intentional (decided in integration audit):

- Wiring design into `/build` would add a second source of truth alongside the architecture doc
- Wiring into `/ship` would pollute the security gate for non-frontend projects
- Wiring into `/autopilot` would add unreliable frontend detection and more failure points

**User-driven integration**: Pass `.forge/design/consult-*.md` path to `/architect` if you want architecture to respect design direction. Run `/design review` alongside code `/review` for frontend projects. The `/review` hub notes this as a suggestion.

---

## Script Dependency Map

| Script | Called By | Purpose |
|---|---|---|
| `scripts/quality-gate.sh` | `/build`, `/review`, `/verify` | Test detection, coverage, DRY, path-map, reusability |
| `scripts/context-prune.sh` | `/build` | Architecture doc section extraction, context bundles |
| `scripts/autopilot-guard.sh` | `/autopilot` | Iteration limits, phase gating, failure tracking |
| `scripts/manifest.sh` | `/autopilot`, `/build` | Run tracking, phase/artifact registration |
| `scripts/telemetry.sh` | All core skills | Invocation logging to `~/.forge/telemetry.jsonl` |
