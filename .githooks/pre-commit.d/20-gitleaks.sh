#!/usr/bin/env bash

set -euo pipefail

if [ ! -f .githooks/_bin/gitleaks ]; then
    wget https://github.com/gitleaks/gitleaks/releases/download/v${gitleaks_version}/gitleaks_${gitleaks_version}_linux_x64.tar.gz -O - 2>/dev/null | tar -xz -C .githooks/_bin/ gitleaks
    chmod +x .githooks/_bin/gitleaks
fi

.githooks/_bin/gitleaks detect --no-git --source . -v