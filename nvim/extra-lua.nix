{ ... }: {
  programs.nixvim.extraConfigLuaPre = ''
    vim.g.loaded_netrw = 1
    vim.g.loaded_netrwPlugin = 1
    vim.g.smart_splits_multiplexer_integration = (vim.env.TMUX and vim.env.TMUX ~= "") and "tmux" or false
  '';

  programs.nixvim.extraConfigLuaPost = ''
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
    vim.g.ibl_enabled = vim.F.if_nil(vim.g.ibl_enabled, true)

    local uv = vim.uv or vim.loop

    local function notify_toggle(name, enabled)
      vim.notify(("%s %s"):format(name, enabled and "enabled" or "disabled"), vim.log.levels.INFO)
    end

    local function close_buffers(predicate)
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_loaded(buf) and predicate(buf) then
          pcall(vim.api.nvim_buf_delete, buf, { force = false })
        end
      end
    end

    local function pick_buffer_in_split(split_cmd)
      local ok_builtin, builtin = pcall(require, "telescope.builtin")
      local ok_actions, actions = pcall(require, "telescope.actions")
      local ok_state, action_state = pcall(require, "telescope.actions.state")
      if not ok_builtin or not ok_actions or not ok_state then return end

      builtin.buffers({
        sort_mru = true,
        attach_mappings = function(prompt_bufnr, map)
          local function open_selected()
            local entry = action_state.get_selected_entry()
            actions.close(prompt_bufnr)
            if not entry or not entry.bufnr then return end
            vim.cmd(split_cmd)
            vim.api.nvim_win_set_buf(0, entry.bufnr)
          end

          map("i", "<CR>", open_selected)
          map("n", "<CR>", open_selected)
          return true
        end,
      })
    end

    local function toggle_command_terminal(command)
      local Terminal = require("toggleterm.terminal").Terminal
      _G.nixlab.terminals = _G.nixlab.terminals or {}
      if not _G.nixlab.terminals[command] then
        _G.nixlab.terminals[command] = Terminal:new({ cmd = command, direction = "float", hidden = true })
      end
      _G.nixlab.terminals[command]:toggle()
    end

    _G.nixlab.close_other_buffers = function()
      local current = vim.api.nvim_get_current_buf()
      close_buffers(function(buf) return buf ~= current end)
    end

    _G.nixlab.close_current_buffer = function(force)
      local current = vim.api.nvim_get_current_buf()
      local replacement = nil

      for _, buf in ipairs(vim.fn.getbufinfo({ buflisted = 1 })) do
        if buf.bufnr ~= current and vim.api.nvim_buf_is_loaded(buf.bufnr) then
          replacement = buf.bufnr
          break
        end
      end

      if replacement then
        vim.api.nvim_win_set_buf(0, replacement)
      else
        vim.cmd("enew")
      end

      pcall(vim.api.nvim_buf_delete, current, { force = force or false })
    end

    _G.nixlab.close_all_buffers = function()
      vim.cmd("enew")
      local current = vim.api.nvim_get_current_buf()
      close_buffers(function(buf) return buf ~= current end)
    end

    _G.nixlab.pick_buffer_in_split = pick_buffer_in_split

    _G.nixlab.rename_current_file = function()
      local old_name = vim.api.nvim_buf_get_name(0)
      if old_name == "" then
        vim.notify("No file to rename", vim.log.levels.WARN)
        return
      end

      vim.ui.input({
        prompt = "New name: ",
        default = vim.fn.fnamemodify(old_name, ":t"),
      }, function(input)
        if not input or input == "" then return end

        local new_name = input:find("/") and input or (vim.fn.fnamemodify(old_name, ":h") .. "/" .. input)
        if new_name == old_name then return end
        if vim.fn.filereadable(new_name) == 1 or vim.fn.isdirectory(new_name) == 1 then
          vim.notify(("Target exists: %s"):format(new_name), vim.log.levels.WARN)
          return
        end

        vim.cmd("silent write")
        local ok, err = uv.fs_rename(old_name, new_name)
        if not ok then
          vim.notify(("Rename failed: %s"):format(err or "unknown error"), vim.log.levels.ERROR)
          return
        end

        vim.api.nvim_buf_set_name(0, new_name)
        vim.cmd.edit(vim.fn.fnameescape(new_name))
        vim.notify(("Renamed to %s"):format(new_name), vim.log.levels.INFO)
      end)
    end

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

    _G.nixlab.toggle_diagnostics = function()
      local enabled = vim.diagnostic.is_enabled == nil and true or vim.diagnostic.is_enabled()
      vim.diagnostic.enable(not enabled)
      notify_toggle("Diagnostics", not enabled)
    end

    _G.nixlab.toggle_background = function()
      vim.o.background = vim.o.background == "dark" and "light" or "dark"
      notify_toggle("Background", vim.o.background == "dark")
    end

    _G.nixlab.toggle_foldcolumn = function()
      vim.wo.foldcolumn = vim.wo.foldcolumn == "0" and "1" or "0"
      notify_toggle("Foldcolumn", vim.wo.foldcolumn ~= "0")
    end

    _G.nixlab.toggle_indent_setting = function()
      vim.bo.expandtab = not vim.bo.expandtab
      notify_toggle("Indent setting", vim.bo.expandtab)
    end

    _G.nixlab.toggle_indent_guides = function()
      vim.g.ibl_enabled = not vim.g.ibl_enabled
      if vim.g.ibl_enabled then
        vim.cmd("IBLEnable")
      else
        vim.cmd("IBLDisable")
      end
      notify_toggle("Indent guides", vim.g.ibl_enabled)
    end

    _G.nixlab.toggle_statusline = function()
      vim.o.laststatus = vim.o.laststatus == 0 and 3 or 0
      notify_toggle("Statusline", vim.o.laststatus ~= 0)
    end

    _G.nixlab.toggle_tabline = function()
      vim.o.showtabline = vim.o.showtabline == 0 and 2 or 0
      notify_toggle("Tabline", vim.o.showtabline ~= 0)
    end

    _G.nixlab.toggle_paste_mode = function()
      vim.o.paste = not vim.o.paste
      notify_toggle("Paste mode", vim.o.paste)
    end

    _G.nixlab.toggle_conceal = function()
      vim.wo.conceallevel = vim.wo.conceallevel == 0 and 2 or 0
      notify_toggle("Conceal", vim.wo.conceallevel ~= 0)
    end

    _G.nixlab.toggle_codelens = function()
      if not vim.lsp.codelens then return end
      local enabled = vim.lsp.codelens.is_enabled()
      vim.lsp.codelens.enable(not enabled, { bufnr = 0 })
      notify_toggle("CodeLens", not enabled)
    end

    _G.nixlab.toggle_virtual_lines = function()
      local config = vim.diagnostic.config()
      local enabled = config.virtual_lines ~= false
      vim.diagnostic.config({ virtual_lines = enabled and false or true })
      notify_toggle("Virtual lines", not enabled)
    end

    _G.nixlab.toggle_semantic_tokens = function()
      if not vim.lsp.semantic_tokens then return end
      local enabled = vim.lsp.semantic_tokens.is_enabled()
      vim.lsp.semantic_tokens.enable(not enabled, { bufnr = 0 })
      notify_toggle("Semantic tokens", not enabled)
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

    _G.nixlab.toggle_node = function() toggle_command_terminal("node") end
    _G.nixlab.toggle_python = function() toggle_command_terminal("python") end
    _G.nixlab.toggle_btm = function() toggle_command_terminal("btm") end

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
        { "<leader>S", group = "Sessions" },
        { "<leader>t", group = "Terminal" },
        { "<leader>u", group = "UI" },
        { "<leader>x", group = "Lists" },
      })
    end
  '';
}
