---
name: ship
description: "Security audit + PR creation. Reads /verify report (blocks on failure), runs OWASP Top 10 and STRIDE threat model checks, auto-fixes critical security issues, and creates a PR with release summary. Use when ready to ship — triggered by 'ship it', 'create a PR', 'ready to merge', 'release this'."
argument-hint: "[optional: --canary | --draft]"
allowed-tools: Read Grep Glob Write Edit Bash Agent
---

# /ship — Security Audit + PR + Deploy

Never ship with /review failures or /verify failures — no override, no flag, no exception. Secrets found in code or git history are always critical.

## Step 0: Context Detection

**If subagent** (spawned by `forge-shipper`): resolve feature via `bash scripts/manifest.sh resolve-feature-name`, load build report `.forge/build/${FEATURE_NAME}.md` and architecture doc from `.forge/architecture/*.md`. No prior history — fresh security review by design. **If inline**: proceed.

## Step 1: Load and Gate on Reports

```bash
FEATURE_NAME=$(bash scripts/manifest.sh resolve-feature-name)
```

### Review Report Gate

Read `.forge/review/${FEATURE_NAME}.md`. Check `## Status:` line. If missing or Status is FAIL/NEEDS_CHANGES:
```bash
bash scripts/compliance-log.sh ship missing-prerequisite critical "Attempted to ship without review report"
```
**STOP, block shipping.**

Freshness check:
```bash
bash scripts/artifact-check.sh review .forge/review/${FEATURE_NAME}.md
```
If Status: STALE (non-zero exit):
```bash
bash scripts/compliance-log.sh ship stale-artifact critical "Review report is stale — commit_sha does not match HEAD"
```
**STOP.**

### Verify Report Gate

Read `.forge/verify/${FEATURE_NAME}.md`. Check `## Status:` line. If missing or Status is FAIL:
```bash
bash scripts/compliance-log.sh ship missing-prerequisite critical "Attempted to ship without verification report"
```
**STOP, block shipping.** No `--force`, no override, no exceptions.

Freshness check:
```bash
bash scripts/artifact-check.sh verify .forge/verify/${FEATURE_NAME}.md
```
If STALE:
```bash
bash scripts/compliance-log.sh ship stale-artifact critical "Verify report is stale — commit_sha does not match HEAD"
```
**STOP.**

**After any auto-fix (Step 4)**, both reports become stale — re-run /review and /verify before PR creation.

## Step 2: Version and Release Preparation

Detect version files (`grep -r '"version"' package.json Cargo.toml pyproject.toml setup.py 2>/dev/null | head -5`). If found, suggest bump: **Patch** (bug fixes), **Minor** (new features, backwards-compatible), **Major** (breaking changes). Confirm with user before applying.

If `CHANGELOG.md` exists, prepend entry with version, date, and grouped changes. Don't create one uninvited.

## Step 3: Security Audit

Identify changed files:
```bash
DEFAULT_BRANCH=$(bash scripts/detect-branch.sh)
git diff --name-only ${DEFAULT_BRANCH}...HEAD
```

Run OWASP Top 10 and STRIDE threat model checks against changed files. Read `skills/ship/references/security-checks.md` for full checklists.

**Adversarial review**: if `.forge/review/adversarial.md` exists — `NO-SHIP` is advisory only (note prominently); `SHIP`/`SHIP-WITH-CAVEATS` adds confidence. Report findings with severity counts (critical/warning/info), citing file:line:pattern for each.

## Step 4: Auto-Fix Critical Issues

**Auto-fix without approval**:
- Remove hardcoded credentials, replace with env var references
- Replace SQL string concatenation with parameterized queries
- Add HTML output escaping for raw user input

**Require user approval**:
- Business logic or control flow changes
- API contract modifications
- Test behavior or assertion changes
- Multiple possible fix locations
- Cryptographic code changes
- New middleware or interceptors

When in doubt, require approval. After any auto-fix, re-run /review and /verify.

## Step 5: Create PR

Arguments: `--canary` (canary deploy), `--draft` (draft PR), `--skip-security` (requires confirmation; log skip in PR description).

Generate release summary from `git log --oneline ${DEFAULT_BRANCH}..HEAD`. PR body must include: summary bullets, changes by type, verification results, adversarial review status if performed, and test plan checklist.

```bash
DEFAULT_BRANCH=$(bash scripts/detect-branch.sh)
git diff --name-only ${DEFAULT_BRANCH}...HEAD | xargs git add
git add [files modified by security fixes]
git commit -m "[summary of changes]"
git push -u origin [branch-name]
gh pr create --title "[concise title under 70 chars]" --body "[generated summary]" [--draft if flag set]
```

Never use `git add -A` — stage only files modified during this build cycle.

### Release Artifacts

```bash
mkdir -p .forge/releases/v[version]
```
Create `.forge/releases/v[version]/summary.md` with: date, PR URL, grouped changes, security audit results, and paths to architecture/review/verify artifacts.

## Step 6: Report

Verify PR exists before claiming shipped:
```bash
gh pr view --json url,state,title
```

Output must include the PR URL — never claim "shipped" without it. Show: security audit result, PR URL, canary/draft status if applicable.

## Rules & Compliance

- **Never ship with /review or /verify failures** — output `FORGE /ship — BLOCKED: [reason]` if prerequisites fail
- **Secrets are always critical** — in code or git history
- Auto-fix only clear, unambiguous security issues; ask for approval on anything complex
- PR description must be useful to a human reviewer, not just a git log dump
- `--skip-security`: add prominent warning to PR description
- Re-run tests after every auto-fix — if a security fix breaks tests, always stop and ask
- **Evidence before claims** — every finding must cite file:line:pattern; never claim "no issues" without listing what was scanned
- Version bump is optional — skip if no version file or user declines
- **Compliance logging & telemetry**: follow `skills/shared/compliance-telemetry.md`. Ship-specific keys: `missing-prerequisite`, `stale-artifact`, `secrets-in-code`, `secrets-in-history`, `unapproved-auto-fix`, `tests-not-rerun-after-fix`, `ungrounded-finding`.
- **Error handling**: follow `skills/shared/rules.md`.
- Log phase-transition telemetry and compliance via `scripts/telemetry.sh` and `scripts/compliance-log.sh` per shared protocol.

> **What's next**: see `skills/shared/workflow-routing.md`. After /ship: /deploy or /retro. If API contracts changed, suggest /document-release.
