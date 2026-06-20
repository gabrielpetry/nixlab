{ nixvimLib, ... }:
let
  mkRaw = nixvimLib.mkRaw;
in {
  programs.nixvim.plugins.conform-nvim = {
    enable = true;
    settings = {
      formatters_by_ft = {
        lua = [ "stylua" ];
        nix = [ "nixfmt" ];
        python = [ "isort" "black" ];
        go = [ "goimports" "gofmt" ];
        bash = [ "shfmt" ];
        sh = [ "shfmt" ];
        yaml = [ "yamlfmt" ];
        "yaml.ansible" = [ "yamlfmt" ];
        toml = [ "taplo" ];
      };
      format_on_save = mkRaw ''
        function(bufnr)
          if vim.tbl_contains({ "helm" }, vim.bo[bufnr].filetype) then return end
          if vim.g.autoformat == false or vim.b[bufnr].autoformat == false then return end
          return { lsp_format = "fallback", timeout_ms = 500 }
        end
      '';
    };
  };
}
