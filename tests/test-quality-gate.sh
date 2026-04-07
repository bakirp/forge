#!/usr/bin/env bash
set -euo pipefail

RED='\033[0;31m'
GRN='\033[0;32m'
YEL='\033[0;33m'
RST='\033[0m'

FAILS=0
SKIPS=0

pass() { printf "${GRN}PASS${RST}: %s\n" "$1"; }
fail() { printf "${RED}FAIL${RST}: %s\n" "$1"; FAILS=$((FAILS + 1)); }
skip() { printf "${YEL}SKIP${RST}: %s\n" "$1"; SKIPS=$((SKIPS + 1)); }

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SCRIPT="$ROOT/scripts/quality-gate.sh"
TEST_TMP="${TMPDIR:-/tmp}/forge-quality-gate-test-$$"
mkdir -p "$TEST_TMP"
trap 'rm -rf "$TEST_TMP"' EXIT

echo "quality-gate.sh tests"
echo "──────────────────────────────"

# ═══════════════════════════════════
# 1. detect-runner tests
# ═══════════════════════════════════
echo ""
echo "1. detect-runner"

# 1a. Config override
echo "  1a. Config override"
dir="$TEST_TMP/runner-config"
mkdir -p "$dir/.forge"
echo '{"test_command": "custom-test-runner"}' > "$dir/.forge/config.json"
result=$(bash "$SCRIPT" detect-runner "$dir")
[[ "$result" == "custom-test-runner" ]] && pass "config override" || fail "config override: got '$result'"

# 1b. package.json scripts.test
echo "  1b. package.json scripts.test"
dir="$TEST_TMP/runner-pkg"
mkdir -p "$dir"
echo '{"scripts":{"test":"vitest"}}' > "$dir/package.json"
result=$(bash "$SCRIPT" detect-runner "$dir")
[[ "$result" == "vitest" ]] && pass "package.json scripts.test" || fail "package.json scripts.test: got '$result'"

# 1c. vitest.config.ts
echo "  1c. vitest.config.ts"
dir="$TEST_TMP/runner-vitest"
mkdir -p "$dir"
echo '{}' > "$dir/package.json"
touch "$dir/vitest.config.ts"
result=$(bash "$SCRIPT" detect-runner "$dir")
[[ "$result" == "npx vitest run" ]] && pass "vitest.config.ts" || fail "vitest.config.ts: got '$result'"

# 1d. jest.config.js
echo "  1d. jest.config.js"
dir="$TEST_TMP/runner-jest"
mkdir -p "$dir"
echo '{}' > "$dir/package.json"
touch "$dir/jest.config.js"
result=$(bash "$SCRIPT" detect-runner "$dir")
[[ "$result" == "npx jest" ]] && pass "jest.config.js" || fail "jest.config.js: got '$result'"

# 1e. pytest.ini
echo "  1e. pytest.ini"
dir="$TEST_TMP/runner-pytest"
mkdir -p "$dir"
touch "$dir/pytest.ini"
result=$(bash "$SCRIPT" detect-runner "$dir")
[[ "$result" == "pytest" ]] && pass "pytest.ini" || fail "pytest.ini: got '$result'"

# 1f. pyproject.toml with [tool.pytest]
echo "  1f. pyproject.toml with pytest"
dir="$TEST_TMP/runner-pyproject"
mkdir -p "$dir"
printf '[tool.pytest.ini_options]\nminversion = "6.0"\n' > "$dir/pyproject.toml"
result=$(bash "$SCRIPT" detect-runner "$dir")
[[ "$result" == "pytest" ]] && pass "pyproject.toml pytest" || fail "pyproject.toml pytest: got '$result'"

# 1g. go.mod
echo "  1g. go.mod"
dir="$TEST_TMP/runner-go"
mkdir -p "$dir"
echo 'module example.com/test' > "$dir/go.mod"
result=$(bash "$SCRIPT" detect-runner "$dir")
[[ "$result" == "go test ./..." ]] && pass "go.mod" || fail "go.mod: got '$result'"

# 1h. Cargo.toml
echo "  1h. Cargo.toml"
dir="$TEST_TMP/runner-rust"
mkdir -p "$dir"
echo '[package]' > "$dir/Cargo.toml"
result=$(bash "$SCRIPT" detect-runner "$dir")
[[ "$result" == "cargo test" ]] && pass "Cargo.toml" || fail "Cargo.toml: got '$result'"

