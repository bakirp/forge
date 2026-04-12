# Shared Compliance & Telemetry Protocol

All FORGE skills follow this protocol. Do not duplicate these instructions in individual skill files — reference this document instead.

## Compliance Logging

Log violations when detected using:
```bash
bash scripts/compliance-log.sh <skill_name> <rule_key> <severity> "<details>"
```

Parameters:
- `skill_name`: the invoking skill (e.g., build, review, ship)
- `rule_key`: kebab-case violation identifier (e.g., `tdd-violation`, `stale-artifact`)
- `severity`: `critical` | `major` | `minor` | `info`
- `details`: free-text description of what happened

**When to log:** Log at the moment a violation is detected, before attempting to fix it. If a violation is detected and fixed in the same step, still log it.

**Severity guide:**
- `critical`: Security issue, data loss risk, or skipped safety gate (secrets in code, missing prerequisites, stale artifacts)
- `major`: Process violation that could affect output quality (skipped review, TDD violation, ungrounded claims)
- `minor`: Best-practice deviation with low impact (scope creep, memory not checked)
- `info`: Informational event worth tracking (fallback used, optional step skipped)

## Telemetry

After a skill completes (or fails), log the invocation and phase transition:
```bash
bash scripts/telemetry.sh <skill_name> <outcome>
bash scripts/telemetry.sh phase-transition <skill_name>
```

Outcomes: `completed` | `error` | `aborted` | `blocked`

## Error Handling (Default)

If any step fails unexpectedly:
1. State what failed and show the error output
2. State what has been completed so far
3. State what remains
4. Ask the user: retry this step, skip it, or abort

Never silently continue past a failed step.

Skills with domain-specific error handling (review, verify, architect) override this default in their own SKILL.md.
