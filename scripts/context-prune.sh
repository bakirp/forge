#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[0;33m'; NC='\033[0m'

# --- extract: pull named sections from an architecture doc ---
# Usage: context-prune.sh extract <arch-doc> <output-file> <section1> [section2 ...]
#
# Sections are matched case-insensitively as substrings of ## or ### headers.
# Supports :: notation for subsection filtering:
#   "API Contracts"           → extracts entire ## API Contracts section
#   "API Contracts::createTask" → extracts only ### createTask within ## API Contracts
#   "Edge Cases::1,3"        → extracts ## Edge Cases, then filters to lines starting with 1. or 3.
# Code blocks (triple backtick) are treated as opaque — headers inside them are ignored.
cmd_extract() {
  local arch_doc="${1:?Usage: context-prune.sh extract <arch-doc> <output-file> <section1> [section2 ...]}"
  local output_file="${2:?output file required}"
  shift 2

  if [[ ! -f "$arch_doc" ]]; then
    echo -e "${RED}ERROR${NC} architecture doc not found: $arch_doc" >&2
    exit 1
  fi

  if [[ $# -eq 0 ]]; then
    echo -e "${RED}ERROR${NC} at least one section identifier required" >&2
    exit 1
  fi

  # Parse queries: split on :: into section_part and optional subsection_part
  local -a section_queries=()
  local -a subsection_filters=()
  local -a raw_queries=()
  local q section_part sub_part
  for q in "$@"; do
    raw_queries+=("$q")
    if [[ "$q" == *"::"* ]]; then
      section_part="$(echo "${q%%::*}" | tr '[:upper:]' '[:lower:]')"
      sub_part="$(echo "${q#*::}" | tr '[:upper:]' '[:lower:]')"
    else
      section_part="$(echo "$q" | tr '[:upper:]' '[:lower:]')"
      sub_part=""
    fi
    section_queries+=("$section_part")
    subsection_filters+=("$sub_part")
  done

  mkdir -p "$(dirname "$output_file")"

  # Track which queries matched during the scan (0=unmatched, 1=matched)
  local -a query_matched=()
  for i in "${!section_queries[@]}"; do
    query_matched+=("0")
  done

  # State machine: scan the doc, extract matching sections
  local in_code_block=false
  local capturing=false
  local capture_depth=0
  local found_any=false
  local content=""
  local active_sub_filter=""
  local line lower_line hashes header_text depth matched_idx

  while IFS= read -r line || [[ -n "$line" ]]; do
    # Track code block boundaries (triple backtick)
    if [[ "$line" =~ ^\`\`\` ]]; then
      if $in_code_block; then
        in_code_block=false
      else
        in_code_block=true
      fi
      if $capturing; then
        content+="$line"$'\n'
      fi
      continue
    fi

    # Inside a code block — pass through if capturing, otherwise skip
    if $in_code_block; then
      if $capturing; then
        content+="$line"$'\n'
      fi
      continue
    fi

    # Check for header lines (## or ###)
    if [[ "$line" =~ ^(#{2,3})[[:space:]]+(.*) ]]; then
      hashes="${BASH_REMATCH[1]}"
      header_text="${BASH_REMATCH[2]}"
      depth=${#hashes}
      lower_line="$(echo "$header_text" | tr '[:upper:]' '[:lower:]')"

      # If we're capturing and hit a header at same or higher level, stop capturing
      if $capturing && [[ $depth -le $capture_depth ]]; then
        capturing=false
        active_sub_filter=""
      fi

      # Check if this header matches any section query
      matched_idx=-1
      for i in "${!section_queries[@]}"; do
        if [[ "$lower_line" == *"${section_queries[$i]}"* ]]; then
          matched_idx=$i
          break
        fi
      done

      if [[ $matched_idx -ge 0 ]]; then
        query_matched[$matched_idx]=1
        active_sub_filter="${subsection_filters[$matched_idx]}"
        # If there's a subsection filter and this is a ## header, capture the header
        # but individual lines/subsections will be filtered below
        capturing=true
        capture_depth=$depth
        found_any=true
        if [[ -z "$active_sub_filter" ]]; then
          content+="$line"$'\n'
        else
          # Include the parent section header for context
          content+="$line"$'\n'
        fi
      elif $capturing && [[ $depth -gt $capture_depth ]]; then
        # Deeper header within a captured section
        if [[ -n "$active_sub_filter" ]]; then
          # Check if this subsection matches the filter
          if [[ "$lower_line" == *"$active_sub_filter"* ]]; then
            content+="$line"$'\n'
            # Temporarily clear filter to capture entire subsection body
            # We use a flag to track we're in a matched subsection
            capturing=true
          else
            # Non-matching subsection — skip it by not adding to content
            # But we need to track that we should skip lines until next header
            capturing=false
          fi
        else
          content+="$line"$'\n'
        fi
      fi
      continue
    fi

    # Non-header line: include if capturing
    if $capturing; then
      if [[ -n "$active_sub_filter" ]]; then
        # For numbered-list filters like "1,3,5", match lines starting with those numbers
        if [[ "$active_sub_filter" == *","* ]]; then
          local should_include=false
          IFS=',' read -ra nums <<< "$active_sub_filter"
          for num in "${nums[@]}"; do
            num="$(echo "$num" | tr -d ' ')"
            if [[ "$line" =~ ^[[:space:]]*${num}\. ]]; then
              should_include=true
              break
            fi
          done
          if $should_include; then
            content+="$line"$'\n'
          fi
        else
          content+="$line"$'\n'
        fi
      else
        content+="$line"$'\n'
      fi
    fi
  done < "$arch_doc"

  if ! $found_any; then
    echo -e "${YELLOW}WARN${NC} no matching sections found in $arch_doc — falling back to full doc" >&2
    cp "$arch_doc" "$output_file"
    return 0
  fi

  # Write extracted content
  printf '%s' "$content" > "$output_file"

  # Warn about any queries that didn't match (tracked during first pass)
  for i in "${!section_queries[@]}"; do
    if [[ "${query_matched[$i]}" == "0" ]]; then
      echo -e "${YELLOW}WARN${NC} section not found: ${raw_queries[$i]}" >&2
    fi
  done

  # Format query names for display (preserve multi-word queries)
  local display_queries=""
  for q in "${raw_queries[@]}"; do
    [[ -n "$display_queries" ]] && display_queries+=", "
    display_queries+="$q"
  done
  echo -e "${GREEN}Extracted${NC} $display_queries -> $output_file"
}

# --- conventions: detect project test runner, framework, file patterns ---
# Usage: context-prune.sh conventions [project-root]
cmd_conventions() {
  local root="${1:-.}"

  echo "## Project Conventions"

  # Test runner detection (same priority as /build Step 4a)
  local test_runner="unknown"

  if [[ -f "$root/.forge/config.json" ]]; then
    local tc=""
    if command -v jq &>/dev/null; then
      tc=$(jq -r '.test_command // empty' "$root/.forge/config.json" 2>/dev/null)
    else
      tc=$(python3 -c "import json; d=json.load(open('$root/.forge/config.json')); print(d.get('test_command',''))" 2>/dev/null || true)
    fi
    [[ -n "$tc" ]] && test_runner="$tc"
  fi

  if [[ "$test_runner" == "unknown" ]]; then
    if [[ -f "$root/package.json" ]]; then
      local test_cmd=""
      if command -v jq &>/dev/null; then
        test_cmd=$(jq -r '.scripts.test // empty' "$root/package.json" 2>/dev/null)
      else
        test_cmd=$(python3 -c "import json; d=json.load(open('$root/package.json')); print(d.get('scripts',{}).get('test',''))" 2>/dev/null || true)
      fi
      if [[ -n "$test_cmd" ]]; then
        test_runner="$test_cmd"
      elif [[ -f "$root/bun.lockb" ]]; then
        test_runner="bun test"
      elif ls "$root"/vitest.config.* &>/dev/null 2>&1; then
        test_runner="npx vitest run"
      elif ls "$root"/jest.config.* &>/dev/null 2>&1; then
        test_runner="npx jest"
      fi
    elif [[ -f "$root/pytest.ini" ]] || [[ -f "$root/pyproject.toml" ]]; then
      test_runner="pytest"
    elif [[ -f "$root/go.mod" ]]; then
      test_runner="go test ./..."
    elif [[ -f "$root/Cargo.toml" ]]; then
      test_runner="cargo test"
    fi
  fi

  echo "- Test runner: $test_runner"

  # Framework detection
  echo -n "- Framework: "
  if [[ -f "$root/package.json" ]]; then
    local fw="unknown"
    local deps=""
    if command -v jq &>/dev/null; then
      deps=$(jq -r '(.dependencies // {}) + (.devDependencies // {}) | keys[]' "$root/package.json" 2>/dev/null || true)
    else
      deps=$(python3 -c "
import json
d=json.load(open('$root/package.json'))
merged=dict(d.get('dependencies',{}))
merged.update(d.get('devDependencies',{}))
for k in merged: print(k)
" 2>/dev/null || true)
    fi
    for candidate in next react vue angular svelte express fastify hono; do
      if echo "$deps" | grep -q "^$candidate$"; then fw="$candidate"; break; fi
    done
    echo "$fw"
  elif [[ -f "$root/go.mod" ]]; then
    echo "Go"
  elif [[ -f "$root/Cargo.toml" ]]; then
    echo "Rust"
  elif [[ -f "$root/pyproject.toml" ]] || [[ -f "$root/setup.py" ]]; then
    echo "Python"
  else
    echo "unknown"
  fi

  # File naming pattern (sample basenames from existing source files)
  echo -n "- File naming: "
  local sample_basenames=""
  for dir in "$root/src" "$root/lib" "$root/app"; do
    if [[ -d "$dir" ]]; then
      local found
      found=$(find "$dir" -maxdepth 2 -type f \( -name '*.ts' -o -name '*.js' -o -name '*.py' -o -name '*.go' -o -name '*.rs' \) 2>/dev/null | head -10)
      for f in $found; do
        sample_basenames+="$(basename "$f")"$'\n'
      done
    fi
  done
  if [[ -n "$sample_basenames" ]]; then
    if echo "$sample_basenames" | grep -q '\-'; then
      echo "kebab-case"
    elif echo "$sample_basenames" | grep -q '_'; then
      echo "snake_case"
    else
      echo "camelCase (or unknown)"
    fi
  else
    echo "unknown"
  fi
}

# --- estimate: rough token count for a file ---
# Usage: context-prune.sh estimate <file>
cmd_estimate() {
  local file="${1:?Usage: context-prune.sh estimate <file>}"

  if [[ ! -f "$file" ]]; then
    echo -e "${RED}ERROR${NC} file not found: $file" >&2
    exit 1
  fi

  local words
  words=$(wc -w < "$file" | tr -d ' ')
  # Rough heuristic: ~0.75 words per token for code/prose mix
  local tokens=$(( (words * 4 + 2) / 3 ))

  echo "$tokens"

  if [[ $tokens -gt 32000 ]]; then
    echo -e "${YELLOW}WARN${NC} bundle exceeds 32000 token budget: ~$tokens tokens" >&2
  fi
}

# --- clean: remove .forge/context/ directory ---
# Usage: context-prune.sh clean [project-root]
cmd_clean() {
  local root="${1:-.}"
  local ctx_dir="$root/.forge/context"
  if [[ -d "$ctx_dir" ]]; then
    rm -rf "$ctx_dir"
    echo -e "${GREEN}Cleaned${NC} $ctx_dir/"
  else
    echo -e "${GREEN}Clean${NC} $ctx_dir/ does not exist"
  fi
}

# --- main dispatcher ---
case "${1:-help}" in
  extract)     shift; cmd_extract "$@" ;;
  conventions) shift; cmd_conventions "$@" ;;
  estimate)    shift; cmd_estimate "$@" ;;
  clean)       shift; cmd_clean "$@" ;;
  help|-h|--help) echo "Usage: context-prune.sh {extract|conventions|estimate|clean} [args...]"; exit 0 ;;
  *) echo "Unknown command: $1"; echo "Usage: context-prune.sh {extract|conventions|estimate|clean} [args...]"; exit 1 ;;
esac
