#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'; RED='\033[0;31m'; YELLOW='\033[0;33m'; CYAN='\033[0;36m'; NC='\033[0m'

# --- detect-runner: expanded test framework detection ---
# Usage: quality-gate.sh detect-runner [project-root]
cmd_detect_runner() {
  local root="${1:-.}"

  # Priority 1: explicit config override
  if [[ -f "$root/.forge/config.json" ]]; then
    local tc=""
    if command -v jq &>/dev/null; then
      tc=$(jq -r '.test_command // empty' "$root/.forge/config.json" 2>/dev/null)
    else
      tc=$(python3 -c "import json; d=json.load(open('$root/.forge/config.json')); print(d.get('test_command',''))" 2>/dev/null || true)
    fi
    if [[ -n "$tc" ]]; then
      echo "$tc"
      return 0
    fi
  fi

  # Priority 2: package.json scripts.test
  if [[ -f "$root/package.json" ]]; then
    local test_cmd=""
    if command -v jq &>/dev/null; then
      test_cmd=$(jq -r '.scripts.test // empty' "$root/package.json" 2>/dev/null)
    else
      test_cmd=$(python3 -c "import json; d=json.load(open('$root/package.json')); print(d.get('scripts',{}).get('test',''))" 2>/dev/null || true)
    fi
    if [[ -n "$test_cmd" ]]; then
      echo "$test_cmd"
      return 0
    fi
  fi

  # Priority 3: auto-detect by config files

  # JS/TS ecosystem
  if [[ -f "$root/bun.lockb" ]]; then
    echo "bun test"; return 0
  fi
  if ls "$root"/vitest.config.* &>/dev/null 2>&1; then
    echo "npx vitest run"; return 0
  fi
  if ls "$root"/jest.config.* &>/dev/null 2>&1; then
    echo "npx jest"; return 0
  fi
  if [[ -f "$root/package.json" ]]; then
    local deps=""
    if command -v jq &>/dev/null; then
      deps=$(jq -r '(.dependencies // {}) + (.devDependencies // {}) | keys[]' "$root/package.json" 2>/dev/null || true)
    else
      deps=$(python3 -c "
import json; d=json.load(open('$root/package.json'))
m=dict(d.get('dependencies',{})); m.update(d.get('devDependencies',{}))
for k in m: print(k)" 2>/dev/null || true)
    fi
    if echo "$deps" | grep -q '^jest$'; then
      echo "npx jest"; return 0
    fi
    if echo "$deps" | grep -q '^mocha$'; then
      echo "npx mocha"; return 0
    fi
  fi
  if ls "$root"/.mocharc.* &>/dev/null 2>&1; then
    echo "npx mocha"; return 0
  fi
  if ls "$root"/cypress.config.* &>/dev/null 2>&1; then
    echo "npx cypress run"; return 0
  fi
  if ls "$root"/playwright.config.* &>/dev/null 2>&1; then
    echo "npx playwright test"; return 0
  fi

  # Python
  if [[ -f "$root/pytest.ini" ]]; then
    echo "pytest"; return 0
  fi
  if [[ -f "$root/setup.cfg" ]] && grep -q '\[tool:pytest\]' "$root/setup.cfg" 2>/dev/null; then
    echo "pytest"; return 0
  fi
  if [[ -f "$root/pyproject.toml" ]] && grep -q '\[tool\.pytest' "$root/pyproject.toml" 2>/dev/null; then
    echo "pytest"; return 0
  fi

  # Go
  if [[ -f "$root/go.mod" ]]; then
    echo "go test ./..."; return 0
  fi

  # Rust
  if [[ -f "$root/Cargo.toml" ]]; then
    echo "cargo test"; return 0
  fi

  # Java/Kotlin — Maven
  if [[ -f "$root/pom.xml" ]]; then
    echo "mvn test"; return 0
  fi

  # Java/Kotlin — Gradle
  if [[ -f "$root/build.gradle" ]] || [[ -f "$root/build.gradle.kts" ]]; then
    echo "./gradlew test"; return 0
  fi

  # Ruby
  if [[ -f "$root/Gemfile" ]]; then
    if [[ -f "$root/.rspec" ]] || [[ -d "$root/spec" ]]; then
      echo "bundle exec rspec"; return 0
    fi
    if [[ -d "$root/test" ]]; then
      echo "bundle exec rake test"; return 0
    fi
  fi

  # PHP
  if [[ -f "$root/phpunit.xml" ]] || [[ -f "$root/phpunit.xml.dist" ]]; then
    echo "./vendor/bin/phpunit"; return 0
  fi

  # .NET
  if ls "$root"/*.csproj &>/dev/null 2>&1; then
    echo "dotnet test"; return 0
  fi
  if ls "$root"/**/*.csproj &>/dev/null 2>&1; then
    echo "dotnet test"; return 0
  fi

  echo "unknown"
}

# --- detect-coverage: coverage tool detection ---
# Usage: quality-gate.sh detect-coverage [project-root]
cmd_detect_coverage() {
  local root="${1:-.}"

  # Config override
  if [[ -f "$root/.forge/config.json" ]]; then
    local cc=""
    if command -v jq &>/dev/null; then
      cc=$(jq -r '.coverage_command // empty' "$root/.forge/config.json" 2>/dev/null)
    else
      cc=$(python3 -c "import json; d=json.load(open('$root/.forge/config.json')); print(d.get('coverage_command',''))" 2>/dev/null || true)
    fi
    if [[ -n "$cc" ]]; then
      echo "$cc"
      return 0
    fi
  fi

  local test_cmd
  test_cmd=$(cmd_detect_runner "$root")

  # JS/TS ecosystem
  if [[ -f "$root/package.json" ]]; then
    local deps=""
    if command -v jq &>/dev/null; then
      deps=$(jq -r '(.dependencies // {}) + (.devDependencies // {}) | keys[]' "$root/package.json" 2>/dev/null || true)
    else
      deps=$(python3 -c "
import json; d=json.load(open('$root/package.json'))
m=dict(d.get('dependencies',{})); m.update(d.get('devDependencies',{}))
for k in m: print(k)" 2>/dev/null || true)
    fi

    if ls "$root"/vitest.config.* &>/dev/null 2>&1; then
      echo "npx vitest run --coverage"; return 0
    fi
    if echo "$deps" | grep -q '^c8$'; then
      echo "npx c8 $test_cmd"; return 0
    fi
    if echo "$deps" | grep -q '^nyc$' || [[ -f "$root/.nycrc" ]] || [[ -f "$root/.nycrc.json" ]]; then
      echo "npx nyc --reporter=text $test_cmd"; return 0
    fi
    if ls "$root"/jest.config.* &>/dev/null 2>&1 || echo "$deps" | grep -q '^jest$'; then
      echo "npx jest --coverage"; return 0
    fi
  fi

  # Python
  if [[ -f "$root/pytest.ini" ]] || [[ -f "$root/pyproject.toml" ]] || [[ -f "$root/setup.cfg" ]]; then
    if [[ -f "$root/pyproject.toml" ]] && grep -q 'coverage' "$root/pyproject.toml" 2>/dev/null; then
      echo "coverage run -m pytest && coverage report"; return 0
    fi
    if [[ -f "$root/requirements.txt" ]] && grep -q 'coverage' "$root/requirements.txt" 2>/dev/null; then
      echo "coverage run -m pytest && coverage report"; return 0
    fi
    # Default: pytest-cov is common
    echo "pytest --cov"; return 0
  fi

  # Go
  if [[ -f "$root/go.mod" ]]; then
    echo "go test -cover ./..."; return 0
  fi

  # Rust
  if [[ -f "$root/Cargo.toml" ]]; then
    if command -v cargo-tarpaulin &>/dev/null; then
      echo "cargo tarpaulin"; return 0
    fi
    echo "cargo test"; return 0
  fi

  # Java — Maven with JaCoCo
  if [[ -f "$root/pom.xml" ]]; then
    if grep -q 'jacoco' "$root/pom.xml" 2>/dev/null; then
      echo "mvn test jacoco:report"; return 0
    fi
    echo "mvn test"; return 0
  fi

  # Java — Gradle with JaCoCo
  if [[ -f "$root/build.gradle" ]] || [[ -f "$root/build.gradle.kts" ]]; then
    local gradle_file="$root/build.gradle"
    [[ -f "$root/build.gradle.kts" ]] && gradle_file="$root/build.gradle.kts"
    if grep -q 'jacoco' "$gradle_file" 2>/dev/null; then
      echo "./gradlew test jacocoTestReport"; return 0
    fi
    echo "./gradlew test"; return 0
  fi

  # Ruby with SimpleCov
  if [[ -f "$root/Gemfile" ]]; then
    if grep -q 'simplecov' "$root/Gemfile" 2>/dev/null; then
      echo "bundle exec rspec"; return 0
    fi
    echo "bundle exec rspec"; return 0
  fi

  # PHP
  if [[ -f "$root/phpunit.xml" ]] || [[ -f "$root/phpunit.xml.dist" ]]; then
    echo "./vendor/bin/phpunit --coverage-text"; return 0
  fi

  # .NET
  if ls "$root"/*.csproj &>/dev/null 2>&1 || ls "$root"/**/*.csproj &>/dev/null 2>&1; then
    echo "dotnet test --collect:\"XPlat Code Coverage\""; return 0
  fi

  echo "unknown"
}

# --- coverage: run coverage and enforce threshold ---
# Usage: quality-gate.sh coverage [project-root] [--threshold N]
cmd_coverage() {
  local root="."
  local threshold=""

  while [[ $# -gt 0 ]]; do
    case "$1" in
      --threshold)
        threshold="$2"
        shift 2
        ;;
      *)
        root="$1"
        shift
        ;;
    esac
  done

  # Read threshold from config if not provided via flag
  if [[ -z "$threshold" ]] && [[ -f "$root/.forge/config.json" ]]; then
    if command -v jq &>/dev/null; then
      threshold=$(jq -r '.coverage_threshold // empty' "$root/.forge/config.json" 2>/dev/null)
    else
      threshold=$(python3 -c "import json; d=json.load(open('$root/.forge/config.json')); print(d.get('coverage_threshold',''))" 2>/dev/null || true)
    fi
  fi

  local cov_cmd
  cov_cmd=$(cmd_detect_coverage "$root")

  if [[ "$cov_cmd" == "unknown" ]]; then
    echo "coverage_tool=unknown"
    echo "coverage=N/A"
    echo "threshold=${threshold:-none}"
    echo "status=NOT_MEASURED"
    echo -e "${YELLOW}WARN${NC} No coverage tool detected" >&2
    return 0
  fi

  echo -e "${CYAN}Running${NC} $cov_cmd" >&2

  local output
  local exit_code=0
  output=$(cd "$root" && eval "$cov_cmd" 2>&1) || exit_code=$?

  # Parse coverage percentage from output
  # Common patterns: "XX%" or "XX.XX%" or "TOTAL ... XX%"
  local pct=""
  pct=$(echo "$output" | grep -oE '[0-9]+(\.[0-9]+)?%' | tail -1 | tr -d '%')

  if [[ -z "$pct" ]]; then
    echo "coverage_tool=$cov_cmd"
    echo "coverage=unknown"
    echo "threshold=${threshold:-none}"
    echo "status=NOT_MEASURED"
    echo -e "${YELLOW}WARN${NC} Could not parse coverage percentage from output" >&2
    echo "$output" >&2
    return 0
  fi

  echo "coverage_tool=$cov_cmd"
  echo "coverage=${pct}%"
  echo "threshold=${threshold:-none}"

  if [[ -n "$threshold" ]]; then
    # Compare using awk for float comparison
    local passed
    passed=$(awk "BEGIN { print ($pct >= $threshold) ? 1 : 0 }")
    if [[ "$passed" == "1" ]]; then
      echo "status=PASS"
      echo -e "${GREEN}PASS${NC} Coverage ${pct}% >= threshold ${threshold}%" >&2
      return 0
    else
      echo "status=FAIL"
      echo -e "${RED}FAIL${NC} Coverage ${pct}% < threshold ${threshold}%" >&2
      return 1
    fi
  else
    echo "status=PASS"
    echo -e "${GREEN}PASS${NC} Coverage ${pct}% (no threshold configured)" >&2
    return 0
  fi
}

# --- reusability-search: find existing reusable code ---
# Usage: quality-gate.sh reusability-search [root] [pattern...]
cmd_reusability_search() {
  local root="${1:-.}"
  shift || true

  if [[ $# -eq 0 ]]; then
    echo -e "${YELLOW}WARN${NC} No search patterns provided" >&2
    echo "No patterns to search for."
    return 0
  fi

  local found=0
  for pattern in "$@"; do
    echo "--- Searching for: $pattern ---"

    # Search for function/method/class definitions matching the pattern
    # Supports JS/TS, Python, Go, Rust, Java, Ruby, PHP
    local results=""
    results=$(grep -rnE \
      "(function\s+${pattern}|const\s+${pattern}\s*=|def\s+${pattern}|func\s+${pattern}|fn\s+${pattern}|class\s+${pattern}|public\s+.*\s+${pattern}\s*\(|private\s+.*\s+${pattern}\s*\(|protected\s+.*\s+${pattern}\s*\()" \
      "$root" \
      --include="*.js" --include="*.ts" --include="*.tsx" --include="*.jsx" \
      --include="*.py" --include="*.go" --include="*.rs" \
      --include="*.java" --include="*.kt" --include="*.rb" --include="*.php" \
      --include="*.cs" --include="*.swift" \
      2>/dev/null || true)

    if [[ -n "$results" ]]; then
      echo "$results"
      found=$((found + 1))
    else
      echo "(no matches)"
    fi
  done

  if [[ $found -gt 0 ]]; then
    echo -e "${GREEN}Found${NC} $found pattern(s) with existing implementations" >&2
  else
    echo -e "${CYAN}INFO${NC} No existing implementations found for given patterns" >&2
  fi
  return 0
}

# --- dry-check: detect duplicate code blocks ---
# Usage: quality-gate.sh dry-check [root] [files...]
cmd_dry_check() {
  local root="${1:-.}"
  shift || true

  if [[ $# -eq 0 ]]; then
    echo -e "${YELLOW}WARN${NC} No files provided for DRY check" >&2
    echo "No files to check."
    return 0
  fi

  local block_size=5
  local duplicates_found=0

  echo "--- DRY Check (minimum ${block_size}-line duplicate blocks) ---"

  for file in "$@"; do
    [[ -f "$root/$file" ]] || [[ -f "$file" ]] || continue
    local filepath="$file"
    [[ -f "$root/$file" ]] && filepath="$root/$file"

    # Extract consecutive line blocks and hash them
    local total_lines
    total_lines=$(wc -l < "$filepath" 2>/dev/null || echo 0)

    if [[ "$total_lines" -lt "$block_size" ]]; then
      continue
    fi

    # Generate fingerprints for each block of N consecutive lines
    local line_num=1
    while [[ $line_num -le $((total_lines - block_size + 1)) ]]; do
      local block
      block=$(sed -n "${line_num},$((line_num + block_size - 1))p" "$filepath" | sed 's/^[[:space:]]*//' | grep -v '^$' | grep -v '^[[:space:]]*$')

      # Skip blocks that are mostly empty or trivial
      local non_empty
      non_empty=$(echo "$block" | grep -c '[^[:space:]]' || true)
      if [[ "$non_empty" -ge 3 ]]; then
        local hash
        hash=$(echo "$block" | shasum | cut -d' ' -f1)

        # Search for this block in other project files
        local other_files
        other_files=$(grep -rlF "$(echo "$block" | head -1)" "$root" \
          --include="*.js" --include="*.ts" --include="*.py" --include="*.go" \
          --include="*.rs" --include="*.java" --include="*.kt" --include="*.rb" \
          --include="*.php" --include="*.cs" \
          2>/dev/null | grep -v "$filepath" | head -3 || true)

        if [[ -n "$other_files" ]]; then
          echo "DUPLICATE|$filepath:$line_num|block_hash=$hash"
          echo "  First line: $(echo "$block" | head -1)"
          echo "  Also found in:"
          echo "$other_files" | while read -r f; do echo "    - $f"; done
          duplicates_found=$((duplicates_found + 1))
        fi
      fi

      line_num=$((line_num + block_size))
    done
  done

  if [[ $duplicates_found -gt 0 ]]; then
    echo -e "${YELLOW}WARN${NC} Found $duplicates_found potential duplicate block(s)" >&2
  else
    echo -e "${GREEN}PASS${NC} No duplicate blocks detected" >&2
  fi
  echo "duplicates_found=$duplicates_found"
  return 0
}

# --- path-map: extract condition paths from source files ---
# Usage: quality-gate.sh path-map [root] [files...]
cmd_path_map() {
  local root="${1:-.}"
  shift || true

  if [[ $# -eq 0 ]]; then
    echo -e "${YELLOW}WARN${NC} No files provided for path mapping" >&2
    echo "No files to map."
    return 0
  fi

  local total_paths=0

  for file in "$@"; do
    local filepath="$file"
    [[ -f "$root/$file" ]] && filepath="$root/$file"
    [[ -f "$filepath" ]] || continue

    # Detect language from extension
    local lang=""
    case "$filepath" in
      *.js|*.jsx|*.ts|*.tsx|*.mjs|*.cjs) lang="js" ;;
      *.py) lang="python" ;;
      *.go) lang="go" ;;
      *.rs) lang="rust" ;;
      *.java|*.kt|*.kts) lang="java" ;;
      *.rb) lang="ruby" ;;
      *.php) lang="php" ;;
      *.cs) lang="csharp" ;;
      *) continue ;;
    esac

    # Extract the base name for path IDs
    local base
    base=$(basename "$filepath" | sed 's/\.[^.]*$//')

    local path_counter=0
    local in_block=0
    local func_name="global"
    local line_num=0

    while IFS= read -r line; do
      line_num=$((line_num + 1))

      # Skip comments and empty lines
      local trimmed
      trimmed=$(echo "$line" | sed 's/^[[:space:]]*//')
      [[ -z "$trimmed" ]] && continue
      [[ "$trimmed" == "//"* ]] && continue
      [[ "$trimmed" == "#"* && "$lang" != "csharp" ]] && continue
      [[ "$trimmed" == "/*"* ]] && continue
      [[ "$trimmed" == "*"* ]] && continue

      # Track current function/method name
      local new_func=""
      case "$lang" in
        js)
          new_func=$(echo "$trimmed" | grep -oE '(function\s+\w+|const\s+\w+\s*=\s*(async\s+)?\(|(\w+)\s*\(.*\)\s*\{)' | head -1 | grep -oE '\w+' | head -1 || true)
          ;;
        python)
          new_func=$(echo "$trimmed" | grep -oE 'def\s+\w+' | sed 's/def //' || true)
          ;;
        go)
          new_func=$(echo "$trimmed" | grep -oE 'func\s+(\(\w+\s+\*?\w+\)\s+)?\w+' | grep -oE '\w+$' || true)
          ;;
        rust)
          new_func=$(echo "$trimmed" | grep -oE 'fn\s+\w+' | sed 's/fn //' || true)
          ;;
        java)
          new_func=$(echo "$trimmed" | grep -oE '(public|private|protected)\s+.*\s+\w+\s*\(' | grep -oE '\w+\s*\(' | sed 's/(//' || true)
          ;;
        ruby)
          new_func=$(echo "$trimmed" | grep -oE 'def\s+\w+' | sed 's/def //' || true)
          ;;
        php)
          new_func=$(echo "$trimmed" | grep -oE 'function\s+\w+' | sed 's/function //' || true)
          ;;
        csharp)
          new_func=$(echo "$trimmed" | grep -oE '(public|private|protected)\s+.*\s+\w+\s*\(' | grep -oE '\w+\s*\(' | sed 's/(//' || true)
          ;;
      esac
      [[ -n "$new_func" ]] && func_name="$new_func"

      # Detect branching constructs
      local path_type="" path_desc=""

      # if/else if/elif/elsif
      if echo "$trimmed" | grep -qE '^(if|} else if|elif|elsif|else if)\b'; then
        path_counter=$((path_counter + 1))
        path_type="if"
        local condition
        condition=$(echo "$trimmed" | sed 's/^[^(]*(//;s/)[^)]*$//;s/{$//' | head -c 60)
        path_desc="${func_name} — if: ${condition}"
      elif echo "$trimmed" | grep -qE '^(} else|else:?|else\b)'; then
        path_counter=$((path_counter + 1))
        path_type="else"
        path_desc="${func_name} — else branch"
      # switch/case/match/when
      elif echo "$trimmed" | grep -qE '^(switch|match)\b'; then
        path_counter=$((path_counter + 1))
        path_type="switch"
        path_desc="${func_name} — switch/match entry"
      elif echo "$trimmed" | grep -qE '^(case|when)\b'; then
        path_counter=$((path_counter + 1))
        local case_val
        case_val=$(echo "$trimmed" | sed 's/^case\s*//;s/^when\s*//;s/:.*//;s/{.*//' | head -c 40)
        path_type="switch-case"
        path_desc="${func_name} — case: ${case_val}"
      elif echo "$trimmed" | grep -qE '^default\s*:'; then
        path_counter=$((path_counter + 1))
        path_type="switch-default"
        path_desc="${func_name} — default case"
      # loops
      elif echo "$trimmed" | grep -qE '^(for|while|do|loop|until)\b'; then
        path_counter=$((path_counter + 1))
        path_type="loop"
        local loop_cond
        loop_cond=$(echo "$trimmed" | head -c 60)
        path_desc="${func_name} — loop: ${loop_cond}"
      # try/catch/except/rescue
      elif echo "$trimmed" | grep -qE '^try\b|^begin\b'; then
        path_counter=$((path_counter + 1))
        path_type="try"
        path_desc="${func_name} — try (happy path)"
      elif echo "$trimmed" | grep -qE '^(\}?\s*)?(catch|except|rescue)\b'; then
        path_counter=$((path_counter + 1))
        local exc_type
        exc_type=$(echo "$trimmed" | sed 's/^catch\s*//;s/^except\s*//;s/^rescue\s*//;s/{.*//;s/:.*//;s/(//;s/)//' | head -c 40)
        path_type="catch"
        path_desc="${func_name} — catch: ${exc_type}"
      # guard/early return
      elif echo "$trimmed" | grep -qE '^\s*(if|unless).*\b(return|throw|raise|panic|exit)\b'; then
        path_counter=$((path_counter + 1))
        path_type="guard"
        path_desc="${func_name} — early return/guard"
      # ternary (JS/TS/Java/C#)
      elif echo "$trimmed" | grep -qE '\?\s*[^?]+\s*:' && [[ "$lang" != "python" ]]; then
        path_counter=$((path_counter + 1))
        path_type="ternary-true"
        path_desc="${func_name} — ternary true branch"
        echo "${filepath}:${line_num}|${path_type}|${base}_${path_counter}a|${path_desc}"
        path_counter=$((path_counter + 1))
        path_type="ternary-false"
        path_desc="${func_name} — ternary false branch"
        echo "${filepath}:${line_num}|${path_type}|${base}_${path_counter}b|${path_desc}"
        total_paths=$((total_paths + 2))
        continue
      fi

      if [[ -n "$path_type" ]]; then
        local path_id="${base}_${path_counter}"
        echo "${filepath}:${line_num}|${path_type}|${path_id}|${path_desc}"
        total_paths=$((total_paths + 1))
      fi
    done < "$filepath"
  done

  echo -e "${GREEN}Mapped${NC} $total_paths condition path(s)" >&2
  return 0
}

