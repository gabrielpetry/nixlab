{ ... }:
{
  # Split navigation and resize keybindings via smart-splits.nvim.
  # C-h/j/k/l: move cursor between splits (tmux-aware when $TMUX is set).
  # C-Up/Down/Left/Right: resize splits.
  # Global keybindings (ToggleTerm <C-Q>, Twilight <C-;>, indent reselect >/<)
  # live in lua/init.lua alongside the lazy.nvim bootstrap.
  xdg.configFile = {
    "nvim/lua/plugins/smart-splits.lua".source = ./lua/plugins/smart-splits.lua;
  };
}
