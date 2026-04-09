# CLAUDE.md

## Testing

Run all test suites:
```bash
for t in tests/test-*.sh; do bash "$t"; done
```

Run a single test:
```bash
bash tests/test-<name>.sh
```

Eval scoring (requires `jq`):
```bash
./evals/score.sh                     # reads evals/results.jsonl
./evals/score.sh path/to/other.jsonl # custom file
```

## Commits

Use conventional commit format:
- `feat:` for new features (new skills, new extensions)
- `fix:` for bug fixes
- `chore:` for maintenance, cleanup, config changes
- `docs:` for documentation-only changes
- `test:` for test-only changes
- `refactor:` for code reorganization without behavior changes
- **DO NOT** mention Co-Authored-By *

## **MANDATORY** Pre-Ship Completeness Checklist which apply always. If in doubt ASK don't assume.

Before marking any skill addition or modification as done, work through this checklist:

1. **README.md** — Is the skill listed in the core workflow or extensions table?
2. **docs/skills-reference.md** — Is there a detailed entry for this skill?
3. **CHANGELOG.md** — Is there a changelog entry for this change?
4. **docs/skill-trigger-map.md** — If this skill triggers or is triggered by others, is the trigger graph updated?
5. **tests/test-*.sh** — Does a test exist for this skill, or was an existing test updated?
6. **All tests pass** — Run `for t in tests/test-*.sh; do bash "$t"; done` and confirm all tests pass.
7. **Plugin version bumped** — In `.claude-plugin/plugin.json`, bump the version: patch for fixes, minor for new skills.
8. **Marketplace in sync** — Is `.claude-plugin/marketplace.json` updated with the same version as `plugin.json`?

Do not mark work complete until all items are addressed.
