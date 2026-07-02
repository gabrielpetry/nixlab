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

`nixosConfigurations` is the server path in this repo. The current end-to-end test host is `dev-container`.

Versioned hosts live under `nixosHosts/`. Private hosts are loaded from a separate repository checked out at `nixosHosts/local/`, with `nixosHosts/local/default.nix` as its entrypoint. A tracked contract example lives at `nixosHosts/local.example.nix`.

The local VM harness provisions a fresh Ubuntu VM, converts it to NixOS with `nixos-anywhere`, and then runs a second remote deployment from the same flake.

```sh
./test.sh up
./test.sh install
./test.sh verify-install
./test.sh deploy
./test.sh verify-deploy
```

Notes:

- `test.sh` stores a repo-local SSH key under `.qemu-noble/ssh/` and creates it automatically if missing.
- The install flow uses `path:$PWD#dev-container` so gitignored local test files remain visible to Nix.
- The installed server host intentionally does **not** use Home Manager.

Example private host layout:

```text
nixosHosts/
  local/
    .git/
    default.nix          # returns nixosConfigurations entries
    my-host/
      default.nix
      disko.nix
```

The `nixosHosts/local/` tree is fully gitignored in this repo so it can be owned by that separate private repository.

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