# 1i. pom.xml (Maven)
echo "  1i. pom.xml"
dir="$TEST_TMP/runner-maven"
mkdir -p "$dir"
echo '<project></project>' > "$dir/pom.xml"
result=$(bash "$SCRIPT" detect-runner "$dir")
[[ "$result" == "mvn test" ]] && pass "pom.xml" || fail "pom.xml: got '$result'"

# 1j. build.gradle (Gradle)
echo "  1j. build.gradle"
dir="$TEST_TMP/runner-gradle"
mkdir -p "$dir"
echo 'plugins {}' > "$dir/build.gradle"
result=$(bash "$SCRIPT" detect-runner "$dir")
[[ "$result" == "./gradlew test" ]] && pass "build.gradle" || fail "build.gradle: got '$result'"

# 1k. Gemfile + .rspec (Ruby RSpec)
echo "  1k. Gemfile + .rspec"
dir="$TEST_TMP/runner-rspec"
mkdir -p "$dir"
echo 'source "https://rubygems.org"' > "$dir/Gemfile"
echo '--color' > "$dir/.rspec"
result=$(bash "$SCRIPT" detect-runner "$dir")
[[ "$result" == "bundle exec rspec" ]] && pass "Gemfile + .rspec" || fail "Gemfile + .rspec: got '$result'"

# 1l. phpunit.xml
echo "  1l. phpunit.xml"
dir="$TEST_TMP/runner-php"
mkdir -p "$dir"
echo '<phpunit/>' > "$dir/phpunit.xml"
result=$(bash "$SCRIPT" detect-runner "$dir")
[[ "$result" == "./vendor/bin/phpunit" ]] && pass "phpunit.xml" || fail "phpunit.xml: got '$result'"

# 1m. .csproj (dotnet)
echo "  1m. .csproj"
dir="$TEST_TMP/runner-dotnet"
mkdir -p "$dir"
echo '<Project Sdk="Microsoft.NET.Sdk"></Project>' > "$dir/Test.csproj"
result=$(bash "$SCRIPT" detect-runner "$dir")
[[ "$result" == "dotnet test" ]] && pass ".csproj" || fail ".csproj: got '$result'"

# 1n. mocha
echo "  1n. .mocharc.yml"
dir="$TEST_TMP/runner-mocha"
mkdir -p "$dir"
echo '{}' > "$dir/package.json"
touch "$dir/.mocharc.yml"
result=$(bash "$SCRIPT" detect-runner "$dir")
[[ "$result" == "npx mocha" ]] && pass ".mocharc.yml" || fail ".mocharc.yml: got '$result'"

# 1o. cypress
echo "  1o. cypress.config.ts"
dir="$TEST_TMP/runner-cypress"
mkdir -p "$dir"
echo '{}' > "$dir/package.json"
touch "$dir/cypress.config.ts"
result=$(bash "$SCRIPT" detect-runner "$dir")
[[ "$result" == "npx cypress run" ]] && pass "cypress.config.ts" || fail "cypress.config.ts: got '$result'"

# 1p. playwright
echo "  1p. playwright.config.ts"
dir="$TEST_TMP/runner-playwright"
mkdir -p "$dir"
echo '{}' > "$dir/package.json"
touch "$dir/playwright.config.ts"
result=$(bash "$SCRIPT" detect-runner "$dir")
[[ "$result" == "npx playwright test" ]] && pass "playwright.config.ts" || fail "playwright.config.ts: got '$result'"

# 1q. unknown fallback
echo "  1q. unknown fallback"
dir="$TEST_TMP/runner-empty"
mkdir -p "$dir"
result=$(bash "$SCRIPT" detect-runner "$dir")
[[ "$result" == "unknown" ]] && pass "empty dir returns unknown" || fail "empty dir: got '$result'"

# ═══════════════════════════════════
# 2. detect-coverage tests
# ═══════════════════════════════════
echo ""
echo "2. detect-coverage"

