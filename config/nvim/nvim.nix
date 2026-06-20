{ pkgs, nixvimLib, ... }:
let
  mkRaw = nixvimLib.mkRaw;

  diagramNvim = pkgs.vimUtils.buildVimPlugin {
    pname = "diagram.nvim";
    version = "2026-06-12";
    src = pkgs.fetchFromGitHub {
      owner = "3rd";
      repo = "diagram.nvim";
      rev = "a221810b17cdda2d5fdddba9bab3eba6fab8fabc";
      hash = "sha256-+K5o50CtBFqn37t6GnAnI1p2CfCyA1w4TIhMKpfZX4A=";
    };
    nvimRequireCheck = [
      "diagram.integrations.markdown"
      "diagram.renderers.d2"
      "diagram.renderers.gnuplot"
      "diagram.renderers.mermaid"
      "diagram.renderers.plantuml"
      "diagram.types"
    ];
  };
in
{
  imports = [
    ./options.nix
    ./diagnostics.nix
    ./keymaps.nix
    ./autocmds.nix
    ./colorscheme.nix
    ./extra-lua.nix
    ./packages.nix
    ./plugins
  ];

  xdg.configFile = {
    "nvim/after/queries/yaml/highlights.scm".source = ./after/queries/yaml/highlights.scm;
    "nvim/after/queries/yaml/injections.scm".source = ./after/queries/yaml/injections.scm;
    "nvim/after/queries/promql/highlights.scm".source = ./after/queries/promql/highlights.scm;
  };

  programs.nixvim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    nixpkgs.source = pkgs.path;

    extraPlugins = [
      diagramNvim
      pkgs.vimPlugins.image-nvim
    ];
  };
}
