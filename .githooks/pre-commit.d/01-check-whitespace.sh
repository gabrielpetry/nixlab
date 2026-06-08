#!/usr/bin/env bash
# Pre-commit hook: check for trailing whitespace in staged files.

set -euo pipefail

# Get the list of staged files (only those that exist and are text-like)
files="$(git diff --cached --name-only --diff-filter=ACM | grep -v '\.\(png\|jpg\|gif\|ico\|zip\|tar\.gz\)$' || true)"

if [ -z "$files" ]; then
    exit 0
fi

# Check for trailing whitespace
bad="$(echo "$files" | xargs grep -l '[[:space:]]$' 2>/dev/null || true)"

if [ -n "$bad" ]; then
    echo "✗ Trailing whitespace found in:"
    echo "$bad"
    echo "Please remove trailing whitespace before committing."
    exit 1
fi
