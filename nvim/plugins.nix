{ ... }:
{
  # lazy.nvim setup, AstroNvim community packs, and general-purpose plugins.
  # Community packs enabled: lua, bash, helm, go, ansible, python.
  # Plugins: grafana alloy syntax, copilot-chat, blink.cmp AI keybind,
  #          diagram.nvim, vim-visual-multi, session persistence.
  xdg.configFile = {
    "nvim/lua/lazy_setup.lua".source = ./lua/lazy_setup.lua;
    "nvim/lua/community.lua".source = ./lua/community.lua;

    "nvim/lua/plugins/alloy.lua".source = ./lua/plugins/alloy.lua;
    "nvim/lua/plugins/cmp_ai.lua".source = ./lua/plugins/cmp_ai.lua;
    "nvim/lua/plugins/copilot_chat.lua".source = ./lua/plugins/copilot_chat.lua;
    "nvim/lua/plugins/diagrams.lua".source = ./lua/plugins/diagrams.lua;
    "nvim/lua/plugins/vim-visual-multi.lua".source = ./lua/plugins/vim-visual-multi.lua;

    # Session management: auto-save per-cwd + restore on startup
    "nvim/lua/plugins/astrocore_sessions.lua".source = ./lua/plugins/astrocore_sessions.lua;
    "nvim/lua/plugins/auto_restore_sessions.lua".source = ./lua/plugins/auto_restore_sessions.lua;
  };
}
