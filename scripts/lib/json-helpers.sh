#!/usr/bin/env bash
# Shared JSON helpers for FORGE scripts (jq preferred, python3 fallback)

HAS_JQ=false; command -v jq &>/dev/null && HAS_JQ=true

now_iso() { date -u +"%Y-%m-%dT%H:%M:%SZ"; }

# jq_read <file> [jq-args...] — read a value from a JSON file
jq_read() {
  local f="$1"; shift
  jq -r "$@" "$f"
}

# jq_write <file> [--arg k v ...] <expr> — modify JSON file in place
jq_write() {
  local f="$1"; shift
  local tmp; tmp=$(jq "$@" "$f") && printf '%s\n' "$tmp" > "$f"
}

# py_read <file> <python-print-expr> — read a value using python3
# NOTE: The expression arg is interpolated into python code. Only pass trusted,
# internally-constructed expressions — never raw user input.
py_read() {
  python3 -c "
import json, sys
with open(sys.argv[1]) as f: d=json.load(f)
print($2)
" "$1"
}

# py_write <file> <python-statements> — modify JSON file using python3
# NOTE: The statements arg is interpolated into python code. Only pass trusted,
# internally-constructed statements — never raw user input.
py_write() {
  python3 -c "
import json, sys
with open(sys.argv[1]) as f: d=json.load(f)
$2
with open(sys.argv[1],'w') as f: json.dump(d,f,indent=2)
" "$1"
}

# json_create <json-string> <output-file> — create a JSON file from a string
json_create() {
  if $HAS_JQ; then printf '%s\n' "$1" | jq . > "$2"
  else python3 -c "import json,sys; json.dump(json.loads(sys.argv[1]),open(sys.argv[2],'w'),indent=2)" "$1" "$2"; fi
}

# json_print <file> — pretty-print a JSON file
json_print() {
  if $HAS_JQ; then jq . "$1"
  else python3 -c "import json,sys; print(json.dumps(json.load(open(sys.argv[1])),indent=2))" "$1"; fi
}

# read_forge_config <root> <field> — read a field from .forge/config.json
read_forge_config() {
  local root="$1" field="$2"
  [[ -f "$root/.forge/config.json" ]] || return 1
  if $HAS_JQ; then
    jq -r ".${field} // empty" "$root/.forge/config.json" 2>/dev/null
  else
    python3 -c "
import json, sys
d=json.load(open(sys.argv[1]))
v=d.get(sys.argv[2],'')
print(v if v else '')" "$root/.forge/config.json" "$field" 2>/dev/null || true
  fi
}

# get_package_deps <root> — print all dependency names from package.json
get_package_deps() {
  local root="$1"
  [[ -f "$root/package.json" ]] || return 1
  if $HAS_JQ; then
    jq -r '(.dependencies // {}) + (.devDependencies // {}) | keys[]' "$root/package.json" 2>/dev/null || true
  else
    python3 -c "
import json, sys
d=json.load(open(sys.argv[1]))
m=dict(d.get('dependencies',{})); m.update(d.get('devDependencies',{}))
for k in m: print(k)" "$root/package.json" 2>/dev/null || true
  fi
}
