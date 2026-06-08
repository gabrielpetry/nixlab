# home.nix
{ pkgs, username ? "user", homeDirectory ? "/home/user", ... }:
{
  home.username = username;
  home.homeDirectory = homeDirectory;
  home.stateVersion = "26.05";
  fonts.fontconfig.enable = true;

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

  # Cross-shell environment variables (applied to fish, bash, zsh, etc.)
  home.sessionVariables = {
    EDITOR = "nvim";
    KUBECTL_CACHE_TTL_SECONDS = "15";
    TERM = "xterm-256color";
    CACHE_DIR = "$HOME/.cache";
    KUBECONFIG = "$HOME/.kube/config";
    PNPM_HOME = "$HOME/.local/share/pnpm";
    BROWSER = "chromium-browser";
  };

  # Cross-shell PATH entries (applied via fish_add_path for fish, export PATH for bash/zsh)
  # Note: $HOME/.cargo/bin intentionally omitted — Rust is from Nix, not rustup
  home.sessionPath = [
    "$HOME/.bun/bin"
    "$HOME/.cargo/bin"
    "$HOME/.local/bin"
    "$HOME/bin"
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
