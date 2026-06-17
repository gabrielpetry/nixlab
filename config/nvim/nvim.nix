{ pkgs, nixvimLib, ... }:
let
  mkRaw = nixvimLib.mkRaw;

  diagramNvim = pkgs.vimUtils.buildVimPlugin {
    pname = "diagram.nvim";
    version = "2026-06-12";
    src = pkgs.fetchFromGitHub {
      owner = "3rd";
      repo = "diagram.nvim";
      rev = "a221810b17cdda2d5fdddba9bab3eba6fab8fabc";
      hash = "sha256-+K5o50CtBFqn37t6GnAnI1p2CfCyA1w4TIhMKpfZX4A=";
    };
    nvimRequireCheck = [
      "diagram.integrations.markdown"
      "diagram.renderers.d2"
      "diagram.renderers.gnuplot"
      "diagram.renderers.mermaid"
      "diagram.renderers.plantuml"
      "diagram.types"
    ];
  };
in
{
  xdg.configFile = {
    "nvim/after/queries/yaml/highlights.scm".source = ./after/queries/yaml/highlights.scm;
    "nvim/after/queries/yaml/injections.scm".source = ./after/queries/yaml/injections.scm;
    "nvim/after/queries/promql/highlights.scm".source = ./after/queries/promql/highlights.scm;
  };

  programs.nixvim = {
    enable = true;
    viAlias = true;
    vimAlias = true;
    nixpkgs.source = pkgs.path;

    globals = {
      mapleader = " ";
      maplocalleader = ",";
    };

    opts = {
      backspace = [ "indent" "eol" "start" "nostop" ];
      breakindent = true;
      clipboard = "unnamedplus";
      cmdheight = 0;
      completeopt = [ "menu" "menuone" "noselect" ];
      confirm = true;
      copyindent = true;
      cursorline = true;
      expandtab = true;
      ignorecase = true;
      infercase = true;
      laststatus = 3;
      linebreak = true;
      mouse = "a";
      number = true;
      preserveindent = true;
      pumheight = 10;
      relativenumber = true;
      scrolloff = 8;
      shiftround = true;
      shiftwidth = 0;
      showmode = false;
      showtabline = 2;
      sidescrolloff = 8;
      signcolumn = "yes";
      smartcase = true;
      smartindent = true;
      softtabstop = 2;
      splitbelow = true;
      splitright = true;
      tabclose = "uselast";
      tabstop = 2;
      termguicolors = true;
      timeoutlen = 500;
      title = true;
      undofile = true;
      updatetime = 300;
      virtualedit = "block";
      winborder = "rounded";
      wrap = false;
      writebackup = false;
      fillchars = {
        eob = " ";
      };
    };

    diagnostic.settings = {
      severity_sort = true;
      update_in_insert = false;
      virtual_text = {
        spacing = 2;
        source = "if_many";
      };
      float = {
        border = "rounded";
        source = "if_many";
      };
    };

    autoCmd = [
      {
        event = [ "BufRead" "BufNewFile" ];
        pattern = "*.yaml";
        callback = mkRaw ''
          function()
            local filepath = vim.fn.expand "%:p"
            if string.find(filepath, "/templates/") then vim.bo.filetype = "helm" end
          end
        '';
      }
      {
        event = [ "BufRead" "BufNewFile" ];
        pattern = "*.md";
        callback = mkRaw ''
          function()
            if vim.fn.exists(":RenderMarkdown") > 0 then vim.cmd "RenderMarkdown enable" end
          end
        '';
      }
      {
        event = "InsertEnter";
        pattern = "*.md";
        callback = mkRaw ''
          function()
            if vim.fn.exists(":RenderMarkdown") > 0 then vim.cmd "RenderMarkdown disable" end
          end
        '';
      }
      {
        event = "TextYankPost";
        pattern = "*";
        callback = mkRaw ''function() vim.hl.on_yank() end'';
      }
      {
        event = [ "FocusGained" "TermClose" "TermLeave" ];
        callback = mkRaw ''
          function()
            if vim.bo.buftype ~= "nofile" then vim.cmd "checktime" end
          end
        '';
      }
      {
        event = "BufWritePre";
        callback = mkRaw ''
          function(args)
            local file = args.match
            if file:match "^%w+:[\\/]" then return end
            vim.fn.mkdir(vim.fs.abspath(vim.fs.dirname(vim.uv.fs_realpath(file) or file)), "p")
          end
        '';
      }
      {
        event = "BufReadPost";
        callback = mkRaw ''
          function(args)
            local buf = args.buf
            if vim.b[buf].last_loc_restored or vim.tbl_contains({ "gitcommit" }, vim.bo[buf].filetype) then return end
            vim.b[buf].last_loc_restored = true
            local mark = vim.api.nvim_buf_get_mark(buf, '"')
            if mark[1] > 0 and mark[1] <= vim.api.nvim_buf_line_count(buf) then
              pcall(vim.api.nvim_win_set_cursor, 0, mark)
            end
          end
        '';
      }
      {
        event = "BufWinEnter";
        callback = mkRaw ''
          function(args)
            if not vim.g.q_close_windows then vim.g.q_close_windows = {} end
            if vim.g.q_close_windows[args.buf] then return end
            vim.g.q_close_windows[args.buf] = true
            for _, map in ipairs(vim.api.nvim_buf_get_keymap(args.buf, "n")) do
              if map.lhs == "q" then return end
            end
            if vim.tbl_contains({ "help", "nofile", "quickfix" }, vim.bo[args.buf].buftype) then
              vim.keymap.set("n", "q", "<Cmd>close<CR>", {
                desc = "Close window",
                buffer = args.buf,
                silent = true,
                nowait = true,
              })
            end
          end
        '';
      }
      {
        event = "BufDelete";
        callback = mkRaw ''
          function(args)
            if vim.g.q_close_windows then vim.g.q_close_windows[args.buf] = nil end
          end
        '';
      }
      {
        event = "BufEnter";
        callback = mkRaw ''
          function()
            local wins = vim.api.nvim_tabpage_list_wins(0)
            if #wins == 1 and vim.bo[vim.api.nvim_win_get_buf(wins[1])].filetype ~= "aerial" then return end
            local sidebar_fts = { aerial = true, ["neo-tree"] = true }
            for _, winid in ipairs(wins) do
              if vim.api.nvim_win_is_valid(winid) then
                local bufnr = vim.api.nvim_win_get_buf(winid)
                local filetype = vim.bo[bufnr].filetype
                if not sidebar_fts[filetype] then
                  return
                else
                  sidebar_fts[filetype] = nil
                end
              end
            end
            if #vim.api.nvim_list_tabpages() > 1 then
              vim.cmd.tabclose()
            else
              vim.cmd.qall()
            end
          end
        '';
      }
    ];

    keymaps = [
      {
        mode = [ "n" "x" ];
        key = "j";
        action = "v:count == 0 ? 'gj' : 'j'";
        options = {
          expr = true;
          silent = true;
          desc = "Move cursor down";
        };
      }
      {
        mode = [ "n" "x" ];
        key = "k";
        action = "v:count == 0 ? 'gk' : 'k'";
        options = {
          expr = true;
          silent = true;
          desc = "Move cursor up";
        };
      }
      {
        mode = "n";
        key = "<leader>w";
        action = "<Cmd>w<CR>";
        options.desc = "Save";
      }
      {
        mode = "n";
        key = "<leader>q";
        action = "<Cmd>confirm q<CR>";
        options.desc = "Quit Window";
      }
      {
        mode = "n";
        key = "<leader>Q";
        action = "<Cmd>confirm qall<CR>";
        options.desc = "Quit Neovim";
      }
      {
        mode = "n";
        key = "<leader>n";
        action = "<Cmd>enew<CR>";
        options.desc = "New File";
      }
      {
        mode = "n";
        key = "|";
        action = "<Cmd>vsplit<CR>";
        options.desc = "Vertical Split";
      }
      {
        mode = "n";
        key = "\\";
        action = "<Cmd>split<CR>";
        options.desc = "Horizontal Split";
      }
      {
        mode = "n";
        key = "<leader>/";
        action = "gcc";
        options = {
          remap = true;
          desc = "Toggle comment line";
        };
      }
      {
        mode = "x";
        key = "<leader>/";
        action = "gc";
        options = {
          remap = true;
          desc = "Toggle comment";
        };
      }
      {
        mode = "n";
        key = "gco";
        action = "o<Esc>Vcx<Esc><Cmd>normal gcc<CR>fxa<BS>";
        options.desc = "Add Comment Below";
      }
      {
        mode = "n";
        key = "gcO";
        action = "O<Esc>Vcx<Esc><Cmd>normal gcc<CR>fxa<BS>";
        options.desc = "Add Comment Above";
      }
      {
        mode = [ "n" "i" "t" ];
        key = "<C-h>";
        action = mkRaw ''function() require("smart-splits").move_cursor_left() end'';
        options = {
          silent = true;
          desc = "Move to left split";
        };
      }
      {
        mode = [ "n" "i" "t" ];
        key = "<C-j>";
        action = mkRaw ''function() require("smart-splits").move_cursor_down() end'';
        options = {
          silent = true;
          desc = "Move to below split";
        };
      }
      {
        mode = [ "n" "i" "t" ];
        key = "<C-k>";
        action = mkRaw ''function() require("smart-splits").move_cursor_up() end'';
        options = {
          silent = true;
          desc = "Move to above split";
        };
      }
      {
        mode = [ "n" "i" "t" ];
        key = "<C-l>";
        action = mkRaw ''function() require("smart-splits").move_cursor_right() end'';
        options = {
          silent = true;
          desc = "Move to right split";
        };
      }
      {
        mode = "n";
        key = "<C-Up>";
        action = mkRaw ''function() require("smart-splits").resize_up() end'';
        options = {
          silent = true;
          desc = "Resize split up";
        };
      }
      {
        mode = "n";
        key = "<C-Down>";
        action = mkRaw ''function() require("smart-splits").resize_down() end'';
        options = {
          silent = true;
          desc = "Resize split down";
        };
      }
      {
        mode = "n";
        key = "<C-Left>";
        action = mkRaw ''function() require("smart-splits").resize_left() end'';
        options = {
          silent = true;
          desc = "Resize split left";
        };
      }
      {
        mode = "n";
        key = "<C-Right>";
        action = mkRaw ''function() require("smart-splits").resize_right() end'';
        options = {
          silent = true;
          desc = "Resize split right";
        };
      }
      {
        mode = "n";
        key = "<C-Q>";
        action = "<Esc><Cmd>ToggleTerm direction=float<CR>";
        options = {
          silent = true;
          desc = "Toggle floating terminal";
        };
      }
      {
        mode = "i";
        key = "<C-Q>";
        action = "<Esc><Cmd>ToggleTerm direction=float<CR>";
        options = {
          silent = true;
          desc = "Toggle floating terminal";
        };
      }
      {
        mode = "t";
        key = "<C-Q>";
        action = "<Cmd>ToggleTerm direction=float<CR>";
        options = {
          silent = true;
          desc = "Toggle floating terminal";
        };
      }
      {
        mode = [ "n" "i" "t" ];
        key = "<F7>";
        action = "<Esc><Cmd>ToggleTerm<CR>";
        options = {
          silent = true;
          desc = "Toggle terminal";
        };
      }
      {
        mode = [ "n" "i" ];
        key = "<C-;>";
        action = "<Cmd>Twilight<CR>";
        options = {
          silent = true;
          desc = "Toggle Twilight";
        };
      }
      {
        mode = "v";
        key = ">";
        action = ">gv";
        options = {
          silent = true;
          desc = "Indent and keep selection";
        };
      }
      {
        mode = "v";
        key = "<";
        action = "<gv";
        options = {
          silent = true;
          desc = "Outdent and keep selection";
        };
      }
      {
        mode = "n";
        key = "[b";
        action = "<Cmd>BufferLineCyclePrev<CR>";
        options = {
          silent = true;
          desc = "Previous buffer";
        };
      }
      {
        mode = "n";
        key = "]b";
        action = "<Cmd>BufferLineCycleNext<CR>";
        options = {
          silent = true;
          desc = "Next buffer";
        };
      }
      {
        mode = "n";
        key = "<b";
        action = "<Cmd>BufferLineMovePrev<CR>";
        options = {
          silent = true;
          desc = "Move buffer left";
        };
      }
      {
        mode = "n";
        key = ">b";
        action = "<Cmd>BufferLineMoveNext<CR>";
        options = {
          silent = true;
          desc = "Move buffer right";
        };
      }
      {
        mode = "n";
        key = "<S-h>";
        action = "<Cmd>BufferLineCyclePrev<CR>";
        options = {
          silent = true;
          desc = "Previous buffer";
        };
      }
      {
        mode = "n";
        key = "<S-l>";
        action = "<Cmd>BufferLineCycleNext<CR>";
        options = {
          silent = true;
          desc = "Next buffer";
        };
      }
      {
        mode = "n";
        key = "<leader>c";
        action = "<Cmd>bdelete<CR>";
        options.desc = "Close buffer";
      }
      {
        mode = "n";
        key = "<leader>C";
        action = "<Cmd>bdelete!<CR>";
        options.desc = "Force close buffer";
      }
      {
        mode = "n";
        key = "<leader>bp";
        action = "<Cmd>BufferLineCyclePrev<CR>";
        options.desc = "Previous buffer";
      }
      {
        mode = "n";
        key = "<leader>bP";
        action = "<Cmd>BufferLinePick<CR>";
        options.desc = "Pick buffer";
      }
      {
        mode = "n";
        key = "<leader>bd";
        action = "<Cmd>bdelete<CR>";
        options.desc = "Delete buffer";
      }
      {
        mode = "n";
        key = "<leader>e";
        action = "<Cmd>Neotree toggle<CR>";
        options.desc = "Toggle Explorer";
      }
      {
        mode = "n";
        key = "<leader>o";
        action = mkRaw ''function() _G.nixlab.toggle_explorer_focus() end'';
        options.desc = "Toggle Explorer Focus";
      }
      {
        mode = "n";
        key = "<leader>h";
        action = mkRaw ''function() _G.nixlab.home() end'';
        options.desc = "Home Screen";
      }
      {
        mode = "n";
        key = "<leader>f<CR>";
        action = "<Cmd>Telescope resume<CR>";
        options.desc = "Resume search";
      }
      {
        mode = "n";
        key = "<leader>fa";
        action = mkRaw ''function() _G.nixlab.find_config_files() end'';
        options.desc = "Find config files";
      }
      {
        mode = "n";
        key = "<leader>fb";
        action = "<Cmd>Telescope buffers<CR>";
        options.desc = "Find buffers";
      }
      {
        mode = "n";
        key = "<leader>fc";
        action = "<Cmd>Telescope grep_string<CR>";
        options.desc = "Find word under cursor";
      }
      {
        mode = "n";
        key = "<leader>fC";
        action = "<Cmd>Telescope commands<CR>";
        options.desc = "Find commands";
      }
      {
        mode = "n";
        key = "<leader>ff";
        action = mkRaw ''function() require("telescope.builtin").find_files({ hidden = vim.fn.isdirectory(".git") == 1 }) end'';
        options.desc = "Find files";
      }
      {
        mode = "n";
        key = "<leader>fF";
        action = mkRaw ''function() require("telescope.builtin").find_files({ hidden = true, no_ignore = true, follow = true }) end'';
        options.desc = "Find all files";
      }
      {
        mode = "n";
        key = "<leader>fg";
        action = mkRaw ''function() _G.nixlab.git_files() end'';
        options.desc = "Find git files";
      }
      {
        mode = "n";
        key = "<leader>fh";
        action = "<Cmd>Telescope help_tags<CR>";
        options.desc = "Find help";
      }
      {
        mode = "n";
        key = "<leader>fk";
        action = "<Cmd>Telescope keymaps<CR>";
        options.desc = "Find keymaps";
      }
      {
        mode = "n";
        key = "<leader>fm";
        action = "<Cmd>Telescope man_pages<CR>";
        options.desc = "Find man";
      }
      {
        mode = "n";
        key = "<leader>fo";
        action = "<Cmd>Telescope oldfiles<CR>";
        options.desc = "Find old files";
      }
      {
        mode = "n";
        key = "<leader>fO";
        action = mkRaw ''function() _G.nixlab.find_oldfiles_cwd() end'';
        options.desc = "Find old files (cwd)";
      }
      {
        mode = "n";
        key = "<leader>fr";
        action = "<Cmd>Telescope registers<CR>";
        options.desc = "Find registers";
      }
      {
        mode = "n";
        key = "<leader>ft";
        action = "<Cmd>Telescope colorscheme<CR>";
        options.desc = "Find themes";
      }
      {
        mode = "n";
        key = "<leader>fw";
        action = "<Cmd>Telescope live_grep<CR>";
        options.desc = "Find words";
      }
      {
        mode = "n";
        key = "<leader>fW";
        action = mkRaw ''function() require("telescope.builtin").live_grep({ additional_args = function() return { "--hidden", "--no-ignore" } end }) end'';
        options.desc = "Find words in all files";
      }
      {
        mode = "n";
        key = "<leader>gb";
        action = mkRaw ''function() require("gitsigns").blame_line({ full = true }) end'';
        options.desc = "Git blame line";
      }
      {
        mode = "n";
        key = "<leader>gc";
        action = "<Cmd>Telescope git_commits<CR>";
        options.desc = "Git commits";
      }
      {
        mode = "n";
        key = "<leader>gC";
        action = "<Cmd>Telescope git_bcommits<CR>";
        options.desc = "Git commits (current file)";
      }
      {
        mode = "n";
        key = "<leader>gt";
        action = "<Cmd>Telescope git_status<CR>";
        options.desc = "Git status";
      }
      {
        mode = "n";
        key = "<leader>gg";
        action = mkRaw ''function() _G.nixlab.toggle_lazygit() end'';
        options.desc = "Lazygit";
      }
      {
        mode = "n";
        key = "<leader>tf";
        action = "<Cmd>ToggleTerm direction=float<CR>";
        options.desc = "Terminal float";
      }
      {
        mode = "n";
        key = "<leader>th";
        action = "<Cmd>ToggleTerm size=10 direction=horizontal<CR>";
        options.desc = "Terminal horizontal";
      }
      {
        mode = "n";
        key = "<leader>tv";
        action = "<Cmd>ToggleTerm size=80 direction=vertical<CR>";
        options.desc = "Terminal vertical";
      }
      {
        mode = "n";
        key = "<leader>tl";
        action = mkRaw ''function() _G.nixlab.toggle_lazygit() end'';
        options.desc = "Lazygit";
      }
      {
        mode = "n";
        key = "<leader>xq";
        action = "<Cmd>copen<CR>";
        options.desc = "Quickfix list";
      }
      {
        mode = "n";
        key = "<leader>xl";
        action = "<Cmd>lopen<CR>";
        options.desc = "Location list";
      }
      {
        mode = "n";
        key = "[t";
        action = "<Cmd>tabprevious<CR>";
        options.desc = "Previous tab";
      }
      {
        mode = "n";
        key = "]t";
        action = "<Cmd>tabnext<CR>";
        options.desc = "Next tab";
      }
      {
        mode = "n";
        key = "[y";
        action = mkRaw ''function() require("aerial").prev(vim.v.count1) end'';
        options.desc = "Previous symbol";
      }
      {
        mode = "n";
        key = "]y";
        action = mkRaw ''function() require("aerial").next(vim.v.count1) end'';
        options.desc = "Next symbol";
      }
      {
        mode = "n";
        key = "[Y";
        action = mkRaw ''function() require("aerial").prev_up(vim.v.count1) end'';
        options.desc = "Previous symbol upwards";
      }
      {
        mode = "n";
        key = "]Y";
        action = mkRaw ''function() require("aerial").next_up(vim.v.count1) end'';
        options.desc = "Next symbol upwards";
      }
      {
        mode = "n";
        key = "<leader>ud";
        action = mkRaw ''function() _G.nixlab.toggle_diagnostics() end'';
        options.desc = "Toggle diagnostics";
      }
      {
        mode = "n";
        key = "<leader>ug";
        action = mkRaw ''function() _G.nixlab.toggle_signcolumn() end'';
        options.desc = "Toggle signcolumn";
      }
      {
        mode = "n";
        key = "<leader>un";
        action = mkRaw ''function() _G.nixlab.toggle_number() end'';
        options.desc = "Toggle line numbers";
      }
      {
        mode = "n";
        key = "<leader>uv";
        action = mkRaw ''function() _G.nixlab.toggle_virtual_text() end'';
        options.desc = "Toggle virtual text";
      }
      {
        mode = "n";
        key = "<leader>uw";
        action = mkRaw ''function() _G.nixlab.toggle_wrap() end'';
        options.desc = "Toggle wrap";
      }
      {
        mode = "n";
        key = "<leader>uT";
        action = "<Cmd>Twilight<CR>";
        options.desc = "Toggle Twilight";
      }
    ];

    colorschemes.catppuccin = {
      enable = true;
      settings.flavour = "frappe";
    };

    extraPlugins = [
      diagramNvim
      pkgs.vimPlugins.image-nvim
    ];

    extraConfigLuaPre = ''
      vim.g.loaded_netrw = 1
      vim.g.loaded_netrwPlugin = 1
      vim.g.smart_splits_multiplexer_integration = (vim.env.TMUX and vim.env.TMUX ~= "") and "tmux" or false
    '';

    extraConfigLuaPost = ''
      vim.treesitter.query.set("markdown", "injections", "")
      vim.treesitter.query.set("markdown_inline", "injections", "")

      do
        local ok, ts_helpers = pcall(require, "aerial.backends.treesitter.helpers")
        if ok then
          ts_helpers.range_from_nodes = function(start_node, end_node)
            local row, col = start_node:range()
            local _, _, end_row, end_col = end_node:range()
            return {
              lnum = row + 1,
              end_lnum = end_row + 1,
              col = col,
              end_col = end_col,
            }
          end
        end
      end

      _G.nixlab = _G.nixlab or {}
      vim.g.autoformat = vim.F.if_nil(vim.g.autoformat, true)
      vim.g.inlay_hints_enabled = vim.F.if_nil(vim.g.inlay_hints_enabled, true)

      local function set_tmux_vim_flag(value)
        if not vim.env.TMUX or vim.env.TMUX == "" then return end
        local cmd = { "tmux", "set-option", "-p", "@pane-is-vim", value and "1" or "0" }
        if vim.system then
          vim.system(cmd, { text = true }, function() end)
        else
          vim.fn.system(cmd)
        end
      end

      vim.api.nvim_create_autocmd({ "VimEnter", "BufEnter", "WinEnter" }, {
        callback = function() set_tmux_vim_flag(true) end,
      })
      vim.api.nvim_create_autocmd({ "VimLeavePre" }, {
        callback = function() set_tmux_vim_flag(false) end,
      })
      set_tmux_vim_flag(true)

      local function notify_toggle(name, enabled)
        vim.notify(("%s %s"):format(name, enabled and "enabled" or "disabled"), vim.log.levels.INFO)
      end

      _G.nixlab.toggle_diagnostics = function()
        local enabled = vim.diagnostic.is_enabled == nil and true or vim.diagnostic.is_enabled()
        vim.diagnostic.enable(not enabled)
        notify_toggle("Diagnostics", not enabled)
      end

      _G.nixlab.toggle_signcolumn = function()
        vim.wo.signcolumn = vim.wo.signcolumn == "no" and "yes" or "no"
        notify_toggle("Signcolumn", vim.wo.signcolumn ~= "no")
      end

      _G.nixlab.toggle_number = function()
        if vim.wo.number and vim.wo.relativenumber then
          vim.wo.relativenumber = false
          notify_toggle("Relative number", false)
        elseif vim.wo.number then
          vim.wo.number = false
          notify_toggle("Line numbers", false)
        else
          vim.wo.number = true
          vim.wo.relativenumber = true
          notify_toggle("Line numbers", true)
        end
      end

      _G.nixlab.toggle_virtual_text = function()
        local config = vim.diagnostic.config()
        local enabled = config.virtual_text ~= false
        vim.diagnostic.config({ virtual_text = enabled and false or { spacing = 2, source = "if_many" } })
        notify_toggle("Virtual text", not enabled)
      end

      _G.nixlab.toggle_wrap = function()
        vim.wo.wrap = not vim.wo.wrap
        notify_toggle("Wrap", vim.wo.wrap)
      end

      _G.nixlab.toggle_buffer_autoformat = function()
        local enabled = vim.F.if_nil(vim.b.autoformat, true)
        vim.b.autoformat = not enabled
        notify_toggle("Buffer autoformat", not enabled)
      end

      _G.nixlab.toggle_global_autoformat = function()
        vim.g.autoformat = not vim.F.if_nil(vim.g.autoformat, true)
        notify_toggle("Global autoformat", vim.g.autoformat)
      end

      _G.nixlab.toggle_buffer_inlay_hints = function()
        if not vim.lsp.inlay_hint then return end
        local enabled = vim.lsp.inlay_hint.is_enabled and vim.lsp.inlay_hint.is_enabled({ bufnr = 0 }) or false
        vim.lsp.inlay_hint.enable(not enabled, { bufnr = 0 })
        notify_toggle("Buffer inlay hints", not enabled)
      end

      _G.nixlab.toggle_global_inlay_hints = function()
        if not vim.lsp.inlay_hint then return end
        vim.g.inlay_hints_enabled = not vim.F.if_nil(vim.g.inlay_hints_enabled, true)
        for _, buf in ipairs(vim.api.nvim_list_bufs()) do
          if vim.api.nvim_buf_is_loaded(buf) then
            pcall(vim.lsp.inlay_hint.enable, vim.g.inlay_hints_enabled, { bufnr = buf })
          end
        end
        notify_toggle("Global inlay hints", vim.g.inlay_hints_enabled)
      end

      _G.nixlab.toggle_explorer_focus = function()
        if vim.bo.filetype == "neo-tree" then
          vim.cmd.wincmd "p"
        else
          vim.cmd.Neotree "focus"
        end
      end

      _G.nixlab.home = function()
        if vim.bo.filetype == "alpha" then
          vim.cmd.enew()
        else
          vim.cmd.Alpha()
        end
      end

      _G.nixlab.find_config_files = function() require("telescope.builtin").find_files({ cwd = vim.fn.stdpath("config") }) end
      _G.nixlab.find_oldfiles_cwd = function() require("telescope.builtin").oldfiles({ cwd_only = true }) end
      _G.nixlab.git_files = function()
        local builtin = require "telescope.builtin"
        local ok = pcall(builtin.git_files)
        if not ok then builtin.find_files() end
      end

      do
        local lazygit_term
        _G.nixlab.toggle_lazygit = function()
          if vim.fn.executable("lazygit") ~= 1 then return end
          local Terminal = require("toggleterm.terminal").Terminal
          if not lazygit_term then lazygit_term = Terminal:new({ cmd = "lazygit", direction = "float", hidden = true }) end
          lazygit_term:toggle()
        end
      end

      if vim.env.WSL_DISTRO_NAME == "Ubuntu" then
        vim.g.clipboard = {
          name = "win32yank-wsl",
          copy = {
            ["+"] = "/mnt/c/win32yank.exe -i",
            ["*"] = "/mnt/c/win32yank.exe -i",
          },
          paste = {
            ["+"] = "/mnt/c/win32yank.exe -o",
            ["*"] = "/mnt/c/win32yank.exe -o",
          },
          cache_enabled = 0,
        }
        vim.opt.clipboard = "unnamedplus"
      end

      local image_ok, image = pcall(require, "image")
      if image_ok then image.setup({}) end

      local diagram_ok, diagram = pcall(require, "diagram")
      if diagram_ok then
        diagram.setup({
          events = {
            render_buffer = { "InsertLeave", "BufWinEnter", "TextChanged" },
            clear_buffer = { "BufLeave" },
          },
          renderer_options = {
            mermaid = {
              background = nil,
              theme = nil,
              scale = 1,
              width = nil,
              height = nil,
            },
            plantuml = {
              charset = nil,
            },
            d2 = {
              theme_id = nil,
              dark_theme_id = nil,
              scale = nil,
              layout = nil,
              sketch = nil,
            },
            gnuplot = {
              size = nil,
              font = nil,
              theme = nil,
            },
          },
        })
      end

      local wk_ok, wk = pcall(require, "which-key")
      if wk_ok then
        wk.add({
          { "<leader>b", group = "Buffers" },
          { "<leader>f", group = "Find" },
          { "<leader>g", group = "Git" },
          { "<leader>l", group = "LSP" },
          { "<leader>t", group = "Terminal" },
          { "<leader>u", group = "UI" },
          { "<leader>x", group = "Lists" },
        })
      end
    '';

    plugins = {
      alpha = {
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
      web-devicons.enable = true;
      which-key.enable = true;
      comment.enable = true;
      gitsigns.enable = true;
      luasnip.enable = true;
      friendly-snippets.enable = true;
      twilight.enable = true;
      visual-multi.enable = true;
      render-markdown.enable = true;
      rainbow-delimiters.enable = true;
      indent-blankline.enable = true;

      lualine = {
        enable = true;
        settings.options = {
          globalstatus = true;
          theme = "auto";
          section_separators = {
            left = "";
            right = "";
          };
          component_separators = {
            left = "";
            right = "";
          };
          disabled_filetypes = {
            statusline = [ "alpha" ];
          };
        };
      };

      bufferline = {
        enable = true;
        settings.options = {
          always_show_bufferline = true;
          diagnostics = "nvim_lsp";
          separator_style = "slant";
          offsets = [
            {
              filetype = "neo-tree";
              text = "Explorer";
              highlight = "Directory";
              text_align = "left";
            }
          ];
        };
      };

      neo-tree = {
        enable = true;
        settings = {
          close_if_last_window = true;
          auto_clean_after_session_restore = true;
          log_to_file = false;
          popup_border_style = "rounded";
          sources = [ "filesystem" "buffers" "git_status" ];
          source_selector = {
            winbar = true;
            content_layout = "center";
            sources = [
              {
                source = "filesystem";
                display_name = "  File ";
              }
              {
                source = "buffers";
                display_name = "  Bufs ";
              }
              {
                source = "git_status";
                display_name = "  Git ";
              }
            ];
          };
          default_component_configs = {
            indent = {
              padding = 0;
              expander_collapsed = "";
              expander_expanded = "";
            };
            icon = {
              folder_closed = "";
              folder_open = "";
              folder_empty = "";
              folder_empty_open = "";
              default = "";
            };
            modified.symbol = "";
            git_status.symbols = {
              added = "✚";
              deleted = "✖";
              modified = "";
              renamed = "";
              untracked = "";
              ignored = "";
              unstaged = "";
              staged = "";
              conflict = "";
            };
          };
          filesystem = {
            follow_current_file = {
              enabled = true;
              leave_dirs_open = true;
            };
            hijack_netrw_behavior = "open_current";
            use_libuv_file_watcher = true;
          };
          window = {
            width = 30;
            mappings = {
              "<Space>" = false;
              "[b" = "prev_source";
              "]b" = "next_source";
              "Y" = "copy_to_clipboard";
              "h" = "close_node";
              "l" = "open";
            };
          };
        };
      };

      telescope = {
        enable = true;
        extensions.fzf-native.enable = true;
        settings.defaults = {
          prompt_prefix = "   ";
          selection_caret = "  ";
          sorting_strategy = "ascending";
          path_display = [ "smart" ];
          layout_config.horizontal = {
            prompt_position = "top";
            preview_width = 0.55;
          };
        };
      };

      treesitter = {
        enable = true;
        highlight = {
          enable = true;
          disable = [ "markdown" "markdown_inline" ];
        };
        indent.enable = true;
        grammarPackages = with pkgs.vimPlugins.nvim-treesitter.builtGrammars; [
          bash
          go
          helm
          json
          lua
          markdown
          markdown_inline
          nix
          promql
          python
          query
          regex
          toml
          vim
          vimdoc
          yaml
        ];
      };

      toggleterm = {
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

      smart-splits = {
        enable = true;
        settings = {
          ignored_filetypes = [ "nofile" "quickfix" "qf" "prompt" ];
          ignored_buftypes = [ "nofile" ];
          at_edge = "wrap";
          cursor_follows_swapped_bufs = true;
          multiplexer_integration = mkRaw ''(vim.env.TMUX and vim.env.TMUX ~= "") and "tmux" or false'';
        };
      };

      blink-cmp = {
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

      auto-session = {
        enable = true;
        settings = {
          auto_save = true;
          auto_restore = true;
          auto_create = true;
          auto_restore_last_session = true;
          bypass_save_filetypes = [ "gitcommit" "gitrebase" ];
        };
      };

      copilot-chat.enable = true;

      aerial = {
        enable = true;
        settings = {
          attach_mode = "global";
          backends = [ "lsp" "treesitter" "markdown" "man" ];
          layout.min_width = 28;
          show_guides = true;
          filter_kind = false;
          guides = {
            mid_item = "├ ";
            last_item = "└ ";
            nested_top = "│ ";
            whitespace = "  ";
          };
          keymaps = {
            "[y" = "actions.prev";
            "]y" = "actions.next";
            "[Y" = "actions.prev_up";
            "]Y" = "actions.next_up";
            "{" = false;
            "}" = false;
            "[[" = false;
            "]]" = false;
          };
        };
      };

      conform-nvim = {
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

      lint = {
        enable = true;
        lintersByFt = {
          lua = [ "selene" ];
          python = [ "ruff" ];
          bash = [ "shellcheck" ];
          sh = [ "shellcheck" ];
          yaml = [ "yamllint" ];
          "yaml.ansible" = [ "ansible_lint" ];
          ansible = [ "ansible_lint" ];
        };
      };

      lsp = {
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
    };
  };

  home.packages = with pkgs; [
    gcc
    stylua
    gnumake
    imagemagick
    gnuplot
    lua
    luarocks
    ruff
    basedpyright
    selene
    delve
    isort
    black
    pyrefly
    ansible-lint
    python3Packages.debugpy
    python3Packages.ty
    pkgs."ansible-language-server"
    pkgs."bash-language-server"
    gopls
    pkgs."helm-ls"
    pkgs."lua-language-server"
    taplo
    yamlfmt
    yamllint
    pkgs."yaml-language-server"
    pkgs."vscode-langservers-extracted"
  ];
}
