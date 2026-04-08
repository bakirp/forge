#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/memory-rank.sh "search terms" [project-name] [limit]
# Reads ~/.forge/memory.jsonl, scores entries, outputs top N ranked results.
#
# Scoring:
#   +3  project name matches
#   +2  tag overlap with search terms
#   +1  decision/rationale contains search term
#   +1  higher confidence (>= 0.8)
#   -1  older than 6 months

QUERY="${1:-}"
PROJECT="${2:-}"
LIMIT="${3:-5}"
MEMORY="$HOME/.forge/memory.jsonl"

if [ -z "$QUERY" ]; then
    echo "Usage: memory-rank.sh \"search terms\" [project-name] [limit]" >&2
    exit 1
fi

if [ ! -f "$MEMORY" ] || [ ! -s "$MEMORY" ]; then
    echo "No memory entries found at $MEMORY"
    exit 0
fi

SIX_MONTHS_AGO=$(date -v-6m +%s 2>/dev/null || date -d "6 months ago" +%s 2>/dev/null || echo "0")

if command -v jq &>/dev/null; then
    jq -r --arg q "$QUERY" --arg p "$PROJECT" --argjson cutoff "$SIX_MONTHS_AGO" --argjson lim "$LIMIT" '
        def score:
            . as $entry |
            ($q | ascii_downcase | split(" ")) as $terms |
            0
            + (if ($p != "" and (($entry.project // "") | ascii_downcase) == ($p | ascii_downcase)) then 3 else 0 end)
            + ([$terms[] | select(. as $t | ($entry.tags // [] | map(ascii_downcase))[] | contains($t))] | length * 2)
            + ([$terms[] | select(. as $t | (($entry.decision // "") + " " + ($entry.rationale // "")) | ascii_downcase | contains($t))] | length)
            + (if (($entry.confidence // 0) >= 0.8) then 1 else 0 end)
            + (if (($entry.date // "") != "" and (($entry.date | strptime("%Y-%m-%d") | mktime) < $cutoff)) then -1 else 0 end);
        [., score]
    ' "$MEMORY" 2>/dev/null | jq -s 'sort_by(-(.[1])) | .[:'"$LIMIT"'][] | .[0]' 2>/dev/null | jq -r '
        "[\(.score // "?")] \(.project // "?") / \(.category // "?")\n  Decision:  \(.decision // "n/a")\n  Rationale: \(.rationale // "n/a")\n  Tags:      \((.tags // []) | join(", "))\n"
    ' 2>/dev/null
else
    python3 -c "
import json, sys, time
from datetime import datetime, timedelta

query = sys.argv[1].lower().split()
project = sys.argv[2].lower()
limit = int(sys.argv[3])
memory_path = sys.argv[4]
cutoff = time.time() - 180 * 86400

results = []
with open(memory_path) as f:
    for line in f:
        line = line.strip()
        if not line: continue
        try:
            e = json.loads(line)
        except: continue
        score = 0
        if project and (e.get('project','').lower() == project): score += 3
        tags = [t.lower() for t in e.get('tags', [])]
        score += sum(2 for t in query if any(t in tag for tag in tags))
        text = (e.get('decision','') + ' ' + e.get('rationale','')).lower()
        score += sum(1 for t in query if t in text)
        if e.get('confidence', 0) >= 0.8: score += 1
        ds = e.get('date','')
        if ds:
            try:
                d = datetime.fromisoformat(ds)
                if d.timestamp() < cutoff: score -= 1
            except: pass
        results.append((score, e))
results.sort(key=lambda x: -x[0])
for score, e in results[:limit]:
    print(f'[{score}] {e.get(\"project\",\"?\")} / {e.get(\"category\",\"?\")}')
    print(f'  Decision:  {e.get(\"decision\",\"n/a\")}')
    print(f'  Rationale: {e.get(\"rationale\",\"n/a\")}')
    print(f'  Tags:      {\", \".join(e.get(\"tags\",[]))}')
    print()
" "$QUERY" "$PROJECT" "$LIMIT" "$MEMORY" 2>/dev/null
fi
