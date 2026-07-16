#!/usr/bin/env bash

set -Eeuo pipefail

# shellcheck source=lib/bash-command-core/lib/bash-simple-doc.sh
source "$(dirname "${BASH_SOURCE[0]}")/bash-command-core/lib/bash-simple-doc.sh"

function expand_home {
    # this
    local path=$1

    case "$path" in
    ~/*)
        printf '%s/%s\n' "$HOME" "${path#~/}"
        ;;
    *)
        printf '%s\n' "$path"
        ;;
    esac
}

function default_ssh_key {
    local home_dir key
    home_dir=${HOME:-}

    [[ -n "$home_dir" ]] || return 1

    for key in "$home_dir/.ssh/id_ed25519" "$home_dir/.ssh/id_rsa"; do
        if [[ -f "$key" ]]; then
            printf '%s\n' "$key"
            return 0
        fi
    done

    return 1
}

function install {
    @doc "Install a NixOS host with nixos-anywhere"
    @arg "required" "--hostname|-n" "NixOS flake output to install"
    @arg "required" "--ip" "Target IP address or DNS name"
    @arg "default=22" "--port|-p" "SSH port"
    @arg "default=root" "--ssh-user|-u" "SSH user for the existing OS before kexec"
    @arg "default=root" "--installer-ssh-user" "SSH user after kexec into the temporary NixOS installer"
    @arg "nullable" "--ssh-key|-i" "Private SSH key (default: ~/.ssh/id_ed25519 or ~/.ssh/id_rsa)"
    @flag "--insecure" "Disable SSH host-key verification (intended for disposable local VMs only)"
    @example "install --hostname vm01-install --ip 127.0.0.1 --port 22101 --ssh-user vagrant --ssh-key .vagrant/ssh/nixlab_dev_key --insecure"
    local hostname='' ip='' port='' ssh_user='' installer_ssh_user='' ssh_key='' insecure=''
    @args "$@" || return $?

    [[ -n "$ssh_user" ]] || log_fail '--ssh-user must not be empty'
    [[ -n "$installer_ssh_user" ]] || log_fail '--installer-ssh-user must not be empty'
    [[ "$port" =~ ^[0-9]+$ ]] || log_fail '--port must be numeric'

    if [[ -z "$ssh_key" ]]; then
        ssh_key=$(default_ssh_key) || log_fail 'No default SSH key found; pass --ssh-key'
    else
        ssh_key=$(expand_home "$ssh_key")
    fi

    [[ -f "$ssh_key" ]] || log_fail "SSH key not found: $ssh_key"

    local script_dir project_root
    script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    project_root="$(git -C "$script_dir" rev-parse --show-toplevel 2>/dev/null)" ||
        log_fail "Failed to resolve git repository root from $script_dir"

    if [[ ! -f "${ssh_key}.pub" ]]; then
        ssh-keygen -y -f "$ssh_key" >"${ssh_key}.pub" ||
            log_fail "Failed to generate public key for $ssh_key"
    fi

    local user_config="${NIXLAB_USER_CONFIG:-$project_root/user-config.nix}"
    user_config="$(realpath "$user_config")" ||
        log_fail "Failed to resolve user config: $user_config"
    [[ -f "$user_config" ]] || log_fail "User config not found: $user_config"

    local flake_uri="git+file://${project_root}"
    local disko_installable="${flake_uri}#nixosConfigurations.${hostname}.config.system.build.diskoScript"
    local system_installable="${flake_uri}#nixosConfigurations.${hostname}.config.system.build.toplevel"
    local disko_path system_path

    disko_path=$(NIXLAB_USER_CONFIG="$user_config" nix build --impure --no-link --print-out-paths "$disko_installable") ||
        log_fail "Failed to resolve the disko path for $hostname"
    system_path=$(NIXLAB_USER_CONFIG="$user_config" nix build --impure --no-link --print-out-paths "$system_installable") ||
        log_fail "Failed to resolve the system path for $hostname"

    local -a host_key_args=(--ssh-option "StrictHostKeyChecking=accept-new")
    if [[ "$insecure" == "true" ]]; then
        host_key_args=(
            --ssh-option "StrictHostKeyChecking=no"
            --ssh-option "UserKnownHostsFile=/dev/null"
        )
    fi

    local known_hosts_kexec='' known_hosts_installer=''
    if [[ "$insecure" != "true" ]]; then
        known_hosts_kexec=$(mktemp)
        known_hosts_installer=$(mktemp)
        trap 'rm -f "$known_hosts_kexec" "$known_hosts_installer"' EXIT
    fi

    local -a nixos_anywhere_args=(
        --store-paths "$disko_path" "$system_path"
        --ssh-port "$port"
        --post-kexec-ssh-port "$port"
        --ssh-option "BatchMode=yes"
        "${host_key_args[@]}"
        -i "$ssh_key"
    )

    local -a kexec_args=("${nixos_anywhere_args[@]}")
    local -a installer_args=("${nixos_anywhere_args[@]}")
    if [[ "$insecure" != "true" ]]; then
        kexec_args+=(--ssh-option "UserKnownHostsFile=$known_hosts_kexec")
        installer_args+=(--ssh-option "UserKnownHostsFile=$known_hosts_installer")
    fi

    NIXLAB_USER_CONFIG="$user_config" nix run --impure "${flake_uri}#nixos-anywhere" -- \
        "${kexec_args[@]}" \
        --phases kexec \
        --target-host "${ssh_user}@${ip}"

    NIXLAB_USER_CONFIG="$user_config" nix run --impure "${flake_uri}#nixos-anywhere" -- \
        "${installer_args[@]}" \
        --phases disko,install,reboot \
        --target-host "${installer_ssh_user}@${ip}"
}

function rebuild {
    @doc "Rebuild a remote NixOS host over SSH"
    @arg "required" "--ssh-host" "Target SSH host/IP/DNS"
    @arg "default=$(whoami)" "--ssh-user|-u" "SSH user for the NixOS host"
    @arg "default=22" "--ssh-port|-p" "SSH port"
    @arg "nullable" "--ssh-key|-i" "Private SSH key (default: ~/.ssh/id_ed25519 or ~/.ssh/id_rsa)"
    @arg "required" "--flake|-f" "NixOS flake URI/output to rebuild"
    @flag "--insecure" "Disable SSH host-key verification (intended for disposable local VMs only)"
    @example "rebuild --ssh-host 127.0.0.1 --ssh-port 22101 --ssh-user root --ssh-key .vagrant/ssh/nixlab_dev_key --flake git+file://\$PWD#vm01 --insecure"
    local ssh_host='' ssh_user='' ssh_port='' ssh_key='' flake='' insecure=''
    @args "$@" || return $?

    [[ -n "$ssh_host" ]] || log_fail '--ssh-host must not be empty'
    [[ -n "$ssh_user" ]] || log_fail '--ssh-user must not be empty'
    [[ -n "$flake" ]] || log_fail '--flake must not be empty'
    [[ "$ssh_port" =~ ^[0-9]+$ ]] || log_fail '--ssh-port must be numeric'

    if [[ -z "$ssh_key" ]]; then
        ssh_key=$(default_ssh_key) || log_fail 'No default SSH key found; pass --ssh-key'
    else
        ssh_key=$(expand_home "$ssh_key")
    fi

    [[ -f "$ssh_key" ]] || log_fail "SSH key not found: $ssh_key"

    local script_dir project_root
    script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
    project_root="$(git -C "$script_dir" rev-parse --show-toplevel 2>/dev/null)" ||
        log_fail "Failed to resolve git repository root from $script_dir"
    local user_config="${NIXLAB_USER_CONFIG:-$project_root/user-config.nix}"
    user_config="$(realpath "$user_config")" ||
        log_fail "Failed to resolve user config: $user_config"
    [[ -f "$user_config" ]] || log_fail "User config not found: $user_config"
    flake="${flake/path:/git+file://}"
    local tool_flake_uri="git+file://${project_root}"

    local host_key_opts="-o StrictHostKeyChecking=accept-new"
    if [[ "$insecure" == "true" ]]; then
        host_key_opts="-o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"
    fi
    local nix_sshopts="-p ${ssh_port} -i ${ssh_key} -o BatchMode=yes ${host_key_opts}"
    if [[ -n "${NIX_SSHOPTS:-}" ]]; then
        nix_sshopts="${nix_sshopts} ${NIX_SSHOPTS}"
    fi

    NIX_SSHOPTS="$nix_sshopts" NIXLAB_USER_CONFIG="$user_config" nix run --impure "${tool_flake_uri}#nixos-rebuild" -- switch \
        --impure \
        --flake "$flake" \
        --target-host "${ssh_user}@${ssh_host}"
}

@main "$@"
