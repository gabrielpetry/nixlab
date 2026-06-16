{ pkgs, ... }:
{
  imports = [
    ./options.nix
    ./plugins.nix
    ./ui.nix
    ./lsp.nix
    ./keybinds.nix
    ./treesitter.nix
  ];

  programs.neovim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
  };

  # System-level dependencies required at runtime by neovim plugins
  home.packages = with pkgs; [
    gcc        # treesitter parser compilation
    stylua     # lua formatter
    gnumake    # copilot-chat tiktoken build step
    imagemagick # image.nvim (diagram rendering)
    gnuplot    # diagram.nvim gnuplot renderer
    lua
    luarocks
    ruff


    # LSP servers/ linters/ formatters
    basedpyright
    selene
    delve
    isort
    black
    pyrefly
    ansible-lint
    python3Packages.debugpy
    python3Packages.ty
  ];
}
