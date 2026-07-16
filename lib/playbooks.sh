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

function vm_setup {
    @internal
    @doc "Install, bootstrap BWS, and rebuild a VM"
    @arg "required" "--vm" "Vagrant VM name"
    @arg "required" "--ssh-port" "Forwarded SSH port"

    local vm='' ssh_port=''
    @args "$@" || return $?

    log_info "Checking if NixOS is installed on $vm"
    vagrant ssh "$vm" -c 'env' 2>&1 | grep -q NIX_PROFILES || {
        log_info "NixOS is not installed on $vm, deploying..."
        vm_deploy --vm "$vm" --ssh-port "$ssh_port" --install
        log_info "Waiting for SSH to be ready on $vm"
        for attempt in {1..60}; do
            if vagrant ssh "$vm" -c 'echo "SSH is ready"' 2>/dev/null; then
                break
            fi
            if [[ "$attempt" == 60 ]]; then
                log_fail "Timed out waiting for SSH on $vm"
            fi
            sleep 1
        done
    }

    # secret bootstrapping
    source .env
    if [[ -z "${BWS_TOKEN:-}" ]]; then
        log_fail "BWS token not found; set BWS_TOKEN or place the token there"
    fi

    log_info "Provisioning BWS access token on $vm"
    vagrant ssh "$vm" -- sudo -n install -d -m 0700 /var/lib/bws
    echo "$BWS_TOKEN" | vagrant ssh "$vm" -- "sudo -n rm -f /var/lib/bws/bws-token.cred.new && sudo -n systemd-creds encrypt --with-key=auto --name=bws-token - /var/lib/bws/bws-token.cred.new && sudo -n chmod 0400 /var/lib/bws/bws-token.cred.new && sudo -n mv -f /var/lib/bws/bws-token.cred.new /var/lib/bws/bws-token.cred"

    log_info "Deploying machine-key"
    log_info "Rebuilding NixOS on $vm"
    vm_deploy --vm "$vm" --ssh-port "$ssh_port" --rebuild
}

function vm01 {
    @doc "Full setup for vm01"
    vm_setup --vm vm01 --ssh-port 22101 "$@"
}

function vm02 {
    @doc "Full setup for vm02"
    vm_setup --vm vm02 --ssh-port 22102 "$@"
}

function vm03 {
    @doc "Full setup for vm03"
    vm_setup --vm vm03 --ssh-port 22103 "$@"
}

# If this script is run directly, execute the main function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    @main "$@"
fi
