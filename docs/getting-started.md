# Getting Started with FORGE

## Requirements

- [Claude Code](https://docs.anthropic.com/en/docs/claude-code) installed and working
- Git
- (Optional) Bun or Node.js — needed for `/verify` Playwright tests

## Install

```bash
git clone https://github.com/yourusername/forge.git
cd forge
./setup
```

Setup takes under 60 seconds. It:
1. Creates `~/.forge/` (memory bank, sessions, retros)
2. Installs all FORGE skills to `~/.claude/skills/`

## Your First Session

Open any project in Claude Code and type:

```
/think Add a health check endpoint to the API
```

FORGE classifies the task and routes you:

- **Tiny** (config tweak, bug fix) — goes straight to `/build`
- **Feature** (new endpoint, component) — runs `/architect` first, then `/build`
- **Epic** (new system, migration) — spawns Agent Teams, then `/architect`, then `/build`

## Full Workflow Example

### 1. Think

```
/think Add user authentication with JWT
```

FORGE responds:
```
FORGE /think → FEATURE
Reasoning: New auth system touches API routes, middleware, and data model.
Route: /architect → /build → /verify → /ship
```

### 2. Architect

FORGE runs `/architect` automatically. It:
- Checks the memory bank for past auth decisions
- Analyzes your codebase
- Produces a locked architecture doc at `.forge/architecture/`

Review and approve the architecture.

### 3. Build

```
/build
```

FORGE implements the architecture with TDD:
- Writes failing tests first
- Implements until tests pass
- Runs 2-stage review (spec compliance + code quality)

### 4. Review

```
/review
```

FORGE reviews the build output against the architecture doc. Checks spec compliance, code quality, and security surface. Produces a report at `.forge/review/report.md`.

### 5. Verify

```
/verify
```

FORGE detects your project type (web/API/pipeline) and runs appropriate tests. Produces a pass/fail report.

### 6. Ship

```
/ship
```

FORGE runs a security audit (OWASP + STRIDE), auto-fixes critical issues, and creates a PR.

### 7. Retro

```
/retro
```

After shipping, FORGE asks three questions about what went well and what didn't. Stores structured data for `/evolve`.

### 8. Evolve

```
/evolve
```

After a few cycles, FORGE analyzes retro data and proposes improvements to its own skills. Low-risk changes apply automatically; high-risk changes need your approval.

## Memory

FORGE remembers architectural decisions across projects. After several sessions, you'll see at session start:

```
FORGE remembers:
- Use PostgreSQL for multi-service writes — SQLite locks on concurrent access (from myapp, 2026-04-01)
- JWT with refresh tokens for API auth — Simpler than session-based for microservices (from backend, 2026-03-15)
```

Manage memory manually:
```
/memory recall database      # Search past decisions
/memory remember "Use Redis for caching — sub-ms latency needed"
/memory forget postgres      # Remove outdated decisions
/memory forget --prune       # Auto-clean stale entries
```

## Project-Specific Config

Add a `CLAUDE.md` to any project root to set project conventions. FORGE respects these — it augments, never overrides. See [CLAUDE.md Template](CLAUDE-md-template.md).

## Next Steps

- [Skills Reference](skills-reference.md) — detailed docs for every skill
- [Memory Guide](memory-guide.md) — how the memory system works
- [Evolve Guide](evolve-guide.md) — how self-evolution works
- [Contributing](contributing.md) — how to contribute to FORGE
