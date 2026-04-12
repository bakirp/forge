# Shared Rules — All FORGE Skills

These rules apply to every skill. Do not duplicate them in individual skill files.

## Evidence Before Claims

After running any command, your response MUST include:
1. The exact command run
2. The terminal output (last 30 lines minimum)
3. The exit code or pass/fail summary line

Do NOT summarize results without showing actual output. If a command failed to run or timed out, state that explicitly.

## No Secrets

Never commit secrets, credentials, or API keys. If found, log as `critical` via compliance-log.sh.

## Scope Discipline

Do not add features, refactor code, or make improvements beyond what the current phase requires. A build doesn't need surrounding code cleaned up. A review doesn't modify code.

## Artifact Integrity

Every phase that produces an artifact must:
- Include `commit_sha` (from `git rev-parse HEAD`) for freshness checks
- Write to the correct `.forge/` subdirectory
- Update the run manifest if one exists

## What's Next Guidance

At the end of each skill, show the recommended next step based on the FORGE workflow:
- think -> brainstorm | architect | build (depends on classification)
- brainstorm -> architect
- architect -> build
- build -> review
- review -> verify
- verify -> ship
- ship -> deploy | retro
- deploy -> canary (optional) | retro