# --- path-diff: change impact analysis for tests ---
# Usage: quality-gate.sh path-diff [root] [base-branch]
cmd_path_diff() {
  local root="${1:-.}"
  local base_branch="${2:-}"

  # Auto-detect default branch if not provided
  if [[ -z "$base_branch" ]]; then
    base_branch=$(cd "$root" && git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@' || echo "main")
  fi

  # Get changed source files (exclude test files)
  local changed_files
  changed_files=$(cd "$root" && git diff --name-only "${base_branch}...HEAD" 2>/dev/null | grep -vE '(test|spec|__test__|_test\.)' || true)

  if [[ -z "$changed_files" ]]; then
    echo -e "${CYAN}INFO${NC} No source file changes detected against $base_branch" >&2
    echo "No changes to analyze."
    return 0
  fi

  local tmpdir
  tmpdir=$(mktemp -d)
  trap "rm -rf $tmpdir" EXIT

  # Get paths from base version
  local base_paths="$tmpdir/base_paths.txt"
  local head_paths="$tmpdir/head_paths.txt"

  # Extract base versions of changed files
  mkdir -p "$tmpdir/base" "$tmpdir/head"
  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    mkdir -p "$tmpdir/base/$(dirname "$file")" "$tmpdir/head/$(dirname "$file")"

    # Get base version
    (cd "$root" && git show "${base_branch}:${file}" 2>/dev/null > "$tmpdir/base/$file") || true

    # Get HEAD version
    if [[ -f "$root/$file" ]]; then
      cp "$root/$file" "$tmpdir/head/$file"
    fi
  done <<< "$changed_files"

  # Map paths for both versions
  local base_file_args=()
  local head_file_args=()
  while IFS= read -r file; do
    [[ -z "$file" ]] && continue
    [[ -f "$tmpdir/base/$file" ]] && base_file_args+=("$file")
    [[ -f "$tmpdir/head/$file" ]] && head_file_args+=("$file")
  done <<< "$changed_files"

  # Run path-map on both versions
  if [[ ${#base_file_args[@]} -gt 0 ]]; then
    cmd_path_map "$tmpdir/base" "${base_file_args[@]}" 2>/dev/null > "$base_paths" || true
  else
    touch "$base_paths"
  fi

  if [[ ${#head_file_args[@]} -gt 0 ]]; then
    cmd_path_map "$tmpdir/head" "${head_file_args[@]}" 2>/dev/null > "$head_paths" || true
  else
    touch "$head_paths"
  fi

  # Compare paths: extract path_type|description as identity key
  # Format: file:line|path_type|path_id|description
  local add_count=0 modify_count=0 remove_count=0 noaction_count=0

  # Check HEAD paths against base
  while IFS='|' read -r location path_type path_id desc; do
    [[ -z "$location" ]] && continue
    local file_part
    file_part=$(echo "$location" | cut -d: -f1)
    # Check if a similar path existed in base (match by path_type + function context)
    local match
    match=$(grep -F "|${path_type}|" "$base_paths" | grep -F "$file_part" | head -1 || true)

    if [[ -n "$match" ]]; then
      # Path existed — check if the content around it changed
      local base_line
      base_line=$(echo "$match" | cut -d'|' -f1 | cut -d: -f2)
      local head_line
      head_line=$(echo "$location" | cut -d: -f2)

      # Simple heuristic: if the line number shifted significantly, likely modified
      local diff=$((head_line - base_line))
      [[ $diff -lt 0 ]] && diff=$((-diff))

      if [[ $diff -gt 5 ]]; then
        echo "MODIFY_TEST|${location}|${path_id}|${desc}"
        modify_count=$((modify_count + 1))
      else
        echo "NO_ACTION|${location}|${path_id}|${desc}"
        noaction_count=$((noaction_count + 1))
      fi
    else
      echo "ADD_TEST|${location}|${path_id}|${desc}"
      add_count=$((add_count + 1))
    fi
  done < "$head_paths"

  # Check for removed paths (in base but not in HEAD)
  while IFS='|' read -r location path_type path_id desc; do
    [[ -z "$location" ]] && continue
    local file_part
    file_part=$(echo "$location" | cut -d: -f1)
    local match
    match=$(grep -F "|${path_type}|" "$head_paths" | grep -F "$file_part" | head -1 || true)

    if [[ -z "$match" ]]; then
      echo "REMOVE_TEST|${location}|${path_id}|${desc}"
      remove_count=$((remove_count + 1))
    fi
  done < "$base_paths"

  echo -e "${GREEN}Analysis${NC} ADD:$add_count MODIFY:$modify_count REMOVE:$remove_count UNCHANGED:$noaction_count" >&2
  return 0
}

# --- help ---
cmd_help() {
  cat <<'USAGE'
Usage: quality-gate.sh <command> [args...]

Commands:
  detect-runner [root]              Detect test framework and output run command
  detect-coverage [root]            Detect coverage tool and output coverage command
  coverage [root] [--threshold N]   Run coverage and enforce threshold (exit 1 if below)
  reusability-search [root] [patterns...]  Search for existing reusable code
  dry-check [root] [files...]       Detect duplicate code blocks
  path-map [root] [files...]        Extract condition paths from source files
  path-diff [root] [base-branch]    Change impact analysis for tests
  help                              Show this help

Config (.forge/config.json):
  test_command       Override test runner command
  coverage_command   Override coverage tool command
  coverage_threshold Coverage percentage threshold (0-100)
USAGE
}

# --- subcommand dispatcher ---
case "${1:-help}" in
  detect-runner)    shift; cmd_detect_runner "$@" ;;
  detect-coverage)  shift; cmd_detect_coverage "$@" ;;
  coverage)         shift; cmd_coverage "$@" ;;
  reusability-search) shift; cmd_reusability_search "$@" ;;
  dry-check)        shift; cmd_dry_check "$@" ;;
  path-map)         shift; cmd_path_map "$@" ;;
  path-diff)        shift; cmd_path_diff "$@" ;;
  help|--help|-h)   cmd_help ;;
  *)
    echo -e "${RED}ERROR${NC} Unknown command: $1" >&2
    cmd_help >&2
    exit 1
    ;;
esac
