# nixlab

> **Personal workstation and server Nix flake configuration.**  
> This repository is **public** — feel free to fork, adapt, and learn from it.

---

## 🚀 Workstation Quickstart — `./run.sh`

**One command to bootstrap your entire system:**

```sh
git clone https://github.com/gabrielpetry/nixlab.git ~/nixlab
cd ~/nixlab
./run.sh
```

That's it. `run.sh` handles the workstation bootstrap automatically:

- Installs **Nix** (with flakes enabled) if you don't have it
- Detects your **username** and **home directory** (no manual editing needed)
- Runs **home-manager switch** to apply your dotfiles, tools, and shell config
- Installs default developer tooling, including **Node.js**, **npm**, and **pnpm**

> No need to edit `flake.nix` or set variables — `run.sh` generates a `user-config.nix` on the fly with your current user info.

---

## 🖥️ Server Install And E2E Test

`nixosConfigurations` is the server path in this repo. The current local test host is `vm01`.

Versioned hosts live under `nixosAnywhere/`. Private hosts are loaded from a separate repository checked out at `nixosAnywhere/local/`, with `nixosAnywhere/local/default.nix` as its entrypoint. A tracked contract example lives at `nixosAnywhere/local.example.nix`.

The local VM harness only manages Vagrant/QEMU lifecycle:

```sh
./dev.sh up --name vm01
./dev.sh ps
./dev.sh destroy --name vm01
```

Install any reachable host with the standalone `nixos-anywhere` wrapper:

```sh
./lib/nixanywhere.sh install --hostname vm01 --ip 127.0.0.1 --port 50022 --ssh-user vagrant --ssh-key .vagrant/ssh/nixlab_dev_key
```

For the Vagrant/QEMU path, `--ssh-user vagrant` is only used before kexec while the box is still Ubuntu; the wrapper reconnects to the temporary NixOS installer as `root` by default. For a normal server, `--ssh-user` defaults to `root`, `--port` defaults to `22`, and `--ssh-key` defaults to the first existing key under `~/.ssh/id_ed25519` or `~/.ssh/id_rsa`:

```sh
./lib/nixanywhere.sh install --hostname my-host --ip 203.0.113.10
```

Notes:

- `--hostname` selects the `nixosConfigurations` flake output to install.
- The install flow uses `path:$PROJECT_ROOT#HOSTNAME` so repo-local generated files remain visible to Nix.
- The installed server host intentionally does **not** use Home Manager.

Example private host layout:

```text
nixosAnywhere/
  local/
    .git/
    default.nix          # returns nixosConfigurations entries
    my-host/
      default.nix
      disko.nix
```

The `nixosAnywhere/local/` tree is fully gitignored in this repo so it can be owned by that separate private repository.

---

## 📦 Available modules

If you want to cherry-pick individual components into your own Nix config:

| Module | Path | What it configures |
|--------|------|--------------------|
| `homeModules.fish` | [`dotfiles/fish/fish.nix`](dotfiles/fish/fish.nix) | Fish shell + fzf + direnv |
| `homeModules.tmux` | [`dotfiles/tmux/tmux.nix`](dotfiles/tmux/tmux.nix) | Tmux terminal multiplexer |
| `homeModules.neovim` | [`config/nvim/nvim.nix`](config/nvim/nvim.nix) | Neovim with Nixvim |
| `homeModules.bash` | [`dotfiles/bash/bash.nix`](dotfiles/bash/bash.nix) | Bash completions & aliases |
| `homeModules.tooling` | [`tooling/tooling.nix`](tooling/tooling.nix) | Scripts in `~/bin` (`ghprlist`, etc.) |

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
        nixlab.homeModules.fish
        nixlab.homeModules.tmux
        nixlab.homeModules.neovim
      ];
    };
  };
}
```

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
