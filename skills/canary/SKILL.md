---
name: canary
description: "Canary deployment workflow. Deploys to a subset of infrastructure, monitors for errors, and either promotes to full rollout or rolls back. Use after /ship for gradual releases."
argument-hint: "[optional: percentage or target environment]"
allowed-tools: Read Grep Glob Write Bash
---

# /canary — Canary Deployment Workflow

You deploy changes to a small subset of infrastructure, monitor for errors, and either promote to full rollout or roll back. You ensure risky changes reach production gradually and safely.

## Step 1: Check Prerequisites

Verify deployment configuration exists. Scan for:

- Kubernetes manifests (`k8s/`, `deploy/`, `*.yaml` with `kind: Deployment`)
- Docker Compose (`docker-compose.yml`, `compose.yml`)
- Cloud config (Vercel `vercel.json`, Fly `fly.toml`, Railway `railway.json`, AWS `samconfig.toml`)
- Custom deploy scripts (`deploy.sh`, `scripts/deploy*`)
- CI/CD config (`.github/workflows/deploy*`, `.gitlab-ci.yml`)

```bash
# Detect deployment infrastructure
ls -la k8s/ deploy/ 2>/dev/null
ls fly.toml vercel.json railway.json docker-compose.yml compose.yml 2>/dev/null
ls deploy.sh scripts/deploy* 2>/dev/null
```

If none found:
```
FORGE /canary — No deployment config detected

Could not find deployment configuration.
Please provide your deployment method:
- Kubernetes namespace/context
- Cloud platform CLI command
- Custom deploy script path
```

## Step 2: Plan Canary

Parse `$ARGUMENTS` for percentage (default: 10%) and environment.

Detect the current version from the latest `/ship` output, git tag, or package version.

```
FORGE /canary — Plan

Version: [version from /ship or git tag]
Target: [percentage]% of traffic
Duration: [monitoring period, default 15 minutes]
Rollback trigger: error rate > 1% or latency > 2x baseline
Infrastructure: [detected method]

Proceed? (y/n, or adjust parameters)
```

Wait for user confirmation before deploying anything.

## Step 3: Deploy Canary

Execute deployment to canary target. Method depends on detected infrastructure:

### Kubernetes
```bash
# Apply canary deployment with reduced replicas
kubectl apply -f [canary-manifest]
# Or scale canary to target percentage
kubectl scale deployment [name]-canary --replicas=[canary-count]
```

### Cloud Functions / Serverless
```bash
# Deploy to a canary alias or preview environment
# Vercel
vercel deploy --target preview
# Fly.io
fly deploy --strategy canary
# AWS Lambda
aws lambda update-alias --function-name [name] --routing-config AdditionalVersionWeights={[version]=[weight]}
```

### Static / CDN
```bash
# Deploy to preview URL for manual traffic splitting
vercel deploy  # produces a preview URL
# Or use edge config for percentage-based routing
```

### Custom
```bash
# Run user-defined canary deploy script
./deploy.sh canary [percentage]
```

Report deployment status:
```
FORGE /canary — Deployed

Canary deployed successfully.
Version: [version]
Target: [percentage]% of traffic
Endpoint: [canary URL if available]

Monitoring for [duration]...
```

## Step 4: Monitor

Watch for errors during the canary period. Check all available signals:

### Error Rate
```bash
# Check application logs for errors
# Kubernetes
kubectl logs -l app=[name],track=canary --tail=100 --since=5m
# Cloud platforms
fly logs --app [name] | tail -50
vercel logs [deployment-url] --since 5m
```

### Latency
Compare canary response times against the stable deployment:
```bash
# Quick latency check
curl -s -o /dev/null -w "%{time_total}" [canary-url]/health
curl -s -o /dev/null -w "%{time_total}" [stable-url]/health
```

### Health Checks
```bash
# Verify health endpoint responds
curl -sf [canary-url]/health
# Check HTTP status
curl -s -o /dev/null -w "%{http_code}" [canary-url]/health
```

Collect metrics over the monitoring period. If any rollback trigger fires during monitoring, immediately recommend rollback.

## Step 5: Decision

Present monitoring results and recommendation:

```
FORGE /canary — Monitoring complete

Duration: [time monitored]
Error rate: [X]% (threshold: 1%)
Latency: [Xms] (baseline: [Yms], threshold: 2x)
Health checks: [passing/failing]
Log errors: [count of error-level log lines]

[If all healthy]:
  Recommendation: PROMOTE to full rollout
  All metrics within acceptable thresholds.

[If unhealthy]:
  Recommendation: ROLLBACK immediately
  Trigger: [which metric breached threshold]
  Details: [specific errors or latency spikes observed]

Action: Promote / Rollback / Extend monitoring [additional minutes]?
```

Wait for user decision. Never auto-promote.

## Step 6: Execute Decision

### Promote
```bash
# Kubernetes: scale canary to full, scale down old
kubectl scale deployment [name]-canary --replicas=[full-count]
kubectl scale deployment [name]-stable --replicas=0
# Or swap labels/selectors

# Cloud: promote preview to production
vercel promote [deployment-url]
fly deploy  # full deploy
```

Report:
```
FORGE /canary — Promoted

Version [version] promoted to 100% of traffic.
Previous version retired.

Deployment complete.
```

### Rollback
```bash
# Kubernetes: remove canary
kubectl delete deployment [name]-canary
# Or scale to 0
kubectl scale deployment [name]-canary --replicas=0

# Cloud: revert to previous deployment
vercel rollback
fly releases rollback
```

Report:
```
FORGE /canary — Rolled back

Canary deployment rolled back.
Stable version restored to 100% of traffic.
Reason: [trigger that caused rollback]

Investigate the issue before retrying.
```

### Extend Monitoring
Continue monitoring for the additional period, then return to Step 5.

## Rules

- Never auto-promote — always require user confirmation
- Rollback must be possible at any point during canary
- If health checks fail, recommend rollback immediately
- Canary percentage defaults to 10% unless specified
- Always show monitoring results before asking for a decision
- Never deploy to production without the user seeing the canary plan first
- If the deployment method cannot support traffic splitting, fall back to a blue-green approach and explain the tradeoff
- Keep all canary logs and metrics for post-deployment analysis
- If monitoring tools are not available, use basic HTTP health checks as a minimum
