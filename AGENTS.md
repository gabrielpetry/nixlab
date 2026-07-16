# nixlab — agent guide

## What this is

Dual-purpose repo for:
- workstation bootstrap via Home Manager
- shared NixOS modules and host construction library (`lib.mkHost`) for server hosts

Simple end-to-end test host definitions live under `nixosAnywhere/vms/` and are exported by the main flake.

Workstation config covers packages, shell, tmux, neovim, starship, KDE flatpak env, and heavy kubectl tooling.

## Bootstrap

```sh
./lib/run.sh
```

This is the workstation path only.

**Gotchas:**
- Working tree must be clean — no uncommitted or untracked files allowed.
- `lib/run.sh` auto-generates `user-config.nix` (gitignored, username/home from `whoami`/`$HOME`).
- Runs `nvfetcher`, then home-manager switch. Set `NIXLAB_UPDATE=1` to update flake inputs first.
- Uses `path:$PWD` (not `.#`) so Nix sees the gitignored `user-config.nix`.

## Manual switch

```sh
nix run home-manager/master -- switch --flake "path:$PWD" --show-trace
```

## Server Install

The local VM harness uses Vagrant with the QEMU provider:

```sh
vagrant up vm01 --provider=qemu
vagrant status
vagrant destroy -f vm01
```

NixOS installs use the standalone `./lib/nixanywhere.sh` wrapper:

```sh
./lib/nixanywhere.sh install --hostname vm01-install --ip 127.0.0.1 --port 22101 --ssh-user vagrant --ssh-key .vagrant/ssh/nixlab_dev_key --insecure
```

The inventory helper keeps installation and runtime rebuilds separate:

```sh
./lib/inventory.sh vm01 --install   # minimal install profile
./lib/inventory.sh vm01 --rebuild   # full runtime profile
```

`--hostname` selects a `nixosConfigurations` output from the main flake. The `*-install` outputs contain only the install-time base (network, disk, SSH keys, and privileged bootstrap user); the matching output without `-install` is used for the full rebuild. For Vagrant/QEMU, `--ssh-user vagrant` is only used before kexec while the box is still Ubuntu; the wrapper reconnects to the temporary NixOS installer as `root` by default. `--ssh-user` defaults to `root`, `--port` defaults to `22`, and `--ssh-key` defaults to the first existing key under `~/.ssh/id_ed25519` or `~/.ssh/id_rsa`. The VM helpers use `--insecure` because disposable VM host keys change; normal hosts use OpenSSH's `accept-new` policy.

## Pre-commit hooks

```sh
git config core.hooksPath .githooks
```

Staged `.nix` files are checked with `nixfmt --check`. Also runs gitleaks, trivy, whitespace, merge-conflict checks.

## External packages

`nvfetcher.toml` + `_sources/` manages prebuilt binaries (pi coding agent).
After updating `nvfetcher.toml`, run `nvfetcher` to regenerate `_sources/`.

## Structure

| Path | What |
|------|------|
| `flake.nix` | Main flake — workstation config + shared NixOS modules + `lib.mkHost` |
| `config/home.nix` | Base home config (username, homeDir, stateVersion = "26.11") |
| `config/packages.nix` | Language tooling, dev utils, nix dev tools |
| `config/environment.nix` | Env vars (`EDITOR`, `KUBECONFIG`, etc.), `sessionPath` |
| `config/bash/` | Bash completions, aliases, plugins |
| `config/nvim/` | Neovim via nixvim |
| `tooling/tooling.nix` | Kubernetes CLI stack (kubectl, flux, helm, k9s, argocd, k3d, crossplane, etc.) |
| `tooling/scripts/` | Custom CLI scripts (symlinked to `~/tooling/scripts/` in PATH) |
| `lib/nixanywhere.sh` | Standalone `nixos-anywhere` wrapper for any reachable host |
| `nixosModules/common.nix` | Shared NixOS base module |
| `nixosAnywhere/lib.nix` | Shared host constructor (`lib.mkHost`) |
| `nixosAnywhere/vms/` | Simple VM host definitions for end-to-end deployment testing |
| `nixosServerModules/` | Server-only reusable NixOS modules |
| `packages/coding-agents/pi.nix` | pi coding-agent package (autoPatchelf for prebuilt binary) |

### Example VM configurations

The main flake exports the hosts under `nixosAnywhere/vms/` through `nixosConfigurations`. They intentionally keep the Vagrant/QEMU setup small so other users can run the complete install and rebuild flow. Local user settings remain in the non-versioned `user-config.nix`.

## No tests, no CI

No test framework, no CI pipeline. Only pre-commit checks.
