{ ... }:
{
  # UI: colorscheme, icons, symbols outline, and focus mode.
  # astroui:          colorscheme = catppuccin-frappe, LSP loading spinners.
  # catppuccin:       theme plugin (priority 1000).
  # cachecolorscheme: persists last-used colorscheme across restarts.
  # aerial:           symbols outline sidebar (LSP/treesitter backed).
  # twilight:         dims inactive code blocks for focus mode (<C-;>).
  xdg.configFile = {
    "nvim/lua/plugins/astroui.lua".source = ./lua/plugins/astroui.lua;
    "nvim/lua/plugins/catppuccin.lua".source = ./lua/plugins/catppuccin.lua;
    "nvim/lua/plugins/cachecolorscheme.lua".source = ./lua/plugins/cachecolorscheme.lua;
    "nvim/lua/plugins/aerial.lua".source = ./lua/plugins/aerial.lua;
    "nvim/lua/plugins/twilight.lua".source = ./lua/plugins/twilight.lua;
  };
}
