# Contributing to FORGE

FORGE is MIT-licensed and welcomes contributions.

## How FORGE Works

FORGE skills are pure Markdown files. Each skill is a `SKILL.md` with YAML frontmatter that Claude Code reads and executes. There's no binary, no runtime, no build step.

```
skills/
  think/SKILL.md        # Entry point, task classification
  architect/SKILL.md    # Architecture planning
  build/SKILL.md        # TDD implementation
  verify/SKILL.md       # QA and testing
  ship/SKILL.md         # Security audit + PR
  memory/               # Decision memory
    SKILL.md            # Hub/router
    remember/SKILL.md   # Store decisions
    recall/SKILL.md     # Retrieve decisions
    forget/SKILL.md     # Remove decisions
  retro/SKILL.md        # Retrospective
  evolve/SKILL.md       # Self-evolution
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

## CI Validation

Every push runs CI that validates:
- All SKILL.md files have required frontmatter fields
- YAML frontmatter is well-formed
- No broken internal references

## Guidelines

- Keep skills focused — one skill, one job
- Instructions should be specific enough for Claude to follow without ambiguity
- Include clear output formats so users know what to expect
- Always include a "Rules" section listing hard constraints
- Don't duplicate logic across skills — delegate via skill chaining
- Test with real tasks, not toy examples

## Code of Conduct

Be kind, be helpful, ship working code.
