{ pkgs, ... }:
{
  home.packages = with pkgs; [
    cargo
    rustc
    rust-analyzer
    rustfmt

    bat
    delta
    entr
    eza
    fd
    htop
    ncdu
    ripgrep
    tree
    wget

    jq
    yq

    gh
    lazygit
    shellcheck

    go

    uv
    cue
    hugo
    opencode

    nixd
    nvfetcher
    nixfmt
    opentofu
    shfmt
  ];

  programs.fzf = {
    enable = true;
    enableFishIntegration = true;
  };

  programs.direnv = {
    enable = true;
    enableFishIntegration = true;
    nix-direnv.enable = true;
  };
}
