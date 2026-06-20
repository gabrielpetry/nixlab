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
}
