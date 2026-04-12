# FORGE Workflow Routing

## Standard Pipeline
```
/think → /brainstorm (optional) → /architect → /build → /review → /verify → /ship → /deploy
```

## Routing Table

| After this skill | Recommended next | Alternative | Condition |
|-----------------|-----------------|-------------|-----------|
| /think | /architect | /brainstorm | If task needs exploration, brainstorm first |
| /think (tiny) | /build | — | Tiny tasks skip architect |
| /brainstorm | /architect | — | — |
| /architect | /build | — | — |
| /build | /review | /review adversarial | Use adversarial for security-critical changes |
| /review | /verify | — | Only if review verdict is PASS |
| /verify | /ship | — | Only if verify verdict is PASS |
| /ship | /deploy | /retro | Deploy if ready; retro if reflecting |
| /deploy | /canary | /retro | Canary for gradual rollout |
| /canary | /retro | — | — |

## Support Skills (invoke anytime)
- `/debug` — root-cause analysis
- `/careful` — destructive operation guard
- `/freeze` — edit lock on files
- `/worktree` — isolated branch
- `/finish` — merge and cleanup
- `/memory` — decision memory bank
- `/browse` — browser-based verification
- `/design` — UI/UX workflow (standalone suite)
- `/benchmark` — performance measurement
- `/document-release` — docs sync after release
- `/retro` — retrospective
- `/evolve` — meta-learning from retros
