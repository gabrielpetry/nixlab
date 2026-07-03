{ nvimPkgs, ... }: {
  programs.nixvim.plugins.treesitter = {
    enable = true;
    highlight = {
      enable = true;
      disable = [
        "markdown"
        "markdown_inline"
      ];
    };
    indent.enable = true;
    grammarPackages = with nvimPkgs.vimPlugins.nvim-treesitter.builtGrammars; [
      bash
      go
      hcl
      helm
      json
      lua
      markdown
      markdown_inline
      nix
      promql
      python
      query
      regex
      terraform
      toml
      vim
      vimdoc
      yaml
    ];
  };
}