# 2a. Config override
echo "  2a. Config override"
dir="$TEST_TMP/cov-config"
mkdir -p "$dir/.forge"
echo '{"coverage_command": "custom-coverage"}' > "$dir/.forge/config.json"
result=$(bash "$SCRIPT" detect-coverage "$dir")
[[ "$result" == "custom-coverage" ]] && pass "coverage config override" || fail "coverage config: got '$result'"

# 2b. vitest coverage
echo "  2b. vitest coverage"
dir="$TEST_TMP/cov-vitest"
mkdir -p "$dir"
echo '{}' > "$dir/package.json"
touch "$dir/vitest.config.ts"
result=$(bash "$SCRIPT" detect-coverage "$dir")
[[ "$result" == "npx vitest run --coverage" ]] && pass "vitest coverage" || fail "vitest coverage: got '$result'"

# 2c. jest coverage
echo "  2c. jest coverage"
dir="$TEST_TMP/cov-jest"
mkdir -p "$dir"
echo '{}' > "$dir/package.json"
touch "$dir/jest.config.js"
result=$(bash "$SCRIPT" detect-coverage "$dir")
[[ "$result" == "npx jest --coverage" ]] && pass "jest coverage" || fail "jest coverage: got '$result'"

# 2d. go coverage
echo "  2d. go coverage"
dir="$TEST_TMP/cov-go"
mkdir -p "$dir"
echo 'module test' > "$dir/go.mod"
result=$(bash "$SCRIPT" detect-coverage "$dir")
[[ "$result" == "go test -cover ./..." ]] && pass "go coverage" || fail "go coverage: got '$result'"

# 2e. unknown
echo "  2e. unknown"
dir="$TEST_TMP/cov-empty"
mkdir -p "$dir"
result=$(bash "$SCRIPT" detect-coverage "$dir")
[[ "$result" == "unknown" ]] && pass "empty dir returns unknown" || fail "cov empty: got '$result'"

# ═══════════════════════════════════
# 3. coverage threshold tests
# ═══════════════════════════════════
echo ""
echo "3. coverage threshold enforcement"

# 3a. Coverage above threshold (mock)
echo "  3a. Above threshold"
dir="$TEST_TMP/cov-above"
mkdir -p "$dir/.forge"
echo '{"coverage_command": "echo Total coverage: 85.5%"}' > "$dir/.forge/config.json"
result=$(bash "$SCRIPT" coverage "$dir" --threshold 80 2>/dev/null)
echo "$result" | grep -q "status=PASS" && pass "85.5% >= 80% = PASS" || fail "above threshold: got '$result'"

# 3b. Coverage below threshold (mock)
echo "  3b. Below threshold"
dir="$TEST_TMP/cov-below"
mkdir -p "$dir/.forge"
echo '{"coverage_command": "echo Total coverage: 60.0%"}' > "$dir/.forge/config.json"
exit_code=0
result=$(bash "$SCRIPT" coverage "$dir" --threshold 80 2>/dev/null) || exit_code=$?
echo "$result" | grep -q "status=FAIL" && pass "60% < 80% = FAIL" || fail "below threshold: got '$result'"
[[ "$exit_code" -eq 1 ]] && pass "exit code 1 on failure" || fail "exit code: got $exit_code"

# 3c. No threshold = PASS
echo "  3c. No threshold"
dir="$TEST_TMP/cov-none"
mkdir -p "$dir/.forge"
echo '{"coverage_command": "echo Total coverage: 50.0%"}' > "$dir/.forge/config.json"
result=$(bash "$SCRIPT" coverage "$dir" 2>/dev/null)
echo "$result" | grep -q "status=PASS" && pass "no threshold = PASS" || fail "no threshold: got '$result'"

# ═══════════════════════════════════
# 4. reusability-search tests
# ═══════════════════════════════════
echo ""
echo "4. reusability-search"

# 4a. Find existing function
echo "  4a. Find existing function"
dir="$TEST_TMP/reuse"
mkdir -p "$dir/src"
cat > "$dir/src/utils.js" << 'JSEOF'
function validateEmail(email) {
  return /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email);
}
JSEOF
result=$(bash "$SCRIPT" reusability-search "$dir" "validateEmail" 2>/dev/null)
echo "$result" | grep -q "validateEmail" && pass "found existing function" || fail "reusability search: got '$result'"

