{ nixvimLib, ... }:
let
  mkRaw = nixvimLib.mkRaw;
in {
  programs.nixvim.autoCmd = [
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
}
