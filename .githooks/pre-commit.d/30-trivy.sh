#!/usr/bin/env bash

set -euo pipefail

if [ ! -f .githooks/_bin/trivy ]; then
    wget https://github.com/aquasecurity/trivy/releases/download/v${trivy_version}/trivy_${trivy_version}_Linux-64bit.tar.gz -O - 2>/dev/null | tar -xz -C .githooks/_bin/ trivy
    chmod +x .githooks/_bin/trivy
fi

.githooks/_bin/trivy fs --exit-code 1 --severity HIGH,CRITICAL --no-progress --scanners vuln,misconfig,secret,license .
