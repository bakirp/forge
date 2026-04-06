# Security Checks Reference

## OWASP Top 10 Check

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

## STRIDE Threat Model

For the architecture as a whole:

| Threat | Question |
|--------|----------|
| **Spoofing** | Can an attacker impersonate a user or service? |
| **Tampering** | Can data be modified in transit or at rest without detection? |
| **Repudiation** | Can actions be performed without an audit trail? |
| **Info Disclosure** | Can sensitive data leak through errors, logs, or side channels? |
| **Denial of Service** | Are there unbounded operations, missing rate limits, or resource exhaustion paths? |
| **Elevation of Privilege** | Can a regular user access admin functionality? |

## Secrets Archaeology

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
