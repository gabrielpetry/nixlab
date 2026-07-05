# nixlab — agent guide

## What this is

Dual-purpose flake for:
- workstation bootstrap via Home Manager
- installable NixOS server hosts via `nixosConfigurations`

Workstation config covers packages, shell, tmux, neovim, starship, KDE flatpak env, and heavy kubectl tooling.

## Bootstrap

```sh
./run.sh
```

This is the workstation path only.

**Gotchas:**
- Working tree must be clean — no untracked files allowed.
- `run.sh` auto-generates `user-config.nix` (gitignored, username/home from `whoami`/`$HOME`).
- Runs `nvfetcher &` and `nix flake update &` concurrently (background), then home-manager switch.
- Uses `path:$PWD` (not `.#`) so Nix sees the gitignored `user-config.nix`.

## Manual switch

```sh
nix run home-manager/master -- switch --flake "path:$PWD" --show-trace
```

## Server Install

The local Vagrant/QEMU harness is managed by `./dev.sh`:

```sh
./dev.sh up --name vm01
./dev.sh ps
./dev.sh destroy --name vm01
```

NixOS installs use the standalone `./lib/nixanywhere.sh` wrapper:

```sh
./lib/nixanywhere.sh install --hostname vm01 --ip 127.0.0.1 --port 50022 --ssh-user vagrant --ssh-key .vagrant/ssh/nixlab_dev_key
```

`--hostname` selects the `nixosConfigurations` output. For Vagrant/QEMU, `--ssh-user vagrant` is only used before kexec while the box is still Ubuntu; the wrapper reconnects to the temporary NixOS installer as `root` by default. `--ssh-user` defaults to `root`, `--port` defaults to `22`, and `--ssh-key` defaults to the first existing key under `~/.ssh/id_ed25519` or `~/.ssh/id_rsa`.

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
| `flake.nix` | Main flake entry for workstation and server outputs |
| `config/home.nix` | Base home config (username, homeDir, stateVersion = "26.11") |
| `config/packages.nix` | Language tooling, dev utils, nix dev tools |
| `config/environment.nix` | Env vars (`EDITOR`, `KUBECONFIG`, etc.), `sessionPath` |
| `config/bash/` | Bash completions, aliases, plugins |
| `config/nvim/` | Neovim via nixvim |
| `tooling/tooling.nix` | Kubernetes CLI stack (kubectl, flux, helm, k9s, argocd, k3d, crossplane, etc.) |
| `tooling/scripts/` | Custom CLI scripts (symlinked to `~/tooling/scripts/` in PATH) |
| `lib/nixanywhere.sh` | Standalone `nixos-anywhere` wrapper for any reachable host |
| `nixosModules/common.nix` | Shared NixOS base module for installable hosts |
| `nixosAnywhere/vm01/` | Installable NixOS VM host used by local testing |
| `nixosAnywhere/local/` | Optional separate private repo checkout loaded from `nixosAnywhere/local/default.nix` |
| `nixosServerModules/` | Server-only reusable NixOS modules |
| `packages/coding-agents/pi.nix` | pi coding-agent package (autoPatchelf for prebuilt binary) |

## No tests, no CI

No test framework, no CI pipeline. Only pre-commit checks.
