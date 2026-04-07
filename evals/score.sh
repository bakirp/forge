#!/usr/bin/env bash
set -euo pipefail

# FORGE Eval Scorer
# Reads evals/results.jsonl, matches each result to its task JSON by id,
# and scores route accuracy, classification accuracy, artifact compliance,
# and red flag violations.
#
# Usage: ./evals/score.sh [results_file]
# Requires: jq

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
RESULTS_FILE="${1:-$SCRIPT_DIR/results.jsonl}"
TASKS_DIR="$SCRIPT_DIR/tasks"

# --- Preflight checks ---

if ! command -v jq &>/dev/null; then
  echo "Error: jq is required but not installed." >&2
  echo "Install: brew install jq  OR  apt-get install jq" >&2
  exit 1
fi

if [[ ! -f "$RESULTS_FILE" ]]; then
  echo "Error: Results file not found: $RESULTS_FILE" >&2
  echo "Usage: $0 [path/to/results.jsonl]" >&2
  exit 1
fi

TOTAL=0
ROUTE_CORRECT=0
ROUTE_TOTAL=0
CLASS_CORRECT=0
CLASS_TOTAL=0
ARTIFACT_COMPLIANT=0
ARTIFACT_TOTAL=0
RED_FLAG_VIOLATIONS=0
RED_FLAG_TOTAL=0
TASK_NOT_FOUND=0

# --- Score each result line ---

