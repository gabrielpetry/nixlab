#!/usr/bin/env bash
# shellcheck disable=SC2329

set -euo pipefail

GIT_ROOT="$(git rev-parse --show-toplevel)"

if [[ -z "${__BSD_LIBRARY_NAME:-}" ]]; then
    # shellcheck source=lib/bash-command-core/lib/bash-simple-doc.sh
    source "$GIT_ROOT/lib/bash-command-core/lib/bash-simple-doc.sh"
fi

if [[ -f "$GIT_ROOT/lib/local/inventory.sh" ]]; then
    # shellcheck source=local/inventory.sh
    source "$GIT_ROOT/lib/local/inventory.sh"
fi

function vm_deploy {
    @internal
    @doc "Basic args for deploy vms"
    @arg "required" "--vm" "VM to deploy"
    @arg "default=22" "--ssh-port|-s" "SSH port to use"
    @flag "--rebuild" "Rebuild the VM"
    @flag "--install" "Install the VM"

    local vm ssh_port rebuild install ip user_config ssh_pubkey
    local -a action
    @args "$@" || return $?
    ip="127.0.0.1"
    user_config="${NIXLAB_USER_CONFIG:-$GIT_ROOT/user-config.nix}"
    ssh_pubkey="${NIXLAB_VM_SSH_PUBKEY_FILE:-$GIT_ROOT/.vagrant/ssh/nixlab_dev_key.pub}"

    if [[ "$rebuild" == "true" && "$install" == "true" ]] ||
       [[ "$rebuild" != "true" && "$install" != "true" ]]; then
        log_fail 'choose exactly one of --install or --rebuild'
    fi

    if [[ "$rebuild" == "true" ]]; then
        action=(
            rebuild
            --ssh-host "$ip"
            --ssh-port "$ssh_port"
            --ssh-user root
            --insecure
            --flake "path:${GIT_ROOT}#${vm}"
            --ssh-key "$GIT_ROOT/.vagrant/ssh/nixlab_dev_key"
        )
    else
        action=(
            install
            --hostname "${vm}-install"
            --ip "$ip"
            --port "$ssh_port"
            --ssh-user vagrant
            --insecure
            --ssh-key "$GIT_ROOT/.vagrant/ssh/nixlab_dev_key"
        )
    fi

    NIXLAB_USER_CONFIG="$user_config" \
        NIXLAB_VM_SSH_PUBKEY_FILE="$ssh_pubkey" \
        "$GIT_ROOT/lib/nixanywhere.sh" "${action[@]}"
}

function vm01 {
    @doc "Deploy vm01"
    vm_deploy --vm vm01 --ssh-port 22101 "$@"
}

function vm02 {
    @doc "Deploy vm02"
    vm_deploy --vm vm02 --ssh-port 22102 "$@"
}

function vm03 {
    @doc "Deploy vm03"
    vm_deploy --vm vm03 --ssh-port 22103 "$@"
}

# If this script is run directly, execute the main function
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    @main "$@"
fi
