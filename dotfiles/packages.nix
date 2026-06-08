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
    pre-commit
    shellcheck

    go

    uv
    cue
    hugo
    opencode

    nixd
    nixfmt
    opentofu
    shfmt

    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.hack
    nerd-fonts.comic-shanns-mono
    nerd-fonts.open-dyslexic

    pi-coding-agent
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
