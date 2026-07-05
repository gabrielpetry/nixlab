#!/usr/bin/env bash

set -euo pipefail

if [ ! -f .githooks/_bin/trivy ]; then
    wget https://github.com/aquasecurity/trivy/releases/download/v${trivy_version}/trivy_${trivy_version}_Linux-64bit.tar.gz -O - 2>/dev/null | tar -xz -C .githooks/_bin/ trivy
    chmod +x .githooks/_bin/trivy
fi

mapfile -t files < <(grep -v '^$' "$staged_files" || true)

if [ "${#files[@]}" -eq 0 ]; then
    exit 0
fi

snapshot=$(mktemp -d)
trap 'rm -rf "$snapshot"' EXIT

git checkout-index --stdin --prefix="$snapshot/" < "$staged_files"

.githooks/_bin/trivy fs --exit-code 1 --severity HIGH,CRITICAL --no-progress --scanners vuln,misconfig,secret,license "$snapshot"
