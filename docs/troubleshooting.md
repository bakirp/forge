# FORGE Troubleshooting Guide

## Tests fail during /build TDD loop
- Verify test runner detection: check package.json "scripts.test" or set `test_command` in .forge/config.json
- Run the test command manually to see full output
- If the test framework itself is broken: fix it first, then re-run /build

## /verify reports FAIL but the app works manually
- Check if the correct port/URL is being tested
- Verify the dev server started (check for port conflicts)
- Run /browse standalone with the URL to isolate browser vs server issues

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
