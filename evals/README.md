# FORGE Eval Framework

Measures FORGE routing accuracy, classification accuracy, artifact compliance, and red flag detection across 50 task scenarios.

## Task Categories

| Directory | Count | What it tests |
|-----------|-------|---------------|
| `tasks/tiny/` | 15 | Should classify as tiny, route to /build, skip /architect |
| `tasks/feature/` | 15 | Should classify as feature, route to /architect, produce architecture docs |
| `tasks/debug/` | 10 | Should route to /debug, produce debug reports |
| `tasks/ambiguous/` | 10 | Should request clarification or accept multiple valid routes |

## Running an Eval

1. Pick a task file and feed its `input` to FORGE via `/think`:

```bash
# Example
cat evals/tasks/tiny/tiny-001.json | jq -r '.input'
# Then use that text as input to /think
```

2. Record the result as a JSON line in `evals/results.jsonl`:

```jsonl
{"id":"tiny-001","actual_route":"/build","actual_classification":"tiny","actual_artifacts":[],"observed_flags":[]}
{"id":"feature-001","actual_route":"/architect","actual_classification":"feature","actual_artifacts":[".forge/architecture/projects-endpoint.md"],"observed_flags":[]}
{"id":"debug-001","actual_route":"/debug","actual_classification":"debug","actual_artifacts":[".forge/debug/report.md"],"observed_flags":["skipped reproduction"]}
```

### Result Fields

| Field | Description |
|-------|-------------|
| `id` | Must match the task file's `id` |
| `actual_route` | The skill FORGE routed to (e.g., `/build`, `/architect`, `/debug`) |
| `actual_classification` | The complexity FORGE assigned (e.g., `tiny`, `feature`, `epic`, `debug`) |
| `actual_artifacts` | File paths FORGE produced |
| `observed_flags` | Any behaviors that match the task's `red_flags` list |

## Scoring

```bash
./evals/score.sh                    # reads evals/results.jsonl
./evals/score.sh path/to/other.jsonl  # or specify a file
```

Requires `jq`. Install with `brew install jq` or `apt-get install jq`.

### Output

The scorer prints per-result misses and a summary:

```
MISS route  | tiny-003 | got: /architect | expected: /build
RED FLAG     | debug-002 | modified tests to pass

==============================
  FORGE Eval Score Summary
==============================

Results scored: 12
Route accuracy:          11 / 12 (91%)
Classification accuracy: 12 / 12 (100%)
Artifact compliance:     10 / 12 (83%)
Red flag violations:     1 across 3 observed flags

Combined routing+classification: 23 / 24 (95%)

Status: ISSUES FOUND
```

Exit code 0 means all pass. Non-zero means at least one miss or red flag violation.
