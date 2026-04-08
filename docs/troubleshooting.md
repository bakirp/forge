# FORGE Troubleshooting Guide

## Tests fail during /build TDD loop
- Verify test runner detection: `bash scripts/quality-gate.sh detect-runner`
- If wrong runner detected: set `test_command` in `.forge/config.json`
- Run the test command manually to see full output
- If the test framework itself is broken: fix it first, then re-run /build

## Quality gate detects wrong test runner
- Check detection: `bash scripts/quality-gate.sh detect-runner`
- Override in `.forge/config.json`: `{"test_command": "your-command"}`
- Supported frameworks: Jest, Vitest, Mocha, Cypress, Playwright, Bun, pytest, Go test, Cargo test, Maven, Gradle, RSpec, Minitest, PHPUnit, dotnet test

## Coverage threshold blocking /build or /verify
- Check current coverage: `bash scripts/quality-gate.sh coverage`
- Check configured threshold: `jq .coverage_threshold .forge/config.json`
- Adjust threshold: edit `coverage_threshold` in `.forge/config.json`
- Override coverage tool: set `coverage_command` in `.forge/config.json`
- If coverage tool not detected: `bash scripts/quality-gate.sh detect-coverage`

## Path coverage audit flags false positives in /review
- Run `bash scripts/quality-gate.sh path-map . [files]` to see detected paths
- path-map uses grep-based heuristics, not AST parsing — it may flag comments or strings containing keywords
- For complex cases, the skill-level judgment in `/review` should filter false positives

## /verify reports FAIL but the app works manually
- Check if the correct port/URL is being tested
- Verify the dev server started (check for port conflicts)
- Run /browse standalone with the URL to isolate browser vs server issues

## /verify skips browser testing for projects without a dev server
- `/browse` should figure out how to run ANY web project, not just ones with a dev server
- Check `/browse` output — it should log how it resolved the entry point
- If detection fails: invoke `/verify web` to force web domain, or run `/browse [entry-point-url]` directly
- "No server" means "simpler to test," not "nothing to test" — functional testing is never optional

## Stale reports blocking /ship
- /ship blocks on /review and /verify failures — re-run both to generate fresh reports
- Delete .forge/review/report.md and .forge/verify/report.md to reset

## /evolve breaks a skill
- /evolve creates a backup before changes and auto-reverts on test failure
- If auto-revert failed: check $TMPDIR for forge-evolve-backup-*.md files
- Manual recovery: `git checkout -- skills/[skill]/SKILL.md`

## Memory bank too large or irrelevant results
- Run `/memory forget --prune` to remove stale entries
- Check size: `wc -l ~/.forge/memory.jsonl`
- If >500 entries: manually review and remove outdated decisions

## Subagent timeout or no output
- Task may be too large — break into smaller tasks
- Try executing inline without subagent
- Check if the specified model is available

## External tool not found
- **gh**: `brew install gh && gh auth login`
- **jq**: `brew install jq`
- **Playwright**: `npx playwright install`
