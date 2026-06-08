{ pkgs, ... }:
{
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
  ];
}
