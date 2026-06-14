{ ... }:
{
  home.sessionVariables = {
    EDITOR = "nvim";
    KUBECTL_CACHE_TTL_SECONDS = "30";
    TERM = "xterm-256color";
    CACHE_DIR = "$HOME/.cache";
    KUBECONFIG = "$HOME/.kube/config";
    PNPM_HOME = "$HOME/.local/share/pnpm";
    BROWSER = "chromium-browser";
  };

  home.sessionPath = [
    "$HOME/.bun/bin"
    "$HOME/.cargo/bin"
    "$PNPM_HOME"
    "$HOME/.local/bin"
    "$HOME/bin"
  ];
}
