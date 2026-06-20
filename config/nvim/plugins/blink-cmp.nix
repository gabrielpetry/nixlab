{ nixvimLib, ... }:
let
  mkRaw = nixvimLib.mkRaw;
in {
  programs.nixvim.plugins.blink-cmp = {
    enable = true;
    settings.keymap = {
      "<Tab>" = [
        "snippet_forward"
        (mkRaw ''
          function()
            if vim.g.ai_accept then return vim.g.ai_accept() end
          end
        '')
        "fallback"
      ];
      "<S-Tab>" = [ "snippet_backward" "fallback" ];
    };
  };
}
