{ ... }:
{
  # Core neovim entrypoint and post-setup hooks.
  # init.lua: lazy.nvim bootstrap, autocmds (helm yaml detection, markdown render),
  #           WSL clipboard shim, and global keybindings.
  # polish.lua: reserved for arbitrary lua that runs last (currently a no-op stub).
  xdg.configFile = {
    "nvim/init.lua".source = ./lua/init.lua;
    "nvim/lua/polish.lua".source = ./lua/polish.lua;
  };
}
