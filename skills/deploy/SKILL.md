---
name: deploy
description: "Post-merge deploy and land flow. Handles post-merge deployment: pull latest merged code, run final checks, deploy to target environment, verify deployment health, and update status. Use AFTER the PR is merged — triggered by 'deploy this', 'push to production', 'deploy to staging', 'land this', 'go live', 'after merge'."
argument-hint: "[optional: environment name, e.g. staging|production]"
allowed-tools: Read Grep Glob Write Bash
---

# /deploy — Deploy and Land Flow

Production deploys require the user to type "yes" (not just "y") before execution. Pull latest merged code, run final safety checks, deploy, verify health, and report status.

> **Shared protocols apply.** See `skills/shared/rules.md` for evidence-before-claims, no-secrets, scope discipline, and artifact integrity rules.

## Step 1: Check PR Status

Read `.forge/releases/*/summary.md` (if present) for PR URL, version, and security audit status. Verify the PR is merged and check recent history:
```bash
ls .forge/releases/*/summary.md 2>/dev/null | tail -1
gh pr list --state merged --limit 5 && git status && git log --oneline -5
```
If no merged PR is found, warn the user and **wait for confirmation** before continuing.

## Step 2: Pull and Verify

Sync with latest merged code (`git checkout $DEFAULT_BRANCH && git pull origin $DEFAULT_BRANCH`). Run the full test suite (detect runner: `npm test`, `go test ./...`, `pytest`, `cargo test`).

If tests fail — **STOP. Do not deploy.** Report failing tests and block until fixed.

## Step 3: Detect Environment

From `$ARGUMENTS` or auto-detect by scanning for deploy configs:
```bash
ls -la deploy.sh scripts/deploy* Makefile vercel.json fly.toml railway.json netlify.toml 2>/dev/null
ls -la Dockerfile docker-compose.yml compose.yml .github/workflows/deploy* 2>/dev/null
grep -A2 '"deploy"' package.json 2>/dev/null
```

Present detection and gate on confirmation:
```
FORGE /deploy — Environment detected
Target: [name] | Method: [method] | Config: [path]
[production]: WARNING — PRODUCTION deploy. Confirm? (type "yes" fully)
[staging]: Deploy to staging? (y/n)
```
For production, require full "yes" — this is a **blocking gate**.

## Step 4: Deploy

| Platform | Command |
|----------|---------|
| npm / Node.js | `npm run deploy` / `npm run deploy:[env]` |
| Docker | `docker build -t [img]:[ver] . && docker push [img]:[ver] && docker compose up -d` |
| Vercel | `vercel deploy --prod` (production) / `vercel deploy` (staging) |
| Fly.io | `fly deploy` |
| Railway | `railway up` |
| Netlify | `netlify deploy --prod` |
| AWS SAM/CDK | `sam deploy` / `cdk deploy` |
| Custom script | `./deploy.sh [env]` / `make deploy ENV=[env]` |

If deployment fails, present the error and **do not retry automatically** — let the user diagnose first. Suggest common causes: auth expired, resource limits, config mismatch.

## Step 5: Verify Deployment

After successful deployment, verify health:
```bash
curl -sf [deployed-url]/health
curl -s -o /dev/null -w "%{http_code}" [deployed-url]/
DEPLOYED=$(curl -s [deployed-url]/version); EXPECTED=$(git rev-parse --short HEAD)
echo "Deployed: $DEPLOYED | Expected: $EXPECTED"
```
Check platform logs for errors (`vercel logs`, `fly logs`, `docker compose logs --tail=50`). If health checks fail or version mismatches, flag immediately and suggest rollback.

## Step 6: Report

```
FORGE /deploy — Complete
Environment: [name] | Version: [SHA or tag] | URL: [deployed URL]
Health: [healthy/unhealthy] | Method: [deploy method] | Tests: passed
```

Write deployment record to `.forge/deploy/last-deploy.json` with fields: `timestamp`, `environment`, `version`, `url`, `health`, `method`. If canary is recommended, suggest `/canary`. If API/user-facing changes detected, suggest `/document-release`.

## Rules, Routing & Compliance

- Production deploys always require explicit "yes" confirmation — **blocking gate**.
- Run tests after pull; do not retry failed deploys automatically; always verify health post-deploy.
- If no deployment method is detected, ask the user rather than guessing.
- Record every deployment in `.forge/deploy/last-deploy.json` for audit trail.
- **Routing**: After `/deploy` -> `/canary` (gradual rollout) or `/retro` (reflect). See `skills/shared/workflow-routing.md`.
- **Compliance**: See `skills/shared/compliance-telemetry.md`. Log violations via `scripts/compliance-log.sh` per shared protocol. Violation keys: `no-confirmation` (critical), `tests-not-run-after-pull` (major), `auto-retry` (major), `health-check-skipped` (major).
