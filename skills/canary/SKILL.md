---
name: canary
description: "Canary deployment workflow. Deploys to a subset of infrastructure, monitors for errors, and either promotes to full rollout or rolls back. Use after /ship for gradual releases. Use for gradual rollouts — triggered by 'canary deploy', 'gradual rollout', 'deploy to a subset', 'test in production'."
argument-hint: "[optional: percentage or target environment]"
allowed-tools: Read Grep Glob Write Bash
---

# /canary — Canary Deployment Workflow

**Rollback immediately on any threshold breach** (error rate > 1%, latency > 2x baseline, or health check failure). **Never auto-promote** — always require explicit user confirmation before promoting.

> **Shared protocols apply** — see `skills/shared/rules.md`, `skills/shared/compliance-telemetry.md`, `skills/shared/workflow-routing.md`. Log violations via `scripts/compliance-log.sh`.

## Step 1: Check Prerequisites

Read the latest `.forge/releases/*/summary.md` for version, security audit status, and PR URL. Scan for deployment config: K8s manifests (`k8s/`, `deploy/`), Docker Compose, cloud config (`vercel.json`, `fly.toml`, `railway.json`), deploy scripts (`deploy.sh`, `scripts/deploy*`), and CI/CD workflows. If none found, ask the user for their deployment method.

## Step 2: Plan Canary

Parse `$ARGUMENTS` for percentage (default: 10%) and environment. Detect current version from `/ship` output, git tag, or package version. Present plan and **wait for user confirmation**:

```
FORGE /canary — Plan

Version: [version]
Target: [percentage]% of traffic
Duration: [monitoring period, default 15 minutes]
Rollback trigger: error rate > 1% or latency > 2x baseline
Infrastructure: [detected method]

Proceed? (y/n, or adjust parameters)
```

## Step 3: Deploy Canary

Execute deployment based on detected infrastructure:

| Platform | Command |
|----------|---------|
| Kubernetes | `kubectl apply -f [canary-manifest]` or `kubectl scale deployment [name]-canary --replicas=[N]` |
| Vercel | `vercel deploy --target preview` |
| Fly.io | `fly deploy --strategy canary` |
| AWS Lambda | `aws lambda update-alias --routing-config AdditionalVersionWeights={[ver]=[weight]}` |
| Custom | `./deploy.sh canary [percentage]` |

Report version, target percentage, canary endpoint URL, and monitoring duration.

## Step 4: Monitor

Watch three signals during the canary period. If any threshold breaches, immediately recommend rollback.

- **Error Rate** — Check application logs (`kubectl logs`, `fly logs`, `vercel logs`) for elevated errors.
- **Latency** — Compare canary vs stable: `curl -s -o /dev/null -w "%{time_total}" [canary-url]/health`
- **Health Checks** — Verify canary endpoint returns 200.

If platform CLI tools are unavailable, fall back to polling the health endpoint with `curl` every 30 seconds.

## Step 5: Decision

Present monitoring results and **wait for user decision** (never auto-promote):

```
FORGE /canary — Monitoring complete

Duration: [time]  |  Error rate: [X]% (threshold: 1%)
Latency: [Xms] (baseline: [Yms], threshold: 2x)
Health checks: [passing/failing]  |  Log errors: [count]

Recommendation: PROMOTE / ROLLBACK
[If rollback: which metric breached + details]

Action: Promote / Rollback / Extend monitoring [minutes]?
```

## Step 6: Execute Decision

- **Promote** — Scale canary to full traffic, retire previous version, report completion.
- **Rollback** — Remove/scale-down canary, restore stable to 100%, report reason.
- **Extend** — Continue monitoring for additional period, return to Step 5.

## Compliance and Rules

| rule_key | severity | trigger |
|----------|----------|---------|
| `auto-promoted` | critical | Canary promoted without user confirmation |
| `unhealthy-no-rollback` | critical | Health checks failed but rollback not recommended |
| `monitoring-not-shown` | major | Promotion decided without showing monitoring results |

Never deploy without the user seeing the canary plan first. If traffic splitting is unsupported, fall back to blue-green and explain the tradeoff. Keep all canary logs/metrics for post-deployment analysis.