while IFS= read -r line; do
  # Skip empty lines
  [[ -z "$line" ]] && continue

  TOTAL=$((TOTAL + 1))
  RESULT_ID=$(echo "$line" | jq -r '.id')

  if [[ -z "$RESULT_ID" || "$RESULT_ID" == "null" ]]; then
    echo "WARN: Line $TOTAL has no id, skipping."
    continue
  fi

  # Find the task JSON file
  TASK_FILE=""
  for dir in "$TASKS_DIR"/*/; do
    candidate="$dir${RESULT_ID}.json"
    if [[ -f "$candidate" ]]; then
      TASK_FILE="$candidate"
      break
    fi
  done

  if [[ -z "$TASK_FILE" ]]; then
    echo "WARN: No task file found for id '$RESULT_ID'"
    TASK_NOT_FOUND=$((TASK_NOT_FOUND + 1))
    continue
  fi

  # Parse task JSON once, extract all needed fields upfront
  TASK_PARSED=$(jq '{
    category,
    expected_skill_route,
    expected_classification,
    acceptable_routes: (.acceptable_routes // []),
    acceptable_classifications: (.acceptable_classifications // []),
    expected_artifacts: (.expected_artifacts // []),
    red_flags: (.red_flags // [])
  }' "$TASK_FILE")

  CATEGORY=$(echo "$TASK_PARSED" | jq -r '.category')

  # --- Route accuracy ---
  ACTUAL_ROUTE=$(echo "$line" | jq -r '.actual_route // empty')
  if [[ -n "$ACTUAL_ROUTE" ]]; then
    ROUTE_TOTAL=$((ROUTE_TOTAL + 1))

    if [[ "$CATEGORY" == "ambiguous" ]]; then
      MATCH=$(echo "$TASK_PARSED" | jq -r --arg route "$ACTUAL_ROUTE" \
        '[.acceptable_routes[] | select(. == $route)] | length')
      if [[ "$MATCH" -gt 0 ]]; then
        ROUTE_CORRECT=$((ROUTE_CORRECT + 1))
      else
        ACCEPTABLE=$(echo "$TASK_PARSED" | jq -r '.acceptable_routes | join(", ")')
        echo "MISS route  | $RESULT_ID | got: $ACTUAL_ROUTE | acceptable: $ACCEPTABLE"
      fi
    else
      EXPECTED_ROUTE=$(echo "$TASK_PARSED" | jq -r '.expected_skill_route')
      if [[ "$ACTUAL_ROUTE" == "$EXPECTED_ROUTE" ]]; then
        ROUTE_CORRECT=$((ROUTE_CORRECT + 1))
      else
        echo "MISS route  | $RESULT_ID | got: $ACTUAL_ROUTE | expected: $EXPECTED_ROUTE"
      fi
    fi
  fi

  # --- Classification accuracy ---
  ACTUAL_CLASS=$(echo "$line" | jq -r '.actual_classification // empty')
  if [[ -n "$ACTUAL_CLASS" ]]; then
    CLASS_TOTAL=$((CLASS_TOTAL + 1))

    if [[ "$CATEGORY" == "ambiguous" ]]; then
      MATCH=$(echo "$TASK_PARSED" | jq -r --arg cls "$ACTUAL_CLASS" \
        '[.acceptable_classifications[] | select(. == $cls)] | length')
      if [[ "$MATCH" -gt 0 ]]; then
        CLASS_CORRECT=$((CLASS_CORRECT + 1))
      else
        ACCEPTABLE=$(echo "$TASK_PARSED" | jq -r '.acceptable_classifications | join(", ")')
        echo "MISS class  | $RESULT_ID | got: $ACTUAL_CLASS | acceptable: $ACCEPTABLE"
      fi
    else
      EXPECTED_CLASS=$(echo "$TASK_PARSED" | jq -r '.expected_classification')
      if [[ "$ACTUAL_CLASS" == "$EXPECTED_CLASS" ]]; then
        CLASS_CORRECT=$((CLASS_CORRECT + 1))
      else
        echo "MISS class  | $RESULT_ID | got: $ACTUAL_CLASS | expected: $EXPECTED_CLASS"
      fi
    fi
  fi

  # --- Artifact compliance ---
  ACTUAL_ARTIFACTS=$(echo "$line" | jq -r '.actual_artifacts // empty')
  EXPECTED_ARTIFACTS=$(echo "$TASK_PARSED" | jq -r '.expected_artifacts')

  if [[ -n "$ACTUAL_ARTIFACTS" && "$EXPECTED_ARTIFACTS" != "[]" ]]; then
    ARTIFACT_TOTAL=$((ARTIFACT_TOTAL + 1))

    ALL_PRESENT=true
    while IFS= read -r pattern; do
      FOUND=$(echo "$line" | jq -r --arg pat "$pattern" \
        '[.actual_artifacts[] | select(test($pat))] | length')
      if [[ "$FOUND" -eq 0 ]]; then
        ALL_PRESENT=false
        echo "MISS artifact | $RESULT_ID | missing: $pattern"
      fi
    done < <(echo "$TASK_PARSED" | jq -r '.expected_artifacts[]')

    if [[ "$ALL_PRESENT" == "true" ]]; then
      ARTIFACT_COMPLIANT=$((ARTIFACT_COMPLIANT + 1))
    fi
  elif [[ "$EXPECTED_ARTIFACTS" == "[]" ]]; then
    ARTIFACT_TOTAL=$((ARTIFACT_TOTAL + 1))
    ARTIFACT_COMPLIANT=$((ARTIFACT_COMPLIANT + 1))
  fi

  # --- Red flag detection ---
  ACTUAL_FLAGS=$(echo "$line" | jq -r '.observed_flags // [] | .[]' 2>/dev/null)

  if [[ -n "$ACTUAL_FLAGS" ]]; then
    while IFS= read -r flag; do
      [[ -z "$flag" ]] && continue
      RED_FLAG_TOTAL=$((RED_FLAG_TOTAL + 1))

      MATCH=$(echo "$TASK_PARSED" | jq -r --arg f "$flag" \
        '[.red_flags[] | select(. == $f)] | length')
      if [[ "$MATCH" -gt 0 ]]; then
        RED_FLAG_VIOLATIONS=$((RED_FLAG_VIOLATIONS + 1))
        echo "RED FLAG     | $RESULT_ID | $flag"
      fi
    done <<< "$ACTUAL_FLAGS"
  fi

done < "$RESULTS_FILE"

# --- Summary ---

echo ""
echo "=============================="
echo "  FORGE Eval Score Summary"
echo "=============================="
echo ""
echo "Results scored: $TOTAL"
[[ $TASK_NOT_FOUND -gt 0 ]] && echo "Tasks not found: $TASK_NOT_FOUND"
echo ""

# Helper for percentage
pct() {
  local num=$1 den=$2
  if [[ $den -eq 0 ]]; then
    echo "N/A (0 scored)"
  else
    echo "$num / $den ($(( (num * 100) / den ))%)"
  fi
}

echo "Route accuracy:          $(pct $ROUTE_CORRECT $ROUTE_TOTAL)"
echo "Classification accuracy: $(pct $CLASS_CORRECT $CLASS_TOTAL)"
echo "Artifact compliance:     $(pct $ARTIFACT_COMPLIANT $ARTIFACT_TOTAL)"
echo "Red flag violations:     ${RED_FLAG_VIOLATIONS} across ${RED_FLAG_TOTAL} observed flags"
echo ""

# Overall pass rate (route + classification combined)
COMBINED_CORRECT=$((ROUTE_CORRECT + CLASS_CORRECT))
COMBINED_TOTAL=$((ROUTE_TOTAL + CLASS_TOTAL))
echo "Combined routing+classification: $(pct $COMBINED_CORRECT $COMBINED_TOTAL)"
echo ""

# Exit code: non-zero if any misses
if [[ $ROUTE_CORRECT -lt $ROUTE_TOTAL || $CLASS_CORRECT -lt $CLASS_TOTAL || $RED_FLAG_VIOLATIONS -gt 0 ]]; then
  echo "Status: ISSUES FOUND"
  exit 1
else
  echo "Status: ALL PASS"
  exit 0
fi