# 4b. No match
echo "  4b. No match"
result=$(bash "$SCRIPT" reusability-search "$dir" "nonExistentFunc" 2>/dev/null)
echo "$result" | grep -q "(no matches)" && pass "no matches reported" || fail "no match: got '$result'"

# ═══════════════════════════════════
# 5. dry-check tests
# ═══════════════════════════════════
echo ""
echo "5. dry-check"

# 5a. Detect duplicate blocks
echo "  5a. Detect duplicate blocks"
dir="$TEST_TMP/dry"
mkdir -p "$dir/src"
cat > "$dir/src/a.js" << 'JSEOF'
function processA(data) {
  const result = data.map(item => item.value);
  const filtered = result.filter(v => v > 0);
  const sorted = filtered.sort((a, b) => a - b);
  const total = sorted.reduce((sum, v) => sum + v, 0);
  return total;
}
JSEOF
cat > "$dir/src/b.js" << 'JSEOF'
function processB(data) {
  const result = data.map(item => item.value);
  const filtered = result.filter(v => v > 0);
  const sorted = filtered.sort((a, b) => a - b);
  const total = sorted.reduce((sum, v) => sum + v, 0);
  return total;
}
JSEOF
result=$(bash "$SCRIPT" dry-check "$dir" "src/a.js" 2>/dev/null)
echo "$result" | grep -q "duplicates_found=" && pass "dry-check produces output" || fail "dry-check: got '$result'"

# 5b. No files
echo "  5b. No files"
result=$(bash "$SCRIPT" dry-check "$dir" 2>/dev/null)
echo "$result" | grep -q "No files to check" && pass "no files warning" || fail "no files: got '$result'"

# ═══════════════════════════════════
# 6. path-map tests
# ═══════════════════════════════════
echo ""
echo "6. path-map"

# 6a. JavaScript if/else/switch/loop
echo "  6a. JS branching constructs"
dir="$TEST_TMP/pathmap"
mkdir -p "$dir"
cat > "$dir/auth.js" << 'JSEOF'
function authenticate(token) {
  if (!token) {
    return { error: 'missing token' };
  } else if (token.expired) {
    return { error: 'expired' };
  } else {
    return { user: token.user };
  }

  switch (token.role) {
    case 'admin':
      return grantAll();
    case 'user':
      return grantBasic();
    default:
      return deny();
  }

  for (const perm of token.permissions) {
    validate(perm);
  }

  try {
    decode(token);
  } catch (err) {
    log(err);
  }
}
JSEOF
result=$(bash "$SCRIPT" path-map "$dir" "auth.js" 2>/dev/null)
if_count=$(echo "$result" | grep -c '|if|' || true)
else_count=$(echo "$result" | grep -c '|else|' || true)
case_count=$(echo "$result" | grep -c '|switch-case|' || true)
default_count=$(echo "$result" | grep -c '|switch-default|' || true)
loop_count=$(echo "$result" | grep -c '|loop|' || true)
try_count=$(echo "$result" | grep -c '|try|' || true)
catch_count=$(echo "$result" | grep -c '|catch|' || true)

[[ "$if_count" -ge 2 ]] && pass "detected if branches ($if_count)" || fail "if branches: got $if_count"
[[ "$else_count" -ge 1 ]] && pass "detected else branch ($else_count)" || fail "else branch: got $else_count"
[[ "$case_count" -ge 2 ]] && pass "detected switch cases ($case_count)" || fail "switch cases: got $case_count"
[[ "$default_count" -ge 1 ]] && pass "detected default case ($default_count)" || fail "default case: got $default_count"
[[ "$loop_count" -ge 1 ]] && pass "detected loop ($loop_count)" || fail "loop: got $loop_count"
[[ "$try_count" -ge 1 ]] && pass "detected try ($try_count)" || fail "try: got $try_count"
[[ "$catch_count" -ge 1 ]] && pass "detected catch ($catch_count)" || fail "catch: got $catch_count"

# 6b. Python if/elif/else/for/try/except
echo "  6b. Python branching constructs"
cat > "$dir/handler.py" << 'PYEOF'
def handle_request(req):
    if req.method == 'GET':
        return get_handler(req)
    elif req.method == 'POST':
        return post_handler(req)
    else:
        return error_405()

    for item in req.items:
        process(item)

    try:
        validate(req)
    except ValueError:
        return bad_request()
    except Exception:
        return server_error()
