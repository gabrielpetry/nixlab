{ ... }: {
  programs.nixvim.plugins.lint = {
    enable = true;
    lintersByFt = {
      lua = [ "selene" ];
      python = [ "ruff" ];
      bash = [ "shellcheck" ];
      sh = [ "shellcheck" ];
      yaml = [ "yamllint" ];
      "yaml.ansible" = [ "ansible_lint" ];
      ansible = [ "ansible_lint" ];
    };
  };
}
