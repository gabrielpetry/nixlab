# nixlab

> **Personal dotfiles and Nix flake configuration.**  
> This repository is **public** — feel free to fork, adapt, and learn from it.

## 🚀 Getting started (for your own use)

This flake is built for my personal setup.  
To use it for yourself:

1. **Fork/clone** this repository.
2. **Set your username and home directory** in the top-level [`flake.nix`](flake.nix) by editing the `username` and `homeDirectory` variables near the top:

   ```nix
   # ===== ADJUST THESE FOR YOUR USER =====
   username = "your-username";
   homeDirectory = "/home/your-username";
   # ======================================
   ```

   The same pattern applies in [`dotfiles/flake.nix`](dotfiles/flake.nix) if you use that entry point.

3. **Review the `tooling/` scripts** — most are generic helpers, but some (like [`ghprlist`](tooling/scripts/ghprlist)) reference personal conventions like `$HOME/repos/<org>` that you may want to adjust.

> **Note:** Secrets and API tokens should **not** be stored in this repo. A [gitleaks](https://gitleaks.io/) pre-commit hook is configured to scan for leaked secrets on every commit.

---

## Pre-commit hooks

Pre-commit hooks live in `.githooks/pre-commit`. To enable them, choose one of the following methods.

### Method 1 — Git config (recommended)

Set the hooks path locally for this repository:

```sh
git config core.hooksPath .githooks
```

This tells Git to look for hooks in `.githooks/` instead of `.git/hooks/`. The setting is local to this repository and stored in `.git/config`.

## Using this flake

You can import nixlab into your own flake to use or reference its [home-manager](https://github.com/nix-community/home-manager) modules and configuration.

### As a flake input

Add nixlab as an input in your `flake.nix`:

```nix
{
  description = "My flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    home-manager.url = "github:nix-community/home-manager";

    # Import nixlab from GitHub
    nixlab.url = "github:gabrielpetry/nixlab";
  };

  outputs = { nixpkgs, home-manager, nixlab, ... }: {
    # Use the modules in your own home-manager configuration
    homeConfigurations."user" = home-manager.lib.homeManagerConfiguration {
      pkgs = nixpkgs.legacyPackages."x86_64-linux";
      modules = [
        {
          home.username = "user";
          home.homeDirectory = "/home/user";
          home.stateVersion = "24.11";
        }

        # Reference a full module (fish, tmux, or nvim)
        nixlab.homeModules.fish
        nixlab.homeModules.tmux
        nixlab.homeModules.neovim
      ];
    };
  };
}
```

### Available modules

| Module          | Path                                     | What it configures                    |
|-----------------|------------------------------------------|---------------------------------------|
| `homeModules.fish`   | [`dotfiles/fish/fish.nix`](dotfiles/fish/fish.nix) | Fish shell setup (fzf, direnv, etc.) |
| `homeModules.tmux`   | [`dotfiles/tmux/tmux.nix`](dotfiles/tmux/tmux.nix) | Tmux terminal multiplexer config     |
| `homeModules.neovim` | [`nvim/nvim.nix`](nvim/nvim.nix)          | Neovim with AstroNvim plugins        |

These modules are designed to work together but can also be used independently in your own home-manager configuration.

> **Note:** The `homeModules` outputs are exposed by the top-level [`flake.nix`](flake.nix) so they can be consumed cleanly from other flakes.

