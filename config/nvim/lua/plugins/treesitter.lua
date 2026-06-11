-- Customize Treesitter

---@type LazySpec
return {
  "nvim-treesitter/nvim-treesitter",
  opts = function(_, opts)
    opts.ensure_installed = opts.ensure_installed or {}
    vim.list_extend(opts.ensure_installed, {
      "lua",
      "vim",
      -- add more arguments for adding more treesitter parsers
    })

    -- Work around Neovim 0.12 markdown injection crashes.
    opts.highlight = opts.highlight or {}
    local disable = opts.highlight.disable or {}
    if type(disable) ~= "table" then disable = { disable } end

    local seen = {}
    for _, lang in ipairs(disable) do
      seen[lang] = true
    end
    for _, lang in ipairs { "markdown", "markdown_inline" } do
      if not seen[lang] then table.insert(disable, lang) end
    end

    opts.highlight.disable = disable
  end,
}
