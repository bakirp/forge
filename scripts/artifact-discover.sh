#!/usr/bin/env bash
set -euo pipefail

# Usage: ./scripts/artifact-discover.sh [type]
# Types: all, architecture, review, verify, debug, browse, brainstorm, runs, releases
# Lists all artifacts found under .forge/ with their status/date

TYPE="${1:-all}"
FORGE_LOCAL=".forge"

if [ ! -d "$FORGE_LOCAL" ]; then
    echo "No .forge/ directory found in the current project."
    exit 0
fi

list_type() {
    local kind="$1" dir="$2" pattern="$3"
    local found=false
    if [ -d "$dir" ]; then
        for f in $dir/$pattern; do
            [ -e "$f" ] || continue
            found=true
            local mod
            mod=$(stat -f "%Sm" -t "%Y-%m-%d %H:%M" "$f" 2>/dev/null \
               || stat -c "%y" "$f" 2>/dev/null | cut -d. -f1)
            printf "  %-14s %-50s %s\n" "[$kind]" "$f" "$mod"
        done
    fi
    $found || return 1
}

show() {
    local kind="$1"
    case "$kind" in
        architecture) list_type "arch"       "$FORGE_LOCAL/architecture" "*.md" ;;
        review)       list_type "review"     "$FORGE_LOCAL/review"       "report.md" ;;
        verify)       list_type "verify"     "$FORGE_LOCAL/verify"       "report.md" ;;
        debug)        list_type "debug"      "$FORGE_LOCAL/debug"        "report.md" ;;
        browse)       list_type "browse"     "$FORGE_LOCAL/browse"       "report.md" ;;
        brainstorm)   list_type "brainstorm" "$FORGE_LOCAL/brainstorm"   "*.md" ;;
        runs)         list_type "run"        "$FORGE_LOCAL/runs"         "*/manifest.json" ;;
        releases)     list_type "release"    "$FORGE_LOCAL/releases"     "*/summary.md" ;;
        *) echo "Unknown type: $kind" >&2; return 1 ;;
    esac
}

echo "FORGE Artifacts"
echo "==============="
found_any=false

ALL_TYPES="architecture review verify debug browse brainstorm runs releases"
if [ "$TYPE" = "all" ]; then
    for t in $ALL_TYPES; do
        show "$t" 2>/dev/null && found_any=true
    done
else
    show "$TYPE" 2>/dev/null && found_any=true
fi

if ! $found_any; then
    echo "  No artifacts found."
fi
