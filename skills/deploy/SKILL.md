---
name: deploy
description: "Deploy and land flow. Handles post-merge deployment: pull latest, run final checks, deploy to target environment, verify deployment health, and update status. Use after merge — triggered by 'deploy this', 'push to production', 'deploy to staging', 'land this', 'go live'."
argument-hint: "[optional: environment name, e.g. staging|production]"
allowed-tools: Read Grep Glob Write Bash
---

# /deploy — Deploy and Land Flow

You handle post-merge deployment. You pull the latest merged code, run a final safety check, deploy to the target environment, verify health, and report status. You are the last step before code is live.

## Step 1: Check PR Status

Check for a release summary from `/ship`:
```bash
ls .forge/releases/*/summary.md 2>/dev/null | tail -1
```
If found, read it for the PR URL, version, and security audit status. Use the PR URL to verify the correct PR was merged.

Verify the PR from `/ship` has been merged:

```bash
# Check recently merged PRs
gh pr list --state merged --limit 5
```

Also check the current branch state:
```bash
git status
git log --oneline -5
```

If the PR is not merged yet:
```
FORGE /deploy — Warning

No recently merged PR found.
The PR from /ship may still be awaiting review or approval.

Proceed with deployment anyway? (y/n)
```

Wait for user confirmation before continuing.

## Step 2: Pull and Verify

Sync with the latest merged code:

```bash
# Detect default branch
DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@')
[ -z "$DEFAULT_BRANCH" ] && DEFAULT_BRANCH="main"

git checkout $DEFAULT_BRANCH
git pull origin $DEFAULT_BRANCH
```

Run the full test suite on the merged code as a final safety check:

```bash
# Detect and run test suite
# Node.js
npm test
# Go
go test ./...
# Python
pytest
# Rust
cargo test
```

If tests fail:
```
FORGE /deploy — Blocked

Tests are failing on the merged code.
This may indicate a merge conflict or a broken integration.

Failing tests:
- [test 1]
- [test 2]

Fix the failures before deploying. Do not deploy broken code.
```

Stop here if tests fail. Do not proceed to deployment.

## Step 3: Detect Environment

From `$ARGUMENTS` or auto-detect the target environment:

### Explicit
- `staging` — deploy to staging environment
- `production` — deploy to production (requires explicit confirmation)
- Custom name — look for matching config

### Auto-detect
Scan for deployment configuration:

```bash
# Check for deploy scripts and configs
ls -la deploy.sh scripts/deploy* Makefile 2>/dev/null
ls -la vercel.json fly.toml railway.json netlify.toml 2>/dev/null
ls -la Dockerfile docker-compose.yml compose.yml 2>/dev/null
ls -la .github/workflows/deploy* 2>/dev/null

# Check package.json for deploy scripts
grep -A2 '"deploy"' package.json 2>/dev/null
```

Present detection:
```
FORGE /deploy — Environment detected

Target: [environment name]
Method: [deployment method]
Config: [config file path]

[If production]:
  WARNING: This will deploy to PRODUCTION.
  Confirm deployment? (yes/no — type "yes" fully to confirm)

[If staging]:
  Deploy to staging? (y/n)
```

For production deploys, require the user to type "yes" (not just "y").

## Step 4: Deploy

Execute deployment based on the detected method:

### npm / Node.js
```bash
# Use the project's deploy script
npm run deploy
# or
npm run deploy:staging
npm run deploy:production
```

### Docker
```bash
# Build and tag
docker build -t [image-name]:[version] .
# Push to registry
docker push [image-name]:[version]
# Update deployment
docker compose up -d
```

### Cloud Platforms
```bash
# Vercel
vercel deploy --prod  # production
vercel deploy         # preview/staging

# Fly.io
fly deploy

# Railway
railway up

# Netlify
netlify deploy --prod

# AWS (SAM/CDK)
sam deploy
# or
cdk deploy
```

### Custom Script
```bash
# Run the project's deploy script
./deploy.sh [environment]
# or
make deploy ENV=[environment]
```

Capture deployment output for the report. If deployment fails:
```
FORGE /deploy — Failed

Deployment failed.
Error: [error output from deploy command]

Do not retry automatically — diagnose the failure first.
Common causes:
- Authentication expired (re-login to cloud CLI)
- Resource limits exceeded
- Configuration mismatch between environments
```

Do not retry automatically. Present the error and let the user decide.

## Step 5: Verify Deployment

After successful deployment, verify the deployed version is healthy:

### Health Check
```bash
# Hit health endpoint
curl -sf [deployed-url]/health
curl -s -o /dev/null -w "%{http_code}" [deployed-url]/

# Check for expected version
curl -s [deployed-url]/version
curl -s [deployed-url]/api/health
```

### Deployment Logs
```bash
# Check for errors in deployment logs
# Vercel
vercel logs [deployment-url] --since 2m
# Fly.io
fly logs --app [name]
# Docker
docker compose logs --tail=50
```

### Version Verification
Confirm the deployed version matches what was merged:
```bash
# Compare deployed version against local
DEPLOYED_VERSION=$(curl -s [deployed-url]/version)
LOCAL_VERSION=$(git rev-parse --short HEAD)
echo "Deployed: $DEPLOYED_VERSION | Expected: $LOCAL_VERSION"
```

If health checks fail:
```
FORGE /deploy — Health check failed

Deployment completed but health checks are failing.
URL: [deployed-url]
Status: [HTTP status or error]

This may indicate:
- Application startup failure
- Missing environment variables
- Database connection issues

Check deployment logs for details.
Consider rolling back if the issue persists.
```

## Step 6: Report

```
FORGE /deploy — Complete

Environment: [name]
Version: [git SHA or version tag]
URL: [deployed URL if available]
Health: [healthy / unhealthy]
Deploy method: [what was used]
Tests: passed before deploy

[If healthy]:
  Deployment successful and verified.

[If canary recommended]:
  For production traffic, consider /canary for gradual rollout.

[If doc-sync needed]:
  API or user-facing changes detected.
  Run /document-release to sync documentation.
```

Write a deployment record to `.forge/deploy/last-deploy.json`:

Create `.forge/deploy/` if it doesn't exist.

```json
{
  "timestamp": "[ISO timestamp]",
  "environment": "[name]",
  "version": "[git SHA]",
  "url": "[deployed URL]",
  "health": "[healthy/unhealthy]",
  "method": "[deploy method]"
}
```

## Rules

- Production deploys always require explicit user confirmation
- Run tests after pull — merged code might have conflicts from other PRs
- If deployment fails, do not retry automatically — diagnose first
- Always verify deployment health after deploying
- Keep deployment logs for debugging
- Never deploy if the test suite is failing
- If no deployment method is detected, ask the user rather than guessing
- Record every deployment in `.forge/deploy/last-deploy.json` for audit trail
- If the deployed version does not match expected, flag it immediately
- Suggest `/canary` for production deployments when the project supports it