PYEOF
result=$(bash "$SCRIPT" path-map "$dir" "handler.py" 2>/dev/null)
total=$(echo "$result" | grep -c '|' || true)
[[ "$total" -ge 7 ]] && pass "Python paths detected ($total)" || fail "Python paths: got $total"

# 6c. Go if/else/switch/for
echo "  6c. Go branching constructs"
cat > "$dir/service.go" << 'GOEOF'
package main

func handleStatus(code int) string {
	if code == 200 {
		return "OK"
	} else if code == 404 {
		return "Not Found"
	} else {
		return "Error"
	}

	switch code {
	case 301:
		return "Redirect"
	case 500:
		return "Server Error"
	}

	for i := 0; i < 10; i++ {
		process(i)
	}
}
GOEOF
result=$(bash "$SCRIPT" path-map "$dir" "service.go" 2>/dev/null)
total=$(echo "$result" | grep -c '|' || true)
[[ "$total" -ge 6 ]] && pass "Go paths detected ($total)" || fail "Go paths: got $total"

# 6d. No files
echo "  6d. No files"
result=$(bash "$SCRIPT" path-map "$dir" 2>/dev/null)
echo "$result" | grep -q "No files to map" && pass "no files warning" || fail "no files: got '$result'"

# ═══════════════════════════════════
# 7. path-diff tests
# ═══════════════════════════════════
echo ""
echo "7. path-diff"

# 7a. Create a temp git repo with changes
echo "  7a. Change impact analysis"
dir="$TEST_TMP/pathdiff"
mkdir -p "$dir/src"
(
  cd "$dir"
  git init -q
  git checkout -b main -q 2>/dev/null || true

  # Base version: simple if/else
  cat > src/app.js << 'JSEOF'
function process(input) {
  if (input > 0) {
    return 'positive';
  } else {
    return 'non-positive';
  }
}
JSEOF
  git add -A && git commit -q -m "initial"

  # Create feature branch with a new branch added
  git checkout -b feature -q
  cat > src/app.js << 'JSEOF'
function process(input) {
  if (input > 0) {
    return 'positive';
  } else if (input === 0) {
    return 'zero';
  } else {
    return 'negative';
  }

  switch (input) {
    case 1:
      return 'one';
    default:
      return 'other';
  }
}
JSEOF
  git add -A && git commit -q -m "add branches"
)

result=$(bash "$SCRIPT" path-diff "$dir" "main" 2>/dev/null)
if echo "$result" | grep -qE '(ADD_TEST|MODIFY_TEST|NO_ACTION)'; then
  pass "path-diff produces classified output"
else
  fail "path-diff: got '$result'"
fi

add_count=$(echo "$result" | grep -c 'ADD_TEST' || true)
[[ "$add_count" -ge 1 ]] && pass "detected new paths to test ($add_count)" || fail "ADD_TEST count: got $add_count"

# ═══════════════════════════════════
# 8. help
# ═══════════════════════════════════
echo ""
echo "8. help command"
result=$(bash "$SCRIPT" help 2>/dev/null)
echo "$result" | grep -q "detect-runner" && pass "help shows detect-runner" || fail "help missing detect-runner"
echo "$result" | grep -q "path-map" && pass "help shows path-map" || fail "help missing path-map"
echo "$result" | grep -q "path-diff" && pass "help shows path-diff" || fail "help missing path-diff"

# ═══════════════════════════════════
# 9. unknown command
# ═══════════════════════════════════
echo ""
echo "9. unknown command"
exit_code=0
bash "$SCRIPT" nonexistent 2>/dev/null || exit_code=$?
[[ "$exit_code" -ne 0 ]] && pass "unknown command exits non-zero" || fail "unknown command: exit code $exit_code"

# ═══════════════════════════════════
# Summary
# ═══════════════════════════════════
echo ""
echo "──────────────────────────────"
if [[ $FAILS -gt 0 ]]; then
  echo -e "${RED}$FAILS test(s) failed${RST}, $SKIPS skipped"
  exit 1
else
  echo -e "${GRN}All tests passed${RST}, $SKIPS skipped"
  exit 0
fi
