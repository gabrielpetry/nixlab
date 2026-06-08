{ pkgs, ... }:
{
  home.sessionPath = [
    "$HOME/.krew"
    "$HOME/.krew/bin"
    "$HOME/tooling/automation"
    "$HOME/tooling/cli"
    "$HOME/tooling/scripts"
  ];

  home.file."tooling/scripts" = {
    source = ./scripts;
    recursive = true;
  };

  home.file."tooling/automation" = {
    source = ./automation;
    recursive = true;
  };

  home.file."tooling/cli" = {
    source = ./cli;
    recursive = true;
  };

  home.packages = with pkgs; [
    kubectl
    kubecolor
    kubernetes-helm
    kustomize
    k9s
    argocd
    kubeseal
    k3d
    krew
    crossplane

    awscli2

    go-task
    yamlfmt
  ];
}
