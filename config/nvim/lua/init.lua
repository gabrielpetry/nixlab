-- This file simply bootstraps the installation of Lazy.nvim and then calls other files for execution
-- This file doesn't necessarily need to be touched, BE CAUTIOUS editing this file and proceed at your own risk.
local lazypath = vim.env.LAZY or vim.fn.stdpath "data" .. "/lazy/lazy.nvim"

if not (vim.env.LAZY or (vim.uv or vim.loop).fs_stat(lazypath)) then
  -- stylua: ignore
  local result = vim.fn.system({ "git", "clone", "--filter=blob:none", "https://github.com/folke/lazy.nvim.git",
    "--branch=stable", lazypath })
  if vim.v.shell_error ~= 0 then
    -- stylua: ignore
    vim.api.nvim_echo(
    { { ("Error cloning lazy.nvim:\n%s\n"):format(result), "ErrorMsg" }, { "Press any key to exit...", "MoreMsg" } },
      true, {})
    vim.fn.getchar()
    vim.cmd.quit()
  end
end

vim.opt.rtp:prepend(lazypath)

-- validate that lazy is available
if not pcall(require, "lazy") then
  -- stylua: ignore
  vim.api.nvim_echo(
  { { ("Unable to load lazy from: %s\n"):format(lazypath), "ErrorMsg" }, { "Press any key to exit...", "MoreMsg" } },
    true, {})
  vim.fn.getchar()
  vim.cmd.quit()
end

require "lazy_setup"
require "polish"

-- Neovim 0.12 can crash on markdown fenced-code injections.
vim.treesitter.query.set("markdown", "injections", "")
vim.treesitter.query.set("markdown_inline", "injections", "")

vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = "*.yaml",
  callback = function()
    local filepath = vim.fn.expand "%:p"
    if string.find(filepath, "/templates/") then vim.bo.filetype = "helm" end
  end,
})

-- When entering a markdown file, enable markdown rendering
vim.api.nvim_create_autocmd({ "BufRead", "BufNewFile" }, {
  pattern = "*.md",
  callback = function()
    if vim.fn.exists(":RenderMarkdown") > 0 then vim.cmd "RenderMarkdown enable" end
  end,
})

-- When going into insert mode in a markdown file, disable markdown rendering to avoid things poping around
vim.api.nvim_create_autocmd({ "InsertEnter" }, {
  pattern = "*.md",
  callback = function()
    if vim.fn.exists(":RenderMarkdown") > 0 then vim.cmd "RenderMarkdown disable" end
  end,
})

vim.keymap.set("n", "<C-Q>", "<Esc><Cmd>ToggleTerm direction=float<CR>")
vim.keymap.set("t", "<C-Q>", "<Cmd>ToggleTerm direction=float<CR>")
vim.keymap.set("i", "<C-Q>", "<Esc><Cmd>ToggleTerm direction=float<CR>")
vim.keymap.set("n", "<C-;>", "<Cmd>Twilight<CR>")
vim.keymap.set("i", "<C-;>", "<Cmd>Twilight<CR>")

-- keep identation when shifting lines
vim.api.nvim_set_keymap("v", ">", ">gv", { noremap = true, silent = true })
vim.api.nvim_set_keymap("v", "<", "<gv", { noremap = true, silent = true })

-- wsl shennanigans
if vim.env.WSL_DISTRO_NAME == "Ubuntu" then
  -- This code will only run when Neovim is started inside WSL

  -- Use win32yank.exe for system clipboard integration
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

-- This setting can be outside the block if you want it to be a default
-- for other systems that have a clipboard manager (like native Linux with xclip).
-- Or, place it inside the 'if' block to only apply it for WSL.
