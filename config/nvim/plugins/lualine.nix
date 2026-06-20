{ ... }: {
  programs.nixvim.plugins.lualine = {
    enable = true;
    settings.options = {
      globalstatus = true;
      theme = "auto";
      section_separators = {
        left = "";
        right = "";
      };
      component_separators = {
        left = "";
        right = "";
      };
      disabled_filetypes = {
        statusline = [ "alpha" ];
      };
    };
  };
}
