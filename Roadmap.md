# FORGE: Corrected Gap Analysis and Long-Term Roadmap

## Summary

Forge already captures the **workflow shape** of both source projects, but it does not yet include the **execution substrate** that makes either of them reliable at scale. The roadmap should therefore optimize for:

1. Make Forge’s current core workflow enforceable and testable.
2. Add the missing operational substrate from Superpowers and gstack.
3. Expand into specialist workflows only after the core loop is trustworthy.

## Validated Gap Analysis

### What Forge already has today

These are genuinely present in the current skill layer:
- Adaptive task routing via `/think`
- Architecture-first planning via `/architect`
- TDD-oriented build flow via `/build`
- Inline two-stage review inside `/build`
- Verification and shipping gates via `/verify` and `/ship`
- Cross-project memory via `/memory`
- Retrospective and self-improvement via `/retro` and `/evolve`
- Pure Markdown skill architecture

### What Forge has only partially

These exist as prompt-level workflow intent, but are not yet backed by robust tooling:
- Subagent orchestration
- Worktree isolation
- Model routing (`haiku` / `sonnet` / `opus`)
- Playwright-based browser verification
- Ship automation beyond PR-oriented release gating

### Missing from gstack that Forge should adopt

**High priority**
- Dedicated browser skill and browser substrate, not just Playwright instructions inside `/verify`
- Design as a first-class workflow: design consultation, variant exploration, design review
- Cross-model second opinion similar to `/codex`
- Guardrails for destructive operations and scoped edit locks
- Secrets archaeology and git-history credential scanning
- Session intelligence: timelines, context recovery, usage tracking
- Multi-host install/distribution
- Documentation sync after shipping
- Deploy/land flow after PR creation

**Corrections to preserve**
- gstack’s debugging analogue is `/investigate`, not `/debug`
- `/freeze` and `/unfreeze` are edit-scope guards, not branch-state management
- The DeBERTa prompt-injection classifier is planned/design work in gstack, not a fully shipped capability
- Merge/deploy is primarily handled by `/land-and-deploy`, while `/ship` is the pre-merge release gate

### Missing from Superpowers that Forge should adopt

**High priority**
- A root bootstrap/dispatcher discipline equivalent to `using-superpowers`
- Brainstorming or ideation before locking architecture
- Root-cause-first debugging as a dedicated skill
- Evidence-before-claims verification as an explicit rule across the framework
- Explicit plan execution with progress tracking
- Dedicated worktree lifecycle and branch-finishing workflows
- Dedicated code-review request/reception workflows
- Context-pruned subagent dispatch
- Skill test harnesses and workflow fixtures

## Roadmap

### Phase 1: Make Forge’s current core trustworthy

**Goal:** turn the current skills from descriptive prompts into an enforceable workflow.

- Upgrade the root [SKILL.md](/Users/bakir/Personal/Learning/Forge/SKILL.md) into a real dispatcher that prefers skill invocation before ad-hoc action.
- Add two missing first-class skills: `/review` and `/debug`.
- Change the primary flow to:
  `/think -> /architect -> /build -> /review -> /verify -> /ship -> /retro -> /evolve`
- Add lightweight artifact contracts under `.forge/`:
  - architecture docs
  - review report
  - verify report
  - debug report
  - run manifest
- Introduce a canonical run manifest at `.forge/runs/<run-id>/manifest.json` with phase, status, task, artifact paths, and blockers.
- Make `/ship` block on both `/review` and `/verify`, not only `/verify`.
- Freeze `/evolve` to proposal-only until workflow tests exist.
- Add a skill test harness for routing, blocking, and artifact generation.

**Deliverables**
- `/review` skill
- `/debug` skill
- `.forge` artifact schema
- test harness and prompt fixtures
- updated docs matching real behavior

### Phase 2: Add missing Superpowers-style execution discipline

**Goal:** close the largest workflow gaps with minimal tooling.

- Add `/brainstorm` before `/architect` for work that needs ideation, product clarification, or alternative exploration.
- Add `/worktree` for isolated workspace setup and `/finish` for branch completion.
- Split `/build` responsibilities more clearly:
  - plan execution
  - subagent-driven implementation
  - progress marking
- [x] Enforce fresh verification evidence before claiming success in `/build`, `/review`, `/verify`, and `/ship`.
- Rework subagent prompts so each task gets only the required context, not the full session.
- Add dedicated review workflows:
  - request review
  - process review feedback
- Introduce a final branch lifecycle gate before PR/merge decisions.

**Deliverables**
- `/brainstorm`
- `/worktree`
- `/finish`
- [x] evidence-before-claims rules
- context-pruned subagent pattern
- dedicated review request/response flows

### Phase 3: Add gstack-style operational substrate

**Goal:** make Forge practical for real release and QA work.

- Add `/browse` as a dedicated browser skill, implemented with Playwright plus helper scripts.
- Move web-flow execution details out of `/verify` so `/verify` becomes the report-and-gate layer.
- Extend [setup](/Users/bakir/Personal/Learning/Forge/setup) to support Claude first, Codex second.
- Add helper scripts for:
  - artifact discovery
  - manifest updates
  - memory ranking/dedup
  - host-aware installation
- Strengthen `/ship` with:
  - version bump policy
  - changelog generation
  - release artifact generation
  - doc-sync hook
- Add `/document-release`.
- Add secrets archaeology to `/ship` or a dedicated security workflow, including git-history scanning.
- Add `/careful` and `/freeze` equivalents as opt-in guard skills.

**Deliverables**
- `/browse`
- multi-host setup for Claude and Codex
- helper scripts in `scripts/`
- `/document-release`
- guardrails for destructive ops and scoped edits
- stronger ship/release contract

### Phase 4: Expand into specialist workflows

**Goal:** bring in the best of gstack without bloating Forge too early.

- Add design workflows:
  - design consultation
  - design variant exploration
  - design review
- Add performance and release extensions:
  - benchmark
  - canary
  - deploy/land
- Add cross-model second-opinion review once Codex support is stable.
- Expand retro into project and cross-project trend analysis.
- Re-enable limited auto-apply in `/evolve` only for low-risk wording and clarity changes after skill tests are stable.

**Deliverables**
- design skill suite
- benchmark/canary/deploy flows
- cross-model review
- safer long-term evolution loop

## Test Plan

- Routing tests: confirm that feature, bug, review, verify, and ship requests trigger the correct skill path.
- Blocking tests: `/ship` must fail without passing `/review` and `/verify`.
- Artifact tests: every core skill writes a valid, parseable artifact and updates the run manifest correctly.
- Memory tests: append, dedup, recall ranking, prune safety, invalid JSON prevention.
- Browser tests: `/browse` and `/verify` web mode produce deterministic reports and failure evidence.
- Setup tests: Claude and Codex install paths work from one repo.
- Evolution safety tests: `/evolve` never auto-applies structural changes without test coverage.

## Assumptions and Defaults

- Forge remains **Markdown-first with light tooling**, not a heavy binary product.
- Claude is the first-class host; Codex is second priority.
- Browser support should be Playwright-based, not a custom browser app, until the core workflow is stable.
- The next implementation priority is **core trustworthiness**, not immediate specialist-skill breadth.
- gstack-inspired features should be adopted selectively, only when they materially improve enforcement, QA, or release reliability.
