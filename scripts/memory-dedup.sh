#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/memory-dedup.sh [--dry-run]
# Finds duplicate memory entries (same project + category + similar decision text)
# With --dry-run: shows duplicates without removing
# Without: removes duplicates, keeping the most recent entry

DRY_RUN=false
if [ "${1:-}" = "--dry-run" ]; then
    DRY_RUN=true
fi

MEMORY="$HOME/.forge/memory.jsonl"

if [ ! -f "$MEMORY" ] || [ ! -s "$MEMORY" ]; then
    echo "No memory entries found at $MEMORY"
    exit 0
fi

TOTAL=$(wc -l < "$MEMORY" | tr -d ' ')

python3 -c "
import json, sys, os

dry_run = sys.argv[1] == 'true'
memory_path = sys.argv[2]

entries = []
with open(memory_path) as f:
    for i, line in enumerate(f):
        line = line.strip()
        if not line: continue
        try:
            e = json.loads(line)
            e['_line'] = i
            e['_raw'] = line
            entries.append(e)
        except:
            entries.append({'_line': i, '_raw': line, '_bad': True})

def dedup_key(e):
    if e.get('_bad'): return None
    proj = e.get('project', '').lower().strip()
    cat = e.get('category', '').lower().strip()
    dec = ' '.join(e.get('decision', '').lower().split()[:8])
    return f'{proj}|{cat}|{dec}'

seen = {}
keep = []
dupes = 0
for e in entries:
    k = dedup_key(e)
    if k is None:
        keep.append(e)
        continue
    if k in seen:
        old = seen[k]
        old_date = old.get('date', '')
        new_date = e.get('date', '')
        if new_date >= old_date:
            keep = [x for x in keep if x.get('_line') != old['_line']]
            keep.append(e)
            seen[k] = e
        dupes += 1
        if dry_run:
            print(f'  DUP: {e.get(\"project\",\"?\")} / {e.get(\"category\",\"?\")} — {e.get(\"decision\",\"?\")[:60]}')
    else:
        seen[k] = e
        keep.append(e)

print(f'Total entries: {len(entries)}  |  Duplicates: {dupes}  |  Kept: {len(keep)}')
if not dry_run and dupes > 0:
    tmp_path = memory_path + '.tmp'
    with open(tmp_path, 'w') as f:
        for e in keep:
            f.write(e['_raw'] + '\n')
    os.rename(tmp_path, memory_path)
    print('Deduplication complete.')
elif dry_run and dupes > 0:
    print('(dry run — no changes made)')
elif dupes == 0:
    print('No duplicates found.')
" "$DRY_RUN" "$MEMORY"
