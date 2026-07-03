{ nixvimLib, ... }:
let
  mkRaw = nixvimLib.mkRaw;
in {
  programs.nixvim.plugins.alpha = {
    enable = true;
    settings = mkRaw ''
      (function()
        local dashboard = require("alpha.themes.dashboard")
        dashboard.section.header.val = {
          " █████  ███████ ████████ ██████   ██████ ",
          "██   ██ ██         ██    ██   ██ ██    ██",
          "███████ ███████    ██    ██████  ██    ██",
          "██   ██      ██    ██    ██   ██ ██    ██",
          "██   ██ ███████    ██    ██   ██  ██████ ",
          "",
          "███    ██ ██    ██ ██ ███    ███",
          "████   ██ ██    ██ ██ ████  ████",
          "██ ██  ██ ██    ██ ██ ██ ████ ██",
          "██  ██ ██  ██  ██  ██ ██  ██  ██",
          "██   ████   ████   ██ ██      ██",
        }
        dashboard.section.buttons.val = {
          dashboard.button("n", "  New File", "<Cmd>ene<CR>"),
          dashboard.button("f", "  Find File", "<Cmd>Telescope find_files<CR>"),
          dashboard.button("o", "  Recent Files", "<Cmd>Telescope oldfiles<CR>"),
          dashboard.button("w", "󰈬  Find Word", "<Cmd>Telescope live_grep<CR>"),
          dashboard.button("s", "󰦛  Restore Session", "<Cmd>lua pcall(vim.cmd, 'SessionRestore')<CR>"),
          dashboard.button("q", "  Quit", "<Cmd>qa<CR>"),
        }
        dashboard.section.footer.val = {
          "",
          "Nixvim configured to feel like AstroNvim",
        }
        return dashboard.config
      end)()
    '';
  };
}
