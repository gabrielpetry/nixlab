return {
  "AstroNvim/astrolsp",
  opts = function(_, opts)
    opts = opts or {}
    opts.features = opts.features or {}
    opts.features.codelens = false

    local user_on_attach = opts.on_attach
    opts.on_attach = function(client, bufnr)
      vim.lsp.codelens.enable(true, { bufnr = bufnr })

      if user_on_attach then user_on_attach(client, bufnr) end
    end
  end,
}
