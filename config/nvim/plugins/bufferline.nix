{ ... }: {
  programs.nixvim.plugins.bufferline = {
    enable = true;
    settings.options = {
      always_show_bufferline = true;
      diagnostics = "nvim_lsp";
      separator_style = "slant";
      offsets = [
        {
          filetype = "neo-tree";
          text = "Explorer";
          highlight = "Directory";
          text_align = "left";
        }
      ];
    };
  };
}
