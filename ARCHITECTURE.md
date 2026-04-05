# FORGE Architecture

Design decisions and their rationale.

## Why Pure Markdown Skills (No Binary)

Claude Code discovers skills from `.claude/skills/<name>/SKILL.md` files. A SKILL.md file with YAML frontmatter and markdown instructions is all Claude needs to execute a structured workflow.

A binary would add:
- Build steps and platform-specific compilation
- A runtime dependency users must install and update
- A barrier to contribution (most Claude Code users aren't systems programmers)
- Lock-in to a single host (Claude Code only)

Pure Markdown means FORGE skills are portable to any AI coding tool that reads markdown instructions (Cursor, Codex CLI, Gemini CLI). No adapter layer needed for v1.

## Why JSONL for Memory

The memory bank (`~/.forge/memory.jsonl`) stores one JSON object per line:

```json
{"id":"abc123","project":"myapp","date":"2026-04-01","category":"architecture","decision":"Use PostgreSQL over SQLite","rationale":"Need concurrent writes from multiple services","anti_patterns":["SQLite for multi-service writes"],"tags":["database","postgres"],"confidence":0.9}
```

Why JSONL over SQLite, JSON array, or a database:
- **Human-readable**: `cat` or `grep` the file directly
- **Append-only**: No read-modify-write cycle. Just append a line.
- **Git-trackable**: Users can optionally version their memory bank
- **No dependencies**: No database driver, no schema migrations
- **Grep-friendly**: `grep "database" ~/.forge/memory.jsonl` just works

For v1, keyword + tag matching is sufficient for recall. Vector embeddings are deferred to v2 — only worth the complexity if recall accuracy becomes a real user complaint.

## Why Playwright for Browser Testing

`/verify` uses Playwright via `npx playwright` rather than Claude Code's built-in browser MCP tools because:
- **Cross-platform**: Works on Linux CI, Windows, macOS — not just the developer's machine
- **Headless**: Runs in CI without a display server
- **Programmable**: Full control over test flows, assertions, screenshots
- **No daemon**: `npx playwright` cold-starts in ~3 seconds. Acceptable for v1.

The MCP browser tools (`mcp__claude-in-chrome__*`) require Chrome running locally and don't work in CI. FORGE targets the full workflow including automated verification.

## Skill Discovery and Installation

FORGE skills live in `skills/` in the repo. The `setup` script copies them to `~/.claude/skills/` (global Claude Code skills directory), making them available in every project.

Why global install (not per-project):
- FORGE is a workflow framework, not a project dependency
- Skills like `/think` and `/architect` apply to any project
- Avoids polluting each project's `.claude/` directory
- Users can override globally-installed skills with project-local versions in `.claude/skills/`

## Skill Chaining

Skills invoke each other via `/skill-name` in their instructions:
- `/think` classifies complexity, then invokes `/architect` for features
- `/architect` produces a locked doc, then the user (or automation) invokes `/build`
- `/build` completes, then `/verify` runs
- `/verify` passes, then `/ship` creates the PR

Each phase produces an artifact (doc, code, test report) that the next phase consumes. This loose coupling means:
- Skills can be invoked independently
- Phases can be skipped when the user knows what they're doing
- New skills can be inserted into the chain without modifying existing ones

## Adaptive Complexity (/think)

Most frameworks force the same ceremony on every task. A one-line bug fix shouldn't require an architecture doc. An epic shouldn't skip planning.

`/think` classifies tasks into three tiers:
- **Tiny**: Direct build, no architecture phase
- **Feature**: Architecture first, then build
- **Epic**: Agent Teams with specialized roles (product, architecture, security), then build

Classification uses signals from the task description and codebase context, not arbitrary rules. The user can always override.

## Agent Teams for Epics

For epic-complexity tasks, `/think` spawns Claude Code Agent Teams with FORGE-specific roles. Each agent gets:
- A defined role (product scope, architecture, security)
- A structured prompt with specific deliverables
- An exit gate (the output format they must produce)

This is different from generic parallel agents because each agent has domain expertise encoded in its prompt, not just "help with this task."
