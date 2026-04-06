---
name: ship
description: "Security audit + PR creation + deploy. Reads /verify report (blocks on failure), runs OWASP Top 10 and STRIDE threat model checks, auto-fixes critical security issues, creates a PR with release summary, and optionally supports canary deploys. Use when ready to ship — triggered by 'ship it', 'create a PR', 'deploy', 'release this'."
argument-hint: "[optional: --canary | --draft]"
allowed-tools: Read Grep Glob Write Edit Bash Agent
---

# /ship — Security Audit + PR + Deploy

You are the final gate. Nothing ships without passing security review and verification.

## Step 1: Read Verification Report

### Check Review Report

Find and read the `/review` report:

```bash
cat .forge/review/report.md
```

Parse the status line. If **Status: FAIL** or **Status: NEEDS_CHANGES**:

```
FORGE /ship — BLOCKED

/review reported issues. Shipping is not allowed until review passes.

Issues:
- [list from report]

Fix the issues, run /review again, then /ship.
```

**Stop here. Do not proceed.**

If no review report exists:
```
FORGE /ship — BLOCKED

No review report found. Run /review first.
```

**Freshness check — review report:** After confirming the review report exists and passes, verify it was written against the current commit:

```bash
CURRENT_SHA=$(git rev-parse HEAD)
REVIEW_SHA=$(grep "^## commit_sha:" .forge/review/report.md | awk '{print $NF}')
if [[ "$REVIEW_SHA" != "$CURRENT_SHA" ]]; then
  echo "STALE: review report is from $REVIEW_SHA, current HEAD is $CURRENT_SHA"
fi
```

If the `commit_sha` in the review report does not match `git rev-parse HEAD`, block shipping:

```
FORGE /ship — BLOCKED

The review report is stale (written against a different commit).
Report commit: [report commit_sha]
Current HEAD:  [git rev-parse HEAD]

Re-run /review, then /ship.
```

**Stop here. Do not proceed.**

### Check Verification Report

Find and read the `/verify` report:

```bash
cat .forge/verify/report.md
```

Parse the status line. If **Status: FAIL**:

```
FORGE /ship — BLOCKED

/verify reported failures. Shipping is not allowed.

Failures:
- [list from report]

Fix the failures, run /verify again, then /ship.
```

**Stop here. Do not proceed.** No `--force`, no override, no exceptions.

If no report exists:
```
FORGE /ship — BLOCKED

No verification report found. Run /verify first.
```

**Freshness check — verify report:** After confirming the verify report exists and passes, verify it was written against the current commit:

```bash
CURRENT_SHA=$(git rev-parse HEAD)
VERIFY_SHA=$(grep "^## commit_sha:" .forge/verify/report.md | awk '{print $NF}')
if [[ "$VERIFY_SHA" != "$CURRENT_SHA" ]]; then
  echo "STALE: verify report is from $VERIFY_SHA, current HEAD is $CURRENT_SHA"
fi
```

If the `commit_sha` in the verify report does not match `git rev-parse HEAD`, block shipping:

```
FORGE /ship — BLOCKED

The verify report is stale (written against a different commit).
Report commit: [report commit_sha]
Current HEAD:  [git rev-parse HEAD]

Re-run /verify, then /ship.
```

**Stop here. Do not proceed.**

**Note on auto-fix staleness:** Step 4 (Auto-Fix Critical Issues) modifies source files, which changes the working tree but does not automatically update the commit SHA. After any auto-fix is applied, treat both the review and verify reports as stale — their `commit_sha` fields will no longer reflect the fixed state. You must re-run /review and /verify before proceeding to PR creation. Do not skip this requirement.

If **Status: PASS** and freshness checks pass, proceed.

## Step 2: Version and Release Preparation

### Detect Version File

Look for version declarations in the project:
```bash
# Check common locations
grep -r '"version"' package.json Cargo.toml pyproject.toml setup.py 2>/dev/null | head -5
```

### Bump Version

If a version file is found, suggest a bump based on the changes:
- **Patch** (x.x.X): Bug fixes, minor changes, no new features
- **Minor** (x.X.0): New features, backwards-compatible changes
- **Major** (X.0.0): Breaking changes, API changes

```
FORGE /ship — Version bump

Current version: [version]
Changes suggest: [patch | minor | major]
Reasoning: [1-line explanation]

New version: [bumped version]
Apply? (y/n, or specify version)
```

Apply the version bump to the detected file(s).

### Generate Changelog Entry

If `CHANGELOG.md` exists, prepend a new entry:

```markdown
## v[new-version] — [YYYY-MM-DD]

[1-2 sentence summary of the release]

### [Features | Fixes | Security | Changes]
- [entries from git log, grouped by type]
```

If no CHANGELOG.md, skip — don't create one uninvited.

## Step 3: Security Audit

Scan all files created or modified during this build cycle. Detect the base branch and use `git diff --name-only` to identify changed files:

```bash
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
git diff --name-only ${DEFAULT_BRANCH}...HEAD
```

### Security Checks

Run the OWASP Top 10 and STRIDE threat model checks. See `references/security-checks.md` for the full checklists.

