#!/usr/bin/env bash
set -euo pipefail

source "$(dirname "$0")/lib/colors.sh"
source "$(dirname "$0")/lib/json-helpers.sh"

# --- detect-runner: expanded test framework detection ---
# Usage: quality-gate.sh detect-runner [project-root]
cmd_detect_runner() {
  local root="${1:-.}"

  # Priority 1: explicit config override
  # WARNING: commands from .forge/config.json are executed via eval.
  # Only trust this file if you created it yourself.
  local tc=""
  tc=$(read_forge_config "$root" "test_command" 2>/dev/null || true)
  if [[ -n "$tc" ]]; then
    echo -e "${YELLOW}WARN${NC} Using test command from .forge/config.json: $tc" >&2
    echo "$tc"
    return 0
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
    deps=$(get_package_deps "$root")
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

  # Config override — WARNING: commands from .forge/config.json are executed via eval.
  # Only trust this file if you created it yourself. A malicious PR could inject commands.
  local cc=""
  cc=$(read_forge_config "$root" "coverage_command" 2>/dev/null || true)
  if [[ -n "$cc" ]]; then
    echo -e "${YELLOW}WARN${NC} Using coverage command from .forge/config.json: $cc" >&2
    echo -e "${YELLOW}WARN${NC} Verify this is safe before proceeding." >&2
    echo "$cc"
    return 0
  fi

  local test_cmd
  test_cmd=$(cmd_detect_runner "$root")

  # JS/TS ecosystem
  if [[ -f "$root/package.json" ]]; then
    local deps=""
    deps=$(get_package_deps "$root")

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
  if [[ -z "$threshold" ]]; then
    threshold=$(read_forge_config "$root" "coverage_threshold" 2>/dev/null || true)
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

  # Phase 1: Build a hash index of all blocks across all input files.
  # Each entry maps hash -> "filepath:line_num". Duplicates share a hash.
  local hash_index
  hash_index=$(mktemp)
  trap "rm -f '$hash_index'" RETURN

  for file in "$@"; do
    [[ -f "$root/$file" ]] || [[ -f "$file" ]] || continue
    local filepath="$file"
    [[ -f "$root/$file" ]] && filepath="$root/$file"

    local total_lines
    total_lines=$(wc -l < "$filepath" 2>/dev/null || echo 0)
    [[ "$total_lines" -lt "$block_size" ]] && continue

    # Use overlapping windows (step=1) for thorough detection
    local line_num=1
    while [[ $line_num -le $((total_lines - block_size + 1)) ]]; do
      local block
      block=$(sed -n "${line_num},$((line_num + block_size - 1))p" "$filepath" | sed 's/^[[:space:]]*//' | grep -v '^$' | grep -v '^[[:space:]]*$')

      local non_empty
      non_empty=$(echo "$block" | grep -c '[^[:space:]]' || true)
      if [[ "$non_empty" -ge 3 ]]; then
        local hash
        hash=$(echo "$block" | shasum | cut -d' ' -f1)
        printf '%s|%s:%s\n' "$hash" "$filepath" "$line_num" >> "$hash_index"
      fi

      line_num=$((line_num + 1))
    done
  done

  # Phase 2: Find hashes that appear in multiple distinct files
  local prev_hash="" prev_file="" prev_loc="" is_dup=false
  while IFS='|' read -r hash loc; do
    local cur_file="${loc%%:*}"

    if [[ "$hash" == "$prev_hash" && "$cur_file" != "$prev_file" ]]; then
      if ! $is_dup; then
        local first_line
        first_line=$(sed -n "${prev_loc##*:}p" "$prev_file" 2>/dev/null | sed 's/^[[:space:]]*//')
        echo "DUPLICATE|${prev_loc}|block_hash=$hash"
        echo "  First line: $first_line"
        echo "  Also found in:"
        is_dup=true
      fi
      echo "    - $loc"
      duplicates_found=$((duplicates_found + 1))
    else
      is_dup=false
    fi

    prev_hash="$hash"
    prev_file="$cur_file"
    prev_loc="$loc"
  done < <(sort "$hash_index")

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
    local in_multiline_comment=false
    local func_name="global"
    local line_num=0

    # Function/method detection patterns (constants, declared outside loop)
    local _re_js_func='^(export[[:space:]]+)?(async[[:space:]]+)?function[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)'
    local _re_js_const='^(export[[:space:]]+)?(const|let|var)[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*='
    local _re_js_method='^([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*\('
    local _re_go_func='^func[[:space:]]+([(][^)]+[)][[:space:]]+)?([a-zA-Z_][a-zA-Z0-9_]*)'
    local _re_access='^(public|private|protected)[[:space:]]+.*[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)[[:space:]]*[(]'
    local _re_php_func='^(public|private|protected)?[[:space:]]*(static[[:space:]]+)?function[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*)'

    # Branching construct detection patterns
    local _re_if='^(if|[}] else if|elif|elsif|else if)[[:space:](]'
    local _re_else='^([}][[:space:]]*)?(else)[[:space:]:}{]*$'
    local _re_loop='^(for|while|do|loop|until)[[:space:](]'
    local _re_catch='^([}]?[[:space:]]*)?(catch|except|rescue)[[:space:](]'
    local _re_guard='^[[:space:]]*(if|unless).*[[:space:]](return|throw|raise|panic|exit)'
    local _re_ternary='[?][[:space:]]*[^?]+:'
    local _re_type_annot='^[[:space:]]*(type|interface)[[:space:]]'

    while IFS= read -r line; do
      line_num=$((line_num + 1))

      local trimmed="${line#"${line%%[![:space:]]*}"}"
      [[ -z "$trimmed" ]] && continue

      # Track multi-line comments (/* ... */)
      if $in_multiline_comment; then
        [[ "$trimmed" == *"*/"* ]] && in_multiline_comment=false
        continue
      fi
      if [[ "$trimmed" == "/*"* ]]; then
        [[ "$trimmed" != *"*/"* ]] && in_multiline_comment=true
        continue
      fi

      # Skip single-line comments
      [[ "$trimmed" == "//"* ]] && continue
      [[ "$trimmed" == "#"* && "$lang" != "csharp" ]] && continue
      [[ "$trimmed" == "*"* ]] && continue

      # Track current function/method name using bash pattern matching
      case "$lang" in
        js)
          if [[ "$trimmed" =~ $_re_js_func ]]; then
            func_name="${BASH_REMATCH[3]}"
          elif [[ "$trimmed" =~ $_re_js_const ]]; then
            func_name="${BASH_REMATCH[3]}"
          elif [[ "$trimmed" =~ $_re_js_method ]]; then
            func_name="${BASH_REMATCH[1]}"
          fi
          ;;
        python)
          [[ "$trimmed" =~ ^def[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*) ]] && func_name="${BASH_REMATCH[1]}"
          ;;
        go)
          [[ "$trimmed" =~ $_re_go_func ]] && func_name="${BASH_REMATCH[2]}"
          ;;
        rust)
          [[ "$trimmed" =~ ^(pub[[:space:]]+)?fn[[:space:]]+([a-zA-Z_][a-zA-Z0-9_]*) ]] && func_name="${BASH_REMATCH[2]}"
          ;;
        java|csharp)
          [[ "$trimmed" =~ $_re_access ]] && func_name="${BASH_REMATCH[2]}"
          ;;
        ruby)
          [[ "$trimmed" =~ ^def[[:space:]]+([a-zA-Z_][a-zA-Z0-9_?!]*) ]] && func_name="${BASH_REMATCH[1]}"
          ;;
        php)
          [[ "$trimmed" =~ $_re_php_func ]] && func_name="${BASH_REMATCH[3]}"
          ;;
      esac

      # Detect branching constructs
      local path_type="" path_desc=""

      if [[ "$trimmed" =~ $_re_if ]]; then
        path_counter=$((path_counter + 1))
        path_type="if"
        local condition="${trimmed:${#BASH_REMATCH[0]}}"
        condition="${condition%%\{*}"
        condition="${condition:0:60}"
        path_desc="${func_name} — if: ${condition}"
      elif [[ "$trimmed" =~ $_re_else ]]; then
        path_counter=$((path_counter + 1))
        path_type="else"
        path_desc="${func_name} — else branch"
      elif [[ "$trimmed" =~ ^(switch|match)[[:space:]] ]]; then
        path_counter=$((path_counter + 1))
        path_type="switch"
        path_desc="${func_name} — switch/match entry"
      elif [[ "$trimmed" =~ ^(case|when)[[:space:]] ]]; then
        path_counter=$((path_counter + 1))
        local case_val="${trimmed:${#BASH_REMATCH[0]}}"
        case_val="${case_val%%:*}"
        case_val="${case_val%%\{*}"
        case_val="${case_val:0:40}"
        path_type="switch-case"
        path_desc="${func_name} — case: ${case_val}"
      elif [[ "$trimmed" =~ ^default[[:space:]]*: ]]; then
        path_counter=$((path_counter + 1))
        path_type="switch-default"
        path_desc="${func_name} — default case"
      elif [[ "$trimmed" =~ $_re_loop ]]; then
        path_counter=$((path_counter + 1))
        path_type="loop"
        path_desc="${func_name} — loop: ${trimmed:0:60}"
      elif [[ "$trimmed" == try* ]] || [[ "$trimmed" =~ ^begin$ ]]; then
        path_counter=$((path_counter + 1))
        path_type="try"
        path_desc="${func_name} — try (happy path)"
      elif [[ "$trimmed" =~ $_re_catch ]]; then
        path_counter=$((path_counter + 1))
        local exc_type="${trimmed#*${BASH_REMATCH[2]}}"
        exc_type="${exc_type#[[:space:](]}"
        exc_type="${exc_type%%[)\{:]*}"
        exc_type="${exc_type:0:40}"
        path_type="catch"
        path_desc="${func_name} — catch: ${exc_type}"
      elif [[ "$trimmed" =~ $_re_guard ]]; then
        path_counter=$((path_counter + 1))
        path_type="guard"
        path_desc="${func_name} — early return/guard"
      # Ternary — exclude TypeScript type annotations
      elif [[ "$lang" != "python" && "$trimmed" == *"?"*":"* ]] && ! [[ "$trimmed" =~ $_re_type_annot ]] && [[ "$trimmed" =~ $_re_ternary ]]; then
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
