# FORGE Skills Reference

Quick reference for all FORGE skills. For detailed steps and rules, see each skill's `SKILL.md` file directly.

## Skill Chain

```
/think → /architect → /build → /review → /verify → /ship → /retro → /evolve
                ↕                                      ↕
             /memory                                /memory

Standalone:  /debug, /browse, /design, /benchmark
Lifecycle:   /worktree, /finish, /document-release
Guards:      /careful, /freeze
Deploy:      /canary, /deploy
Ideation:    /brainstorm → /architect
Automation:  /autopilot (full pipeline, zero prompts)
```

---

## Core Pipeline

| Skill | Phase | Usage | Purpose |
|-------|-------|-------|---------|
| `/think` | Planning | `/think [description]` | Classifies complexity (tiny/feature/epic), generates a feature name (Step 4.5), routes to appropriate workflow depth. `--auto` chains the full pipeline. |
| `/architect` | Planning | `/architect [description]` | Produces locked architecture doc with data flow, API contracts, edge cases, test strategy. Reads/writes memory. |
| `/build` | Build | `/build [arch doc or 'continue']` | TDD implementation with subagent execution, path coverage, reusability search. Writes `.forge/build/[feature-name].md`. |
| `/review` | Review | `/review [files or focus]` | Code review gate: spec compliance, quality, DRY, path coverage, security surface. Writes `.forge/review/[feature-name].md`. |
| `/verify` | QA | `/verify [web\|api\|pipeline]` | Cross-platform verification: Playwright for web, contract validation for API. Writes `.forge/verify/[feature-name].md`. |
| `/ship` | Ship | `/ship [--canary] [--draft]` | OWASP + STRIDE security audit, auto-fix, PR creation. Blocks on `/review` and `/verify` failures. |

## Review Sub-Skills

| Skill | Usage | Purpose |
|-------|-------|---------|
| `/review request` | `/review request [scope]` | Prepares scoped review request with criteria and context. |
| `/review response` | `/review response [feedback]` | Processes review feedback with anti-sycophancy gate — verifies before implementing. |
| `/review adversarial` | `/review adversarial [focus]` | Red-team review across 7 attack surfaces. Status: SHIP/NO-SHIP/SHIP-WITH-CAVEATS. |

## Memory Sub-Skills

| Skill | Usage | Purpose |
|-------|-------|---------|
| `/memory recall` | `/memory recall [terms]` | Retrieve ranked decisions. Top 5 by: project match > tag overlap > category > recency. |
| `/memory remember` | `/memory remember [decision]` | Store architectural decision. Deduplicates, confirms with user. |
| `/memory forget` | `/memory forget [terms]` | Delete entries by search or `--prune` (6+ months, low confidence). |

## Design Sub-Skills

| Skill | Usage | Purpose |
|-------|-------|---------|
| `/design consult` | `/design consult [context]` | Design consultation with aesthetic direction, anti-pattern enforcement, accessibility-first. |
| `/design explore` | `/design explore [context]` | Generate 3-4 distinct design variants with comparison table. |
| `/design review` | `/design review [context]` | Design review against principles, anti-patterns, accessibility. PASS/NEEDS_CHANGES. |
| `/design audit` | `/design audit [context]` | Technical quality measurement (0-10 per dimension). Not a gate. |
| `/design polish` | `/design polish [context]` | Final 6-check visual sweep. Makes fixes directly. |

## Standalone Skills

| Skill | Phase | Usage | Purpose |
|-------|-------|-------|---------|
| `/debug` | Any | `/debug [description]` | Root-cause debugging: evidence collection, ranked hypotheses, minimal fix. |
| `/brainstorm` | Ideation | `/brainstorm [description]` | 3-5 alternative approaches with trade-offs. `--grill` stress-tests existing plans. |
| `/browse` | Browser | `/browse [url or flow]` | Playwright browser automation with screenshots. |
| `/benchmark` | Performance | `/benchmark [target]` | Performance benchmarking with baseline comparison and regression detection. |

## Lifecycle & Guards

| Skill | Usage | Purpose |
|-------|-------|---------|
| `/worktree` | `/worktree [branch]` | Create isolated git worktree for task isolation. |
| `/finish` | `/finish [branch]` | Merge branch back, run tests, clean up worktree. |
| `/careful` | `/careful [on\|off]` | Session-scoped warning before destructive operations. |
| `/freeze` | `/freeze [patterns]` | Session-scoped edit locks on files/directories. |
| `/document-release` | `/document-release [PR#]` | Post-ship documentation sync. |
| `/retro` | `/retro [context]` | Post-ship retrospective: 3 questions + skill ratings. Feeds `/evolve`. |
| `/evolve` | `/evolve [skill]` | Self-rewriting skills based on retro data. Risk-classified changes. |