Read `skills/ship/references/security-checks.md` for the detailed OWASP Top 10 checklist, STRIDE threat model questions, and secrets archaeology process. Apply each check to the changed files.

### Report Findings

```
FORGE /ship — Security Audit

OWASP Top 10:
  [✓] No injection vulnerabilities
  [✓] Authentication checks present
  [✗] CRITICAL: Hardcoded API key in src/config.js:42
  ...

STRIDE:
  [✓] Spoofing: Auth tokens validated
  [!] WARNING: No rate limiting on /api/login
  ...

Critical: [count] — must fix before shipping
Warning: [count] — recommend fixing
Info: [count] — noted for future
```

## Step 4: Auto-Fix Critical Issues

For each **critical** finding, determine the fix category:

**Auto-fix** (no user approval needed):
- Remove a hardcoded credential and replace with environment variable reference
- Replace SQL string concatenation with parameterized queries
- Add HTML output escaping where raw user input is rendered

**Require user approval:**
- Anything that changes business logic or control flow
- Anything that modifies API contracts (inputs, outputs, status codes)
- Anything that could change test behavior or assertions
- Fixes where there are multiple possible fix locations
- Anything involving cryptographic code
- Adding new middleware or interceptors

When in doubt: require user approval.

**Important:** After any auto-fix, both the /review and /verify reports are stale. Re-run /review and /verify before proceeding to PR creation.

## Step 5: Create PR

### Parse Arguments

- `--canary` — mark as canary deploy in PR description
- `--draft` — create as draft PR
- `--skip-security` — skip security audit (requires explicit user confirmation before proceeding; always log the skip in the PR description)

### Generate Release Summary

Read the git log for this branch. Detect the default branch first — do not assume `main`:
```bash
# Detect the default branch
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
git log --oneline ${DEFAULT_BRANCH}..HEAD
```

Produce a human-readable summary grouped by type:

```markdown
## Summary
- [1-3 bullet points describing the change at a high level]

## Changes
### Features
- [feature descriptions from commits]

### Fixes
- [fix descriptions from commits]

### Security
- [security fixes applied by /ship]

## Verification
- Domain: [from verify report]
- Tests: [pass count from verify report]
- Security audit: [PASS with N warnings | N critical fixed]

## Test Plan
- [ ] [Key scenarios to verify in review]
```

### Create the PR

```bash
# Stage only files modified during this build cycle — never use git add -A
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
git diff --name-only ${DEFAULT_BRANCH}...HEAD | xargs git add
# Also stage any security fixes made in Step 3
git add [files modified by security fixes]
git commit -m "[summary of changes]"
git push -u origin [branch-name]

gh pr create \
  --title "[concise title under 70 chars]" \
  --body "[generated summary]" \
  [--draft if --draft flag]
```

### Generate Release Artifacts

Write a release summary:
```bash
mkdir -p .forge/releases/v[version]
```

Write to `.forge/releases/v[version]/summary.md`:
```markdown
# Release v[version]

## Date: [YYYY-MM-DD]
## PR: [URL]
## Changes
[Same grouped summary as PR description]
## Security
[Audit results summary]
## Artifacts
- Architecture doc: [path or N/A]
- Review report: [path]
- Verify report: [path]
```

## Step 6: Report

Before claiming the ship is complete, show evidence the PR was created:
```bash
gh pr view --json url,state,title
```
Output must include the PR URL. Do not claim "shipped" or "PR created" without showing the actual PR URL returned by `gh pr create` or confirmed by `gh pr view`.

```
FORGE /ship — Complete ✓

Security audit: [PASS | N critical fixed, N warnings]
PR: [URL]
[If canary]: Marked as canary deploy
[If draft]: Created as draft — mark ready when reviewed

Full cycle complete: /think → /architect → /build → /verify → /ship ✓
```

### Documentation Sync

After PR creation, check if documentation needs updating:
```
If API contracts changed, README examples may be stale, or docs/ references outdated:

FORGE /ship — Documentation may need updating.
Run /document-release to sync docs with this release.
```

## Rules

- **Blocks on /review failures** — NEEDS_CHANGES or FAIL in the review report blocks shipping, same as /verify FAIL
- **Never ship with /verify failures** — no override, no flag, no exception
- **Never commit secrets** — if a hardcoded secret is found, it's always critical
- Auto-fix only clear, unambiguous security issues — ask for approval on anything complex
- The PR description must be useful to a human reviewer, not just a git log dump
- If `--skip-security` is used, add a prominent warning to the PR description
- Re-run tests after every auto-fix — security fixes that break functionality are not fixes
- Report the PR URL so the user can review it immediately
- **Evidence before claims** — every security finding must cite the specific file, line, and pattern. Never claim "no issues" without listing what was scanned.
- **Version bump is optional** — skip if no version file detected or user declines
- **Secrets in git history are always critical** — even if removed from current code, they may be exposed
- **Suggest /document-release** after shipping if docs may be stale — don't auto-run it

### Error Handling
If any step fails unexpectedly: (1) state what failed and show the error output, (2) state what has been completed so far, (3) state what remains, (4) ask the user: retry this step, skip it, or abort. Never silently continue past a failed step. If a security fix breaks tests, always stop and ask.
