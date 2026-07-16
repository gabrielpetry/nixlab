# nixlab

> **Personal workstation and server Nix flake configuration.**  
> This repository is **public** — feel free to fork, adapt, and learn from it.

---

## 🚀 Workstation Quickstart — `./lib/run.sh`

**One command to bootstrap your entire system:**

```sh
git clone https://github.com/gabrielpetry/nixlab.git ~/nixlab
cd ~/nixlab
./lib/run.sh
```

That's it. `lib/run.sh` handles the workstation bootstrap automatically:

- Installs **Nix** (with flakes enabled) if you don't have it
- Detects your **username** and **home directory** (no manual editing needed)
- Runs **home-manager switch** to apply your dotfiles, tools, and shell config
- Installs default developer tooling, including **Node.js**, **npm**, and **pnpm**

> No need to edit `flake.nix` or set variables — `lib/run.sh` generates a `user-config.nix` on the fly with your current user info.

---

## 🖥️ Server Install And E2E Test

This repo provides shared building blocks for server hosts and simple VM definitions for end-to-end deployment testing.

- `lib.mkHost` (from `nixosAnywhere/lib.nix`) is the shared host constructor, exposed as `nixlab.lib.mkHost`.
- `nixosModules/*` contain reusable NixOS modules.
- `nixosAnywhere/vms/` contains the example VM definitions exported by the main flake.

The local VM harness uses Vagrant with the QEMU provider:

```sh
vagrant up vm01 --provider=qemu
vagrant status
vagrant destroy -f vm01
```

For `vm01`, the local harness also forwards the K3s ports to localhost:

- `https://127.0.0.1:26443` -> guest `6443`
- `http://127.0.0.1:28080` -> guest `80`
- `https://127.0.0.1:28443` -> guest `443`

Additional VMs use the same ports with `+100` per VM index.

### Rebuild a VM

```sh
./lib/inventory.sh vm01 --install
./lib/inventory.sh vm01 --rebuild
```

`--install` selects the minimal `vm01-install` configuration (disk, network, SSH keys, and bootstrap user). `--rebuild` selects `vm01`, which adds the full runtime configuration including Docker, K3s, BWS, and exporters.

The full playbook also performs both phases and bootstraps the local BWS credential:

```sh
./lib/playbooks.sh vm01
```

This rebuilds the `vm01` configuration exported by the main flake. The VM helper passes `--insecure` because the disposable VM's SSH host key changes when it is recreated.

### Install a fresh host

Install any reachable host with the standalone `nixos-anywhere` wrapper:

```sh
./lib/nixanywhere.sh install --hostname vm01-install --ip 127.0.0.1 --port 22101 --ssh-user vagrant --ssh-key .vagrant/ssh/nixlab_dev_key --insecure
```

For the Vagrant/QEMU path, `--ssh-user vagrant` is only used before kexec while the box is still Ubuntu; the wrapper reconnects to the temporary NixOS installer as `root` by default. For a normal server, `--ssh-user` defaults to `root`, `--port` defaults to `22`, and `--ssh-key` defaults to the first existing key under `~/.ssh/id_ed25519` or `~/.ssh/id_rsa`:

```sh
./lib/nixanywhere.sh install --hostname my-host --ip 203.0.10.10
```

SSH host keys are recorded with OpenSSH's `accept-new` policy by default. Use `--insecure` only for disposable local test machines where host-key verification is intentionally disabled.

### Example VM layout

```text
nixosAnywhere/
  vms/
    vm01-install.nix   # network, disk, SSH, bootstrap user only
    vm02-install.nix
    vm03-install.nix
    vm01.nix            # full rebuild configuration
    vm02.nix
    vm03.nix
    vms.nix
    disko.nix
```

The main flake exports these examples through `nixosConfigurations`. Keep machine-specific secrets and user settings in the non-versioned `user-config.nix`; never place secret values in Nix expressions.

---

## 📦 Available modules

If you want to cherry-pick individual components into your own Nix config:

