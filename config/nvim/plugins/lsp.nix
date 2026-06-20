{ nixvimLib, ... }:
let
  mkRaw = nixvimLib.mkRaw;
in {
  programs.nixvim.plugins.lsp = {
    enable = true;
    inlayHints = true;
    onAttach = ''
      if client and client.server_capabilities.codeLensProvider then
        vim.lsp.codelens.enable(true, { bufnr = bufnr })
      end
    '';
    keymaps = {
      silent = true;
      lspBuf = {
        "K" = "hover";
        "gD" = "declaration";
        "gd" = "definition";
        "gK" = "signature_help";
        "gy" = "type_definition";
      };
      extra = [
        {
          key = "gr";
          action = mkRaw ''require("telescope.builtin").lsp_references'';
          options.desc = "LSP references";
        }
        {
          key = "gI";
          action = mkRaw ''require("telescope.builtin").lsp_implementations'';
          options.desc = "LSP implementations";
        }
        {
          key = "gl";
          action = mkRaw ''vim.diagnostic.open_float'';
          options.desc = "Hover diagnostics";
        }
        {
          key = "[d";
          action = mkRaw ''function() vim.diagnostic.jump({ count = -1, float = true }) end'';
          options.desc = "Previous diagnostic";
        }
        {
          key = "]d";
          action = mkRaw ''function() vim.diagnostic.jump({ count = 1, float = true }) end'';
          options.desc = "Next diagnostic";
        }
        {
          key = "[e";
          action = mkRaw ''function() vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.ERROR }) end'';
          options.desc = "Previous error";
        }
        {
          key = "]e";
          action = mkRaw ''function() vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.ERROR }) end'';
          options.desc = "Next error";
        }
        {
          key = "[w";
          action = mkRaw ''function() vim.diagnostic.jump({ count = -1, severity = vim.diagnostic.severity.WARN }) end'';
          options.desc = "Previous warning";
        }
        {
          key = "]w";
          action = mkRaw ''function() vim.diagnostic.jump({ count = 1, severity = vim.diagnostic.severity.WARN }) end'';
          options.desc = "Next warning";
        }
        {
          key = "<leader>la";
          action = mkRaw ''vim.lsp.buf.code_action'';
          options.desc = "LSP code action";
        }
        {
          mode = "x";
          key = "<leader>la";
          action = mkRaw ''vim.lsp.buf.code_action'';
          options.desc = "LSP code action";
        }
        {
          key = "<leader>lA";
          action = mkRaw ''function() vim.lsp.buf.code_action({ context = { only = { "source" }, diagnostics = {} } }) end'';
          options.desc = "LSP source action";
        }
        {
          key = "<leader>ld";
          action = mkRaw ''vim.diagnostic.open_float'';
          options.desc = "Hover diagnostics";
        }
        {
          key = "<leader>lD";
          action = mkRaw ''function() require("telescope.builtin").diagnostics({ bufnr = 0 }) end'';
          options.desc = "Search diagnostics";
        }
        {
          key = "<leader>lf";
          action = mkRaw ''function() require("conform").format({ async = true, lsp_format = "fallback" }) end'';
          options.desc = "Format buffer";
        }
        {
          key = "<leader>li";
          action = mkRaw ''function() vim.cmd.checkhealth("vim.lsp") end'';
          options.desc = "LSP information";
        }
        {
          key = "<leader>lh";
          action = mkRaw ''vim.lsp.buf.signature_help'';
          options.desc = "Signature help";
        }
        {
          key = "<leader>ll";
          action = mkRaw ''function() vim.lsp.codelens.enable(true) end'';
          options.desc = "LSP CodeLens refresh";
        }
        {
          key = "<leader>lL";
          action = mkRaw ''vim.lsp.codelens.run'';
          options.desc = "LSP CodeLens run";
        }
        {
          key = "<leader>lr";
          action = mkRaw ''vim.lsp.buf.rename'';
          options.desc = "Rename current symbol";
        }
        {
          key = "<leader>lR";
          action = mkRaw ''require("telescope.builtin").lsp_references'';
          options.desc = "Search references";
        }
        {
          key = "<leader>lG";
          action = mkRaw ''require("telescope.builtin").lsp_dynamic_workspace_symbols'';
          options.desc = "Search workspace symbols";
        }
        {
          key = "<leader>ls";
          action = mkRaw ''require("telescope.builtin").lsp_document_symbols'';
          options.desc = "Search symbols";
        }
        {
          key = "<leader>lS";
          action = mkRaw ''function() require("aerial").toggle() end'';
          options.desc = "Symbols outline";
        }
        {
          key = "<leader>uf";
          action = mkRaw ''function() _G.nixlab.toggle_buffer_autoformat() end'';
          options.desc = "Toggle autoformatting (buffer)";
        }
        {
          key = "<leader>uF";
          action = mkRaw ''function() _G.nixlab.toggle_global_autoformat() end'';
          options.desc = "Toggle autoformatting (global)";
        }
        {
          key = "<leader>uh";
          action = mkRaw ''function() _G.nixlab.toggle_buffer_inlay_hints() end'';
          options.desc = "Toggle LSP inlay hints (buffer)";
        }
        {
          key = "<leader>uH";
          action = mkRaw ''function() _G.nixlab.toggle_global_inlay_hints() end'';
          options.desc = "Toggle LSP inlay hints (global)";
        }
      ];
    };
    servers = {
      lua_ls = {
        enable = true;
        package = null;
        settings = {
          Lua = {
            diagnostics.globals = [ "vim" ];
            format.enable = false;
            telemetry.enable = false;
            workspace.checkThirdParty = false;
          };
        };
      };
      bashls = {
        enable = true;
        package = null;
      };
      basedpyright = {
        enable = true;
        package = null;
        settings = {
          basedpyright = {
            analysis = {
              autoImportCompletions = true;
              typeCheckingMode = "basic";
            };
          };
        };
      };
      ruff = {
        enable = true;
        package = null;
      };
      gopls = {
        enable = true;
        package = null;
      };
      helm_ls = {
        enable = true;
        package = null;
        filetypes = [ "helm" ];
      };
      jsonls = {
        enable = true;
        package = null;
      };
      nixd = {
        enable = true;
        package = null;
      };
      taplo = {
        enable = true;
        package = null;
      };
      yamlls = {
        enable = true;
        package = null;
        settings = {
          yaml = {
            keyOrdering = false;
          };
        };
      };
      ansiblels = {
        enable = true;
        package = null;
        cmd = [ "ansible-language-server" "--stdio" ];
        filetypes = [ "ansible" "yaml.ansible" ];
      };
    };
  };
}
