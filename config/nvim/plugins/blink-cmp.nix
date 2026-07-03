{ nixvimLib, ... }:
let
  mkRaw = nixvimLib.mkRaw;
in
{
  programs.nixvim.plugins.blink-cmp = {
    enable = true;
    settings.use_nvim_cmp_as_default = true;
    settings.keymap = {
      preset = "default";
      "<CR>" = [
        "select_and_accept"
        "fallback"
      ];
      "<C-u>" = [
        "scroll_documentation_up"
        "fallback"
      ];
      "<C-d>" = [
        "scroll_documentation_down"
        "fallback"
      ];
      "<Tab>" = [
        "snippet_forward"
        (mkRaw ''
          function()
            if vim.g.ai_accept then return vim.g.ai_accept() end
          end
        '')
        "fallback"
      ];
      "<S-Tab>" = [
        "snippet_backward"
        "fallback"
      ];
    };
  };
}
