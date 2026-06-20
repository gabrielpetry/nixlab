{ nixvimLib, ... }:
let
  mkRaw = nixvimLib.mkRaw;
in
{
  programs.nixvim.keymaps = [
    {
      mode = [
        "n"
        "i"
      ];
      key = "<C-s>";
      action = "<Esc><Cmd>write!<CR>i";
      options = {
        silent = true;
        desc = "Force write";
      };
    }
    {
      mode = [
        "n"
        "i"
      ];
      key = "<C-q>";
      action = "<Esc><Cmd>quit!<CR>";
      options = {
        silent = true;
        desc = "Force quit";
      };
    }
    {
      mode = "n";
      key = "<leader>R";
      action = mkRaw "function() _G.nixlab.rename_current_file() end";
      options.desc = "Rename current file";
    }
    {
      mode = [
        "n"
        "x"
      ];
      key = "j";
      action = "v:count == 0 ? 'gj' : 'j'";
      options = {
        expr = true;
        silent = true;
        desc = "Move cursor down";
      };
    }
    {
      mode = [
        "n"
        "x"
      ];
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
      key = "bb";
      action = "<Cmd>BufferLinePick<CR>";
      options.desc = "Pick buffer";
    }
    {
      mode = "n";
      key = "bc";
      action = "<Cmd>BufferLineCloseOthers<CR>";
      options.desc = "Close other buffers";
    }
    {
      mode = "n";
      key = "bC";
      action = mkRaw "function() _G.nixlab.close_all_buffers() end";
      options.desc = "Close all buffers";
    }
    {
      mode = "n";
      key = "bse";
      action = "<Cmd>BufferLineSortByExtension<CR>";
      options.desc = "Sort buffers by extension";
    }
    {
      mode = "n";
      key = "bsi";
      action = "<Cmd>BufferLineSortByTabs<CR>";
      options.desc = "Sort buffers by buffer number";
    }
    {
      mode = "n";
      key = "bsp";
      action = "<Cmd>BufferLineSortByDirectory<CR>";
      options.desc = "Sort buffers by path";
    }
    {
      mode = "n";
      key = "bsr";
      action = "<Cmd>BufferLineSortByRelativeDirectory<CR>";
      options.desc = "Sort buffers by relative path";
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
      key = "b\\";
      action = mkRaw ''function() _G.nixlab.pick_buffer_in_split("split") end'';
      options.desc = "Pick buffer (horizontal split)";
    }
    {
      mode = "n";
      key = "b|";
      action = mkRaw ''function() _G.nixlab.pick_buffer_in_split("vsplit") end'';
      options.desc = "Pick buffer (vertical split)";
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
      mode = [
        "n"
        "i"
        "t"
      ];
      key = "<C-h>";
      action = mkRaw ''function() require("smart-splits").move_cursor_left() end'';
      options = {
        silent = true;
        desc = "Move to left split";
      };
    }
    {
      mode = [
        "n"
        "i"
        "t"
      ];
      key = "<C-j>";
      action = mkRaw ''function() require("smart-splits").move_cursor_down() end'';
      options = {
        silent = true;
        desc = "Move to below split";
      };
    }
    {
      mode = [
        "n"
        "i"
        "t"
      ];
      key = "<C-k>";
      action = mkRaw ''function() require("smart-splits").move_cursor_up() end'';
      options = {
        silent = true;
        desc = "Move to above split";
      };
    }
    {
      mode = [
        "n"
        "i"
        "t"
      ];
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
      mode = [
        "n"
        "i"
        "t"
      ];
      key = "<F7>";
      action = "<Esc><Cmd>ToggleTerm<CR>";
      options = {
        silent = true;
        desc = "Toggle terminal";
      };
    }
    {
      mode = [
        "n"
        "i"
        "t"
      ];
      key = "<C-'>";
      action = "<Esc><Cmd>ToggleTerm<CR>";
      options = {
        silent = true;
        desc = "Toggle terminal";
      };
    }
    {
      mode = [
        "n"
        "i"
      ];
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
      action = "<Cmd>BufferLinePickClose<CR>";
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
      action = mkRaw "function() _G.nixlab.toggle_explorer_focus() end";
      options.desc = "Toggle Explorer Focus";
    }
    {
      mode = "n";
      key = "<leader>h";
      action = mkRaw "function() _G.nixlab.home() end";
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
      action = mkRaw "function() _G.nixlab.find_config_files() end";
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
      action = mkRaw "function() _G.nixlab.git_files() end";
      options.desc = "Find git files";
    }
    {
      mode = "n";
      key = "<leader>f'";
      action = "<Cmd>Telescope marks<CR>";
      options.desc = "Find marks";
    }
    {
      mode = "n";
      key = "<leader>fl";
      action = "<Cmd>Telescope current_buffer_fuzzy_find<CR>";
      options.desc = "Find lines";
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
      action = mkRaw "function() _G.nixlab.find_oldfiles_cwd() end";
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
      action = "<Cmd>Telescope git_branches<CR>";
      options.desc = "Git branches";
    }
    {
      mode = "n";
      key = "<leader>gB";
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
      action = mkRaw "function() _G.nixlab.toggle_lazygit() end";
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
      action = mkRaw "function() _G.nixlab.toggle_lazygit() end";
      options.desc = "Lazygit";
    }
    {
      mode = "n";
      key = "<leader>tn";
      action = mkRaw "function() _G.nixlab.toggle_node() end";
      options.desc = "Node terminal";
    }
    {
      mode = "n";
      key = "<leader>tp";
      action = mkRaw "function() _G.nixlab.toggle_python() end";
      options.desc = "Python terminal";
    }
    {
      mode = "n";
      key = "<leader>tt";
      action = mkRaw "function() _G.nixlab.toggle_btm() end";
      options.desc = "btm terminal";
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
      key = "[q";
      action = "<Cmd>cprev<CR>";
      options.desc = "Previous quickfix";
    }
    {
      mode = "n";
      key = "]q";
      action = "<Cmd>cnext<CR>";
      options.desc = "Next quickfix";
    }
    {
      mode = "n";
      key = "[Q";
      action = "<Cmd>cfirst<CR>";
      options.desc = "First quickfix";
    }
    {
      mode = "n";
      key = "]Q";
      action = "<Cmd>clast<CR>";
      options.desc = "Last quickfix";
    }
    {
      mode = "n";
      key = "[l";
      action = "<Cmd>lprev<CR>";
      options.desc = "Previous location list";
    }
    {
      mode = "n";
      key = "]l";
      action = "<Cmd>lnext<CR>";
      options.desc = "Next location list";
    }
    {
      mode = "n";
      key = "[L";
      action = "<Cmd>lfirst<CR>";
      options.desc = "First location list";
    }
    {
      mode = "n";
      key = "]L";
      action = "<Cmd>llast<CR>";
      options.desc = "Last location list";
    }
    {
      mode = "n";
      key = "<leader>ud";
      action = mkRaw "function() _G.nixlab.toggle_diagnostics() end";
      options.desc = "Toggle diagnostics";
    }
    {
      mode = "n";
      key = "<leader>ub";
      action = mkRaw "function() _G.nixlab.toggle_background() end";
      options.desc = "Toggle background";
    }
    {
      mode = "n";
      key = "<leader>u>";
      action = mkRaw "function() _G.nixlab.toggle_foldcolumn() end";
      options.desc = "Toggle foldcolumn";
    }
    {
      mode = "n";
      key = "<leader>ui";
      action = mkRaw "function() _G.nixlab.toggle_indent_setting() end";
      options.desc = "Toggle indent setting";
    }
    {
      mode = "n";
      key = "<leader>u|";
      action = mkRaw "function() _G.nixlab.toggle_indent_guides() end";
      options.desc = "Toggle indent guides";
    }
    {
      mode = "n";
      key = "<leader>ul";
      action = mkRaw "function() _G.nixlab.toggle_statusline() end";
      options.desc = "Toggle statusline";
    }
    {
      mode = "n";
      key = "<leader>uL";
      action = mkRaw "function() _G.nixlab.toggle_codelens() end";
      options.desc = "Toggle CodeLens";
    }
    {
      mode = "n";
      key = "<leader>up";
      action = mkRaw "function() _G.nixlab.toggle_paste_mode() end";
      options.desc = "Toggle paste mode";
    }
    {
      mode = "n";
      key = "<leader>us";
      action = mkRaw "function() vim.wo.spell = not vim.wo.spell end";
      options.desc = "Toggle spellcheck";
    }
    {
      mode = "n";
      key = "<leader>uS";
      action = mkRaw "function() _G.nixlab.toggle_conceal() end";
      options.desc = "Toggle conceal";
    }
    {
      mode = "n";
      key = "<leader>ut";
      action = mkRaw "function() _G.nixlab.toggle_tabline() end";
      options.desc = "Toggle tabline";
    }
    {
      mode = "n";
      key = "<leader>uV";
      action = mkRaw "function() _G.nixlab.toggle_virtual_lines() end";
      options.desc = "Toggle virtual lines";
    }
    {
      mode = "n";
      key = "<leader>uY";
      action = mkRaw "function() _G.nixlab.toggle_semantic_tokens() end";
      options.desc = "Toggle semantic tokens";
    }
    {
      mode = "n";
      key = "<leader>ug";
      action = mkRaw "function() _G.nixlab.toggle_signcolumn() end";
      options.desc = "Toggle signcolumn";
    }
    {
      mode = "n";
      key = "<leader>un";
      action = mkRaw "function() _G.nixlab.toggle_number() end";
      options.desc = "Toggle line numbers";
    }
    {
      mode = "n";
      key = "<leader>uv";
      action = mkRaw "function() _G.nixlab.toggle_virtual_text() end";
      options.desc = "Toggle virtual text";
    }
    {
      mode = "n";
      key = "<leader>uw";
      action = mkRaw "function() _G.nixlab.toggle_wrap() end";
      options.desc = "Toggle wrap";
    }
    {
      mode = "n";
      key = "<leader>uT";
      action = "<Cmd>Twilight<CR>";
      options.desc = "Toggle Twilight";
    }
    {
      mode = "n";
      key = "<leader>Ss";
      action = "<Cmd>AutoSession save<CR>";
      options.desc = "Save session";
    }
    {
      mode = "n";
      key = "<leader>Sl";
      action = "<Cmd>AutoSession restore<CR>";
      options.desc = "Last session";
    }
    {
      mode = "n";
      key = "<leader>Sd";
      action = "<Cmd>AutoSession delete<CR>";
      options.desc = "Delete session";
    }
    {
      mode = "n";
      key = "<leader>SD";
      action = "<Cmd>AutoSession delete<CR>";
      options.desc = "Delete directory session";
    }
    {
      mode = "n";
      key = "<leader>Sf";
      action = "<Cmd>AutoSession search<CR>";
      options.desc = "Search sessions";
    }
    {
      mode = "n";
      key = "<leader>SF";
      action = "<Cmd>AutoSession search<CR>";
      options.desc = "Search directory sessions";
    }
    {
      mode = "n";
      key = "<leader>S.";
      action = "<Cmd>AutoSession restore<CR>";
      options.desc = "Load current directory session";
    }
  ];
}
