# Contributing to FORGE

FORGE is MIT-licensed and welcomes contributions.

## How FORGE Works

FORGE skills are pure Markdown files. Each skill is a `SKILL.md` with YAML frontmatter that Claude Code reads and executes. There's no binary, no runtime, no build step.

```
skills/
  think/SKILL.md          # Adaptive entry point
  architect/SKILL.md      # Lock architecture
  build/SKILL.md          # TDD implementation
  review/SKILL.md         # Code review gate
    request/SKILL.md      # Prepare review request
    response/SKILL.md     # Process review feedback
  verify/SKILL.md         # Cross-platform QA
  ship/SKILL.md           # Security audit + PR
  debug/SKILL.md          # Root-cause debugging
  memory/SKILL.md         # Decision memory hub
    remember/SKILL.md
    recall/SKILL.md
    forget/SKILL.md
  retro/SKILL.md          # Post-ship retrospective
  evolve/SKILL.md         # Self-evolution
  brainstorm/SKILL.md     # Ideation before architecture
  worktree/SKILL.md       # Isolated workspace setup
  finish/SKILL.md         # Branch completion and merge
  browse/SKILL.md         # Playwright browser automation
  design/SKILL.md         # Design consultation hub
    consult/SKILL.md
    explore/SKILL.md
    review/SKILL.md
  benchmark/SKILL.md      # Performance benchmarking
  canary/SKILL.md         # Canary deployment
  deploy/SKILL.md         # Post-merge deployment
  document-release/SKILL.md # Post-ship docs sync
  careful/SKILL.md        # Destructive operation guard
  freeze/SKILL.md         # Scoped edit locks
  forge/SKILL.md          # FORGE overview and help
```

## Skill File Format

Every SKILL.md must have this frontmatter:

```yaml
---
name: skill-name
description: "One-sentence description"
argument-hint: "[example arguments]"
allowed-tools: Read Grep Glob Bash
---
```

Required fields:
- `name` — skill identifier (matches directory name, or `parent-child` for nested skills)
- `description` — what the skill does (used by Claude Code for discovery)
- `argument-hint` — example usage shown to users
- `allowed-tools` — which Claude Code tools this skill may use

## Making Changes

### Improving an Existing Skill

1. Fork the repo
2. Edit the SKILL.md file
3. Test by running `./setup` and using the skill in a Claude Code session
4. Submit a PR with:
   - What you changed and why
   - What problem you observed (ideally from a `/retro`)
   - How you tested it

### Adding a New Skill

1. Create `skills/[name]/SKILL.md` with the required frontmatter
2. Follow the existing skill patterns (step-by-step instructions, clear output formats, rules section)
3. Update `SKILL.md` (root bootstrap) to list the new skill
4. Update `docs/skills-reference.md`
5. Test via `./setup` and a Claude Code session

### Documentation

Docs live in `docs/`. Follow the existing style: practical, example-driven, no unnecessary prose.

## Artifact Freshness Requirements

`/review` and `/verify` reports must include `commit_sha` and `tree_hash` fields (see `docs/artifact-schema.md` for the exact format). These fields record the commit the report was written against. `/ship` validates them against the current HEAD and rejects stale reports.

If you are writing or modifying a skill that produces a review or verify report, make sure the report writes both fields. Before submitting a PR that touches the artifact pipeline, run:

```sh
scripts/artifact-check.sh
```

This validates `commit_sha` freshness against HEAD and will surface staleness errors before CI does.

## CI Validation

Every push runs CI that validates:
- All SKILL.md files have required frontmatter fields
- YAML frontmatter is well-formed
- No broken internal references

## Helper Scripts

Scripts in `scripts/` provide shared infrastructure for skills. Skills delegate detection and enforcement to scripts; scripts return structured output; skills make policy decisions.

| Script | Purpose |
|--------|---------|
| `quality-gate.sh` | Test detection (15+ frameworks), coverage enforcement, reusability search, DRY check, path coverage mapping, change impact analysis |
| `context-prune.sh` | Architecture doc section extraction, project conventions detection, token estimation |
| `telemetry.sh` | Skill invocation logging to `~/.forge/telemetry.jsonl` |
| `artifact-check.sh` | Artifact freshness validation (commit_sha vs HEAD) |
| `manifest.sh` | Run manifest tracking |
| `autopilot-guard.sh` | Iteration limit enforcement for `/autopilot` |

When writing a new skill that needs test runner detection, coverage checking, or code quality analysis, delegate to `scripts/quality-gate.sh` rather than reimplementing the logic. See `quality-gate.sh help` for available subcommands.

## Guidelines

- Keep skills focused — one skill, one job
- Instructions should be specific enough for Claude to follow without ambiguity
- Include clear output formats so users know what to expect
- Always include a "Rules" section listing hard constraints
- Don't duplicate logic across skills — delegate via skill chaining
- Test with real tasks, not toy examples

## Code of Conduct

Be kind, be helpful, ship working code.
