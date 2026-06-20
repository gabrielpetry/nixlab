{ nixvimLib, ... }:
let
  mkRaw = nixvimLib.mkRaw;
in {
  programs.nixvim.keymaps = [
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
}
