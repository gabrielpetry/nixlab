{ pkgs, ... }: {
  programs.nixvim.plugins.treesitter = {
    enable = true;
    highlight = {
      enable = true;
      disable = [ "markdown" "markdown_inline" ];
    };
    indent.enable = true;
    grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
      bash
      go
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
      toml
      vim
      vimdoc
      yaml
    ];
  };
}
