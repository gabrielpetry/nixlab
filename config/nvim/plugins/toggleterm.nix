{ nixvimLib, ... }:
let
  mkRaw = nixvimLib.mkRaw;
in {
  programs.nixvim.plugins.toggleterm = {
    enable = true;
    settings = {
      size = 10;
      direction = "float";
      shading_factor = 2;
      on_create = mkRaw ''
        function()
          vim.opt_local.foldcolumn = "0"
          vim.opt_local.signcolumn = "no"
        end
      '';
      float_opts = {
        border = "curved";
        width = mkRaw ''function() return math.ceil(vim.o.columns * 0.9) end'';
        height = mkRaw ''function() return math.ceil(vim.o.lines * 0.85) end'';
      };
    };
  };
}
