# Changelog

## v1.0.0 — 2026-04-05

First public release. All 7 core skills implemented.

### Skills

- **/think** — Adaptive entry point. Classifies tasks as tiny/feature/epic and routes to the right workflow depth. Epic tasks spawn Agent Teams with product, architecture, and security agents.
- **/architect** — Locks architecture before build. Queries memory bank for past decisions, produces structured architecture doc with data flow, API contracts, edge cases, and test strategy.
- **/build** — TDD-enforced implementation. Failing tests before code, 2-stage review (spec compliance + code quality), subagent execution in isolated worktrees, smart model routing (Haiku/Sonnet/Opus), token budget warnings.
- **/verify** — Cross-platform QA. Auto-detects project domain (web/API/pipeline). Playwright for browser testing, contract validation for APIs, output diffing for pipelines. Produces pass/fail report.
- **/ship** — Security audit + PR creation. OWASP Top 10 and STRIDE threat model checks. Auto-fixes critical issues. Creates PR with release summary. Blocks on /verify failures.
- **/memory** — Cross-project decision memory (remember/recall/forget). JSONL storage at ~/.forge/memory.jsonl. Keyword + tag matching for recall. Auto-prune for stale entries.
- **/retro** — Post-ship retrospective. Three structured questions + per-skill ratings. Stores JSON data that /evolve consumes.
- **/evolve** — Self-rewriting skills. Reads retro data, scores skill effectiveness, proposes targeted diffs. Low-risk changes auto-apply; high-risk changes require approval.

### Infrastructure

- Setup script: `git clone && ./setup` installs 12 skills in under 60 seconds
- GitHub Actions CI: validates SKILL.md frontmatter on every push
- Pure Markdown — no binary, no runtime dependencies

### Documentation

- Getting Started guide
- Skills Reference (all 7 skills with examples)
- Memory Guide
- Evolve Guide
- Contributing guidelines
- CLAUDE.md template for projects
- Architecture decision records
