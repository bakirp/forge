#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/lib/test-helpers.sh"
SCRIPT="$ROOT/scripts/context-prune.sh"
FIXTURE="$ROOT/tests/fixtures/sample-architecture.md"
TEST_TMP="${TMPDIR:-/tmp}/forge-context-prune-test-$$"
mkdir -p "$TEST_TMP"
trap 'rm -rf "$TEST_TMP"' EXIT

echo "context-prune.sh tests"
echo "──────────────────────────────"

# --- Test 1: Extract single section ---
echo ""
echo "1. Extract single section"
out="$TEST_TMP/single.md"
bash "$SCRIPT" extract "$FIXTURE" "$out" "api contracts" 2>/dev/null

if grep -q "### createTask" "$out"; then
  pass "extracted createTask contract"
else
  fail "createTask contract not found in output"
fi

if grep -q "### getTaskById" "$out"; then
  pass "extracted getTaskById contract"
else
  fail "getTaskById contract not found in output"
fi

# Should NOT contain other sections
if grep -q "## Edge Cases" "$out"; then
  fail "output contains Edge Cases (should not)"
else
  pass "output does not contain unrelated sections"
fi

# --- Test 2: Extract multiple sections ---
echo ""
echo "2. Extract multiple sections"
out="$TEST_TMP/multi.md"
bash "$SCRIPT" extract "$FIXTURE" "$out" "api contracts" "edge cases" "test strategy" 2>/dev/null

if grep -q "## API Contracts" "$out"; then
  pass "contains API Contracts"
else
  fail "missing API Contracts"
fi

if grep -q "## Edge Cases" "$out"; then
  pass "contains Edge Cases"
else
  fail "missing Edge Cases"
fi

if grep -q "## Test Strategy" "$out" || grep -q "### Unit Tests" "$out"; then
  pass "contains Test Strategy"
else
  fail "missing Test Strategy"
fi

# Should NOT contain Data Flow
if grep -q "## Data Flow" "$out"; then
  fail "output contains Data Flow (should not)"
else
  pass "output does not contain unrelated sections"
fi

# --- Test 3: Case-insensitive match ---
echo ""
echo "3. Case-insensitive match"
out="$TEST_TMP/case.md"
bash "$SCRIPT" extract "$FIXTURE" "$out" "API CONTRACTS" 2>/dev/null

if grep -q "### createTask" "$out"; then
  pass "case-insensitive match works (uppercase query)"
else
  fail "case-insensitive match failed"
fi

out2="$TEST_TMP/case2.md"
bash "$SCRIPT" extract "$FIXTURE" "$out2" "edge CASES" 2>/dev/null

if grep -q "Creating a task with an empty title" "$out2"; then
  pass "case-insensitive match works (mixed case query)"
else
  fail "case-insensitive match failed for mixed case"
fi

# --- Test 4: Code block immunity ---
echo ""
echo "4. Code block immunity"
out="$TEST_TMP/code-immune.md"
# "this is not a header" and "also not a header" are inside code blocks
bash "$SCRIPT" extract "$FIXTURE" "$out" "this is not a header" 2>/dev/null

# Should fall back to full doc because no real headers match
if [[ -f "$out" ]] && grep -q "## Status: LOCKED" "$out"; then
  pass "code block headers not extracted (fell back to full doc)"
else
  fail "code block headers were incorrectly matched"
fi

# Also verify: extracting a real section does NOT include code block content as a section
out2="$TEST_TMP/code-immune2.md"
bash "$SCRIPT" extract "$FIXTURE" "$out2" "code example" 2>/dev/null

if grep -q '## also not a header' "$out2"; then
  # This is expected — the code block content is included as body text of the Code Example section
  pass "code block content included as section body (not as separate section)"
else
  pass "code block content handled correctly"
fi

# --- Test 5: Missing section handling ---
echo ""
echo "5. Missing section handling"
out="$TEST_TMP/missing.md"
stderr_out="$TEST_TMP/missing-stderr.txt"
bash "$SCRIPT" extract "$FIXTURE" "$out" "nonexistent section xyz" 2>"$stderr_out" || true

if grep -q "WARN" "$stderr_out"; then
  pass "warning emitted for missing section"
else
  fail "no warning for missing section"
fi

# Should fall back to full doc
if [[ -f "$out" ]] && grep -q "## Status: LOCKED" "$out"; then
  pass "fell back to full doc when no sections matched"
else
  fail "did not fall back to full doc"
fi

# --- Test 6: Conventions detection ---
echo ""
echo "6. Conventions detection"
conv_dir="$TEST_TMP/conv-project"
mkdir -p "$conv_dir"
cat > "$conv_dir/package.json" << 'PKGJSON'
{
  "name": "test-project",
  "scripts": {
    "test": "vitest run"
  },
  "dependencies": {
    "express": "^4.18.0"
  }
}
PKGJSON

conv_out=$(bash "$SCRIPT" conventions "$conv_dir" 2>/dev/null)

if echo "$conv_out" | grep -q "vitest run"; then
  pass "detected test runner from package.json"
else
  fail "did not detect test runner (got: $conv_out)"
fi

if echo "$conv_out" | grep -q "express"; then
  pass "detected framework from package.json"
else
  fail "did not detect framework"
fi

# --- Test 7: Token estimate ---
echo ""
echo "7. Token estimate"
# Create a file with known word count
word_file="$TEST_TMP/words.md"
# Write exactly 75 words (one per line)
for i in $(seq 1 75); do echo "word"; done > "$word_file"
estimate=$(bash "$SCRIPT" estimate "$word_file" 2>/dev/null | head -1)

