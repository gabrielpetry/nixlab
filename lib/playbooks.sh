#!/usr/bin/env bash
# shellcheck disable=SC2329

set -euo pipefail

GIT_ROOT="$(git rev-parse --show-toplevel)"

if [[ -z "${__BSD_LIBRARY_NAME:-}" ]]; then
    # shellcheck source=lib/bash-command-core/lib/bash-simple-doc.sh
    source "$GIT_ROOT/lib/bash-command-core/lib/bash-simple-doc.sh"
fi

# shellcheck source=lib/inventory.sh
source "$GIT_ROOT/lib/inventory.sh"

if [[ -f "$GIT_ROOT/lib/local/playbooks.sh" ]]; then
    # shellcheck source=local/playbooks.sh
    source "$GIT_ROOT/lib/local/playbooks.sh"
fi

function vm01 {
    @doc "Full setup for vm01"
    log_info "Checking if NixOS is installed on vm01"
    vagrant ssh vm01 -c 'env' 2>&1 | grep -q NIX_PROFILES || {
        log_info "NixOS is not installed on vm01, deploying..."
        vm_deploy --vm vm01 --ssh-port 22101 --install
        sleep 5
        log_info "Waiting for ssh to be ready on vm01"
        until vagrant ssh vm01 -c 'echo "SSH is ready"' 2>/dev/null; do
            sleep 1
        done
    }
    log_info "Rebuilding NixOS on vm01"
    vm_deploy --vm vm01 --ssh-port 22101 --rebuild && sleep 5

}

# If this script is run directly, execute the main function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    @main "$@"
fi