## Deploy

| Skill | Usage | Purpose |
|-------|-------|---------|
| `/canary` | `/canary [percentage]` | Gradual rollout (default 10%), monitor, promote or rollback. |
| `/deploy` | `/deploy [environment]` | Post-merge deployment + health verification. |

## Automation

| Skill | Usage | Purpose |
|-------|-------|---------|
| `/autopilot` | `/autopilot [description]` | Full pipeline, zero user prompts. Continuous execution from think → ship without pausing. Guard-enforced iteration limits, self-healing loops. |
| `/forge` | `/forge` | FORGE overview, skill listing, red-flags table. |

---

## Quality Gates — `scripts/quality-gate.sh`

Shared infrastructure consumed by `/build`, `/review`, and `/verify`.

| Command | Purpose | Used by |
|---------|---------|---------|
| `detect-runner [root]` | Detect test framework (15+ supported) | `/build`, `context-prune.sh` |
| `detect-coverage [root]` | Detect coverage tool | `/build`, `/review`, `/verify` |
| `coverage [root] [--threshold N]` | Run coverage, enforce threshold | `/build`, `/review`, `/verify` |
| `reusability-search [root] [patterns...]` | Find existing functions | `/build`, `/review` |
| `dry-check [root] [files...]` | Detect duplicate code blocks | `/review` |
| `path-map [root] [files...]` | Extract condition paths | `/build`, `/review` |
| `path-diff [root] [base-branch]` | Change impact classification | `/build` |

**Supported Frameworks**: Jest, Vitest, Mocha, Cypress, Playwright, Bun, pytest, Go test, Cargo test, Maven, Gradle, RSpec, Minitest, PHPUnit, dotnet test. Config override: `.forge/config.json` `test_command`.

**Configuration**: Override via `.forge/config.json`: `test_command`, `coverage_command`, `coverage_threshold`.

---

## Compliance Logging -- `scripts/compliance-log.sh`

Logs rule violations to `.forge/compliance.jsonl`. Integrated into `/build`, `/review`, `/ship`, `/verify`, and `/autopilot`. Each violation is a JSONL entry with timestamp, phase, rule identifier, detail, and severity. See [Artifact Schema](artifact-schema.md#compliance-log) for the full schema.

---

## Feature-Named Artifacts

All handover documents are named after the feature (e.g., `.forge/build/add-user-auth.md`) instead of using a generic `report.md`. The feature name is generated by `/think` Step 4.5, stored in the manifest via `scripts/manifest.sh feature-name`, and resolved by all skills via `scripts/manifest.sh resolve-feature-name`. Falls back to `report` for backward compatibility.

---

## "What's Next" Guidance

Every skill now includes a "What's Next" section at the end of its output. This section suggests:

- **Recommended next action** -- the most common or logical next step in the pipeline.
- **Alternative actions** -- other valid next steps depending on the user's intent.

This helps users navigate the FORGE workflow without memorizing the full skill chain.

---

## Test Suites

| Test | Purpose |
|------|---------|
| `tests/test-routing.sh` | Skill routing and classification |
| `tests/test-blocking.sh` | Blocking gate enforcement |
| `tests/test-artifacts.sh` | Artifact creation and schema compliance |
| `tests/test-memory.sh` | Memory bank operations |
| `tests/test-browser.sh` | Browser automation |
| `tests/test-evolution.sh` | Self-evolution safety |
| `tests/test-completeness.sh` | Documentation completeness |
| `tests/test-manifest.sh` | Run manifest tracking |
| `tests/test-hooks.sh` | Hook registration and firing |
| `tests/test-telemetry.sh` | Telemetry logging |
| `tests/test-autopilot-guard.sh` | Autopilot iteration limits |
| `tests/test-context-prune.sh` | Context pruning |
| `tests/test-quality-gate.sh` | Quality gate subcommands |
| `tests/test-design.sh` | Design skill suite |
| `tests/test-handover.sh` | Build handover artifacts |
| `tests/test-adversarial.sh` | Adversarial review |
| `tests/test-feature-naming.sh` | Feature-named artifact generation and resolution |
| `tests/test-compliance-log.sh` | Compliance log creation and schema |
| `tests/test-next-steps.sh` | "What's Next" section presence in skill output |
