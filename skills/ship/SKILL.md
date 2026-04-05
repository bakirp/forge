---
name: ship
description: "Security audit + PR creation + deploy. Reads /verify report (blocks on failure), runs OWASP Top 10 and STRIDE threat model checks, auto-fixes critical security issues, creates a PR with release summary, and optionally supports canary deploys."
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

If **Status: PASS**, proceed.

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

### OWASP Top 10 Check

For each changed file, check for:

| # | Vulnerability | What to look for |
|---|--------------|-----------------|
| 1 | **Injection** | String concatenation in SQL/shell/OS commands, unsanitized user input in queries |
| 2 | **Broken Auth** | Hardcoded credentials, missing auth checks on routes, weak token generation |
| 3 | **Sensitive Data Exposure** | Secrets in code, unencrypted PII, verbose error messages leaking internals |
| 4 | **XXE** | XML parsing without disabling external entities |
| 5 | **Broken Access Control** | Missing authorization checks, IDOR patterns, privilege escalation paths |
| 6 | **Security Misconfiguration** | Debug mode in prod, default credentials, unnecessary features enabled |
| 7 | **XSS** | Unescaped user input in HTML/templates, `dangerouslySetInnerHTML`, `innerHTML` |
| 8 | **Insecure Deserialization** | `eval()`, `pickle.loads()`, `JSON.parse` on untrusted input without validation |
| 9 | **Known Vulnerabilities** | Outdated dependencies with known CVEs |
| 10 | **Insufficient Logging** | Auth events not logged, no audit trail for sensitive operations |

### STRIDE Threat Model

For the architecture as a whole:

| Threat | Question |
|--------|----------|
| **Spoofing** | Can an attacker impersonate a user or service? |
| **Tampering** | Can data be modified in transit or at rest without detection? |
| **Repudiation** | Can actions be performed without an audit trail? |
| **Info Disclosure** | Can sensitive data leak through errors, logs, or side channels? |
| **Denial of Service** | Are there unbounded operations, missing rate limits, or resource exhaustion paths? |
| **Elevation of Privilege** | Can a regular user access admin functionality? |

### Secrets Archaeology

Scan git history for accidentally committed credentials:
```bash
# Check recent commits for secret patterns
git log -p --diff-filter=A HEAD~20..HEAD 2>/dev/null | grep -iE '(password|secret|api_key|api.key|token|private.key|credentials)\s*[:=]' | head -20
```

If secrets are found in git history:
```
FORGE /ship — CRITICAL: Secrets found in git history

The following patterns were found in recent commits:
- [file:commit] [matched pattern]

These are in the git history even if removed from current code.
Recommendation: Rotate the exposed credentials immediately.

Consider using git-filter-repo or BFG to clean history (destructive — requires force push).
```

Flag secrets in history as CRITICAL — they may already be exposed.

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

For each **critical** finding:
- If it's a clear fix (remove hardcoded secret, add input sanitization, escape output), fix it automatically
- Run the tests again after each fix to ensure nothing breaks
- If the fix is ambiguous or risky, present it to the user:

```
FORGE /ship — Critical fix requires approval

Issue: [description]
File: [path:line]
Proposed fix: [description]

Apply? (y/n)
```

After all critical fixes:
```bash
# Re-run tests to confirm fixes don't break anything
[project test command]
```

If tests fail after security fixes, stop and ask the user.

**Important:** If any code was modified in this step, the existing `/verify` report is now stale. Re-run `/verify` before proceeding to Step 5. The verification report must reflect the code that is actually being shipped.

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
git diff --name-only main...HEAD | xargs git add
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
