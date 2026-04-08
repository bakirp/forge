#!/usr/bin/env bash
set -euo pipefail

# Detect the default branch name for the current repository.
# Usage: bash scripts/detect-branch.sh
# Outputs the branch name (e.g., "main", "master", "develop")

DEFAULT_BRANCH=$(git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's@^refs/remotes/origin/@@') || true

if [[ -z "$DEFAULT_BRANCH" ]]; then
  for candidate in main master develop; do
    if git show-ref --verify --quiet "refs/heads/$candidate" 2>/dev/null || \
       git show-ref --verify --quiet "refs/remotes/origin/$candidate" 2>/dev/null; then
      DEFAULT_BRANCH="$candidate"
      break
    fi
  done
fi

echo "${DEFAULT_BRANCH:-main}"