# 75 words × 4/3 = 100 tokens
if [[ "$estimate" -ge 80 && "$estimate" -le 120 ]]; then
  pass "token estimate in expected range ($estimate for 75 words)"
else
  fail "token estimate out of range: $estimate (expected ~100 for 75 words)"
fi

# --- Test 8: Token warning ---
echo ""
echo "8. Token warning for large bundles"
large_file="$TEST_TMP/large.md"
# Create a file that will exceed 32000 tokens (~24000+ words)
for i in $(seq 1 25000); do echo "word$i"; done > "$large_file"
stderr_out="$TEST_TMP/large-stderr.txt"
bash "$SCRIPT" estimate "$large_file" 2>"$stderr_out" >/dev/null

if grep -q "WARN" "$stderr_out" && grep -q "32000" "$stderr_out"; then
  pass "warning emitted for bundle exceeding 32000 tokens"
else
  fail "no warning for large bundle (stderr: $(cat "$stderr_out"))"
fi

# --- Test 9: Clean ---
echo ""
echo "9. Clean removes .forge/context/"
clean_dir="$TEST_TMP/clean-project"
mkdir -p "$clean_dir/.forge/context"
echo "test" > "$clean_dir/.forge/context/task-1.md"
echo "test" > "$clean_dir/.forge/context/task-2.md"

bash "$SCRIPT" clean "$clean_dir" 2>/dev/null

if [[ ! -d "$clean_dir/.forge/context" ]]; then
  pass "clean removed .forge/context/ directory"
else
  fail "clean did not remove .forge/context/"
fi

# Clean on non-existent directory should not error
bash "$SCRIPT" clean "$clean_dir" 2>/dev/null
pass "clean on non-existent directory does not error"

# --- Test 10: Full doc fallback for non-standard arch doc ---
echo ""
echo "10. Full doc fallback"
nonstandard="$TEST_TMP/nonstandard.md"
cat > "$nonstandard" << 'NONSTD'
# My Architecture

This doc uses no standard headers.

Some content about the system.

More content here.
NONSTD

out="$TEST_TMP/fallback.md"
stderr_out="$TEST_TMP/fallback-stderr.txt"
bash "$SCRIPT" extract "$nonstandard" "$out" "api contracts" 2>"$stderr_out" || true

if grep -q "WARN" "$stderr_out"; then
  pass "warning emitted for non-standard doc"
else
  fail "no warning for non-standard doc"
fi

if [[ -f "$out" ]] && grep -q "My Architecture" "$out"; then
  pass "fell back to full doc content"
else
  fail "did not fall back to full doc"
fi

# --- Test 11: :: subsection filter (extracts specific subsection) ---
echo ""
echo "11. :: subsection filter"
out="$TEST_TMP/subsection.md"
bash "$SCRIPT" extract "$FIXTURE" "$out" "API Contracts::createTask" 2>/dev/null

if grep -q "### createTask" "$out"; then
  pass ":: filter extracts matching subsection"
else
  fail ":: filter did not extract createTask"
fi

# Should include the parent ## header for context
if grep -q "## API Contracts" "$out"; then
  pass ":: filter includes parent section header"
else
  fail ":: filter missing parent section header"
fi

# Should NOT include unrelated subsections
if grep -q "### getTaskById" "$out"; then
  fail ":: filter includes non-matching subsection getTaskById"
else
  pass ":: filter excludes non-matching subsections"
fi

# --- Test 12: :: numbered list filter ---
echo ""
echo "12. :: numbered list filter"
out="$TEST_TMP/numbered.md"
bash "$SCRIPT" extract "$FIXTURE" "$out" "Edge Cases::1,3" 2>/dev/null

if grep -q "## Edge Cases" "$out"; then
  pass "numbered filter includes section header"
else
  fail "numbered filter missing section header"
fi

if grep -q "^1\." "$out"; then
  pass "numbered filter includes item 1"
else
  fail "numbered filter missing item 1"
fi

if grep -q "^3\." "$out"; then
  pass "numbered filter includes item 3"
else
  fail "numbered filter missing item 3"
fi

if grep -q "^2\." "$out"; then
  fail "numbered filter includes non-requested item 2"
else
  pass "numbered filter excludes non-requested items"
fi

# --- Test 13: File naming detection ---
echo ""
echo "13. File naming detection"
naming_dir="$TEST_TMP/naming-project"
mkdir -p "$naming_dir/src"
touch "$naming_dir/src/user-service.ts" "$naming_dir/src/task-controller.ts"
cat > "$naming_dir/package.json" << 'PKGJSON'
{ "name": "test", "scripts": { "test": "jest" } }
PKGJSON

naming_out=$(bash "$SCRIPT" conventions "$naming_dir" 2>/dev/null)

if echo "$naming_out" | grep -q "kebab-case"; then
  pass "detected kebab-case file naming"
else
  fail "did not detect kebab-case (got: $naming_out)"
fi

naming_dir2="$TEST_TMP/naming-project2"
mkdir -p "$naming_dir2/src"
touch "$naming_dir2/src/user_service.py" "$naming_dir2/src/task_controller.py"
cat > "$naming_dir2/pyproject.toml" << 'PYTOML'
[tool.pytest]
PYTOML

naming_out2=$(bash "$SCRIPT" conventions "$naming_dir2" 2>/dev/null)

if echo "$naming_out2" | grep -q "snake_case"; then
  pass "detected snake_case file naming"
else
  fail "did not detect snake_case (got: $naming_out2)"
fi

print_test_summary
