{ nixvimLib, ... }:
let
  mkRaw = nixvimLib.mkRaw;
in {
  programs.nixvim.plugins.smart-splits = {
    enable = true;
    settings = {
      ignored_filetypes = [ "nofile" "quickfix" "qf" "prompt" ];
      ignored_buftypes = [ "nofile" ];
      at_edge = "wrap";
      cursor_follows_swapped_bufs = true;
      multiplexer_integration = mkRaw ''(vim.env.TMUX and vim.env.TMUX ~= "") and "tmux" or false'';
    };
  };
}
