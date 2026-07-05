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
    @example "install --hostname vm01 --ip 127.0.0.1 --port 50022 --ssh-user vagrant --ssh-key .vagrant/ssh/nixlab_dev_key"
    local hostname='' ip='' port='' ssh_user='' installer_ssh_user='' ssh_key=''
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

    local nixos_anywhere_args=(
        --flake "path:${project_root}#${hostname}"
        --ssh-port "$port"
        --post-kexec-ssh-port "$port"
        --ssh-option "StrictHostKeyChecking=no"
        --ssh-option "UserKnownHostsFile=/dev/null"
        -i "$ssh_key"
    )

    nix run github:nix-community/nixos-anywhere -- \
        "${nixos_anywhere_args[@]}" \
        --phases kexec \
        --target-host "${ssh_user}@${ip}"

    nix run github:nix-community/nixos-anywhere -- \
        "${nixos_anywhere_args[@]}" \
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
    @example "rebuild --ssh-host 127.0.0.1 --ssh-port 50022 --ssh-user vagrant --ssh-key .vagrant/ssh/nixlab_dev_key --flake path:\$PWD#vm01"
    local ssh_host='' ssh_user='' ssh_port='' ssh_key='' flake=''
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

    local nix_sshopts="-p ${ssh_port} -i ${ssh_key}"
    if [[ -n "${NIX_SSHOPTS:-}" ]]; then
        nix_sshopts="${nix_sshopts} ${NIX_SSHOPTS}"
    fi

    NIX_SSHOPTS="$nix_sshopts" nix run nixpkgs#nixos-rebuild -- switch \
        --flake "$flake" \
        --target-host "${ssh_user}@${ssh_host}" \
        --elevate=sudo
}

@main "$@"
