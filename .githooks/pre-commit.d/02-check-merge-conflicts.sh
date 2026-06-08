#!/usr/bin/env bash
# Pre-commit hook: check for unresolved merge conflict markers.

set -euo pipefail

files="$(git diff --cached --name-only --diff-filter=ACM || true)"

if [ -z "$files" ]; then
    exit 0
fi

# Grep for conflict markers
bad="$(echo "$files" | xargs grep -ln '^<<<<<<< \|^=======$\|^>>>>>>> ' 2>/dev/null || true)"

if [ -n "$bad" ]; then
    echo "✗ Unresolved merge conflict markers found in:"
    echo "$bad"
    echo "Resolve conflicts before committing."
    exit 1
fi