| Module | Path | What it configures |
|--------|------|--------------------|
| `homeModules.packages` | [`config/packages.nix`](config/packages.nix) | Base developer packages |
| `homeModules.environment` | [`config/environment.nix`](config/environment.nix) | Session environment and PATH |
| `homeModules.tmux` | [`config/tmux/tmux.nix`](config/tmux/tmux.nix) | Tmux terminal multiplexer |
| `homeModules.neovim` | [`config/nvim/nvim.nix`](config/nvim/nvim.nix) | Neovim with Nixvim |
| `homeModules.bash` | [`config/bash/bash.nix`](config/bash/bash.nix) | Bash completions, aliases, and plugins |
| `homeModules.starship` | [`config/starship/starship.nix`](config/starship/starship.nix) | Starship prompt |
| `homeModules.kde` | [`config/kde.nix`](config/kde.nix) | KDE desktop settings |
| `homeModules.tooling` | [`tooling/tooling.nix`](tooling/tooling.nix) | Kubernetes CLI stack and helper scripts |

### Import into your own flake

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";
    nixlab.url = "github:gabrielpetry/nixlab";
  };

  outputs = { nixpkgs, home-manager, nixlab, ... }: {
    homeConfigurations."user" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages."x86_64-linux";
      modules = [
        { home.username = "user"; home.homeDirectory = "/home/user"; home.stateVersion = "24.11"; }
        nixlab.homeModules.bash
        nixlab.homeModules.tmux
        nixlab.homeModules.neovim
      ];
    };
  };
}
```

---

## 🔐 Bitwarden Secrets Manager — initial token setup

The `bws` NixOS module (`nixosModules/bws/bws.nix`) fetches secrets from Bitwarden Secrets Manager at runtime and stores them as systemd-encrypted credentials on disk.

You need to create the encrypted access token before the module can run:

```sh
# 1. Paste or type your BWS access token (output is hidden)
read -rsp "BWS access token: " BWS_ACCESS_TOKEN

# 2. Encrypt it with systemd-creds, locked to this machine
sudo install -d -m 700 /var/lib/bws
printf '%s' "$BWS_ACCESS_TOKEN" \
  | sudo systemd-creds encrypt --with-key=auto --name=bws-token - /var/lib/bws/bws-token.cred

# 3. Clear the plaintext from the shell
unset BWS_ACCESS_TOKEN

# 4. Lock down permissions
sudo chmod 0400 /var/lib/bws/bws-token.cred
```

You can verify the encrypted token is usable by decrypting it with `systemd-creds` (for testing only):

```sh
sudo systemd-creds decrypt --with-key=auto /var/lib/bws/bws-token.cred -
```

### Getting a BWS access token

1. Log in to the [Bitwarden Secrets Manager web UI](https://bitwarden.com/products/secrets-manager/) (or your self-hosted instance)
2. Navigate to your project → **Service Accounts** → create a new service account
3. Copy the **Access Token** that is shown once
4. Store it securely — it will not be shown again

The access token needs at least `read` permission on the secrets referenced by your `bws.files` config.

### Per-secret credential files

Each entry under `bws.files.<name>` with `storage = "systemd-credential"` (the default) is automatically encrypted with `systemd-creds encrypt --with-key=auto` when the fetch unit runs. The encrypted file lives at the configured `path` (e.g. `/var/lib/bws/k3s-token.cred`).

Consumer services load these files via `LoadCredentialEncrypted=` in their systemd unit. When the `environmentVariable` option is set, the service also gets an `Environment=<VAR>=%d/<name>` entry pointing to the decrypted credential at runtime.

---

## 🪝 Pre-commit hooks

Hook scripts live in `.githooks/pre-commit.d/`. Enable them locally:

```sh
git config core.hooksPath .githooks
```

This tells Git to look in `.githooks/` instead of `.git/hooks/`. A [gitleaks](https://gitleaks.io/) scan runs on every commit to detect leaked secrets.

---

## 📄 License

`LICENSE.md` — [WTFPL](http://www.wtfpl.net/) with additional terms: **no AI training, no evil, no weapons, and buy me a beer if we ever meet.** See the full license for details.
