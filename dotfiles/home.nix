# home.nix
{ pkgs, username ? "user", homeDirectory ? "/home/user", ... }:
{
  home.username = username;
  home.homeDirectory = homeDirectory;
  home.stateVersion = "26.05";
  fonts.fontconfig.enable = true;

  # Packages previously provided by brew (now via Nix)
  home.packages = with pkgs; [
    cargo 
    rustc
    rust-analyzer
    rustfmt

    bat
    tree
    yq
    jq

    go
    opentofu
    nixfmt
    shfmt
    nixd

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
    "$HOME/.krew"
    "$HOME/.krew/bin"
    "$HOME/.local/bin"
    "$HOME/bin"
    "$HOME/nixlab/tooling/automation"
    "$HOME/nixlab/tooling/cli"
    "$HOME/nixlab/tooling/scripts"
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
