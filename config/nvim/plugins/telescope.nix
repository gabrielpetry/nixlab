{ ... }: {
  programs.nixvim.plugins.telescope = {
    enable = true;
    extensions.fzf-native.enable = true;
    settings.defaults = {
      prompt_prefix = "   ";
      selection_caret = "  ";
      sorting_strategy = "ascending";
      path_display = [ "smart" ];
      layout_config.horizontal = {
        prompt_position = "top";
        preview_width = 0.55;
      };
    };
  };
}
