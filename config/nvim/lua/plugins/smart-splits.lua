local in_tmux = (vim.env.TMUX or "") ~= ""

return {
  "mrjones2014/smart-splits.nvim",
  lazy = false,
  init = function()
    vim.g.smart_splits_multiplexer_integration = in_tmux and "tmux" or false
  end,
  config = function(_, opts)
    require("smart-splits").setup(opts)

    local map = vim.keymap.set
    map({ "n", "i", "t" }, "<C-h>", function() require("smart-splits").move_cursor_left() end, { desc = "Move to left split" })
    map({ "n", "i", "t" }, "<C-j>", function() require("smart-splits").move_cursor_down() end, { desc = "Move to below split" })
    map({ "n", "i", "t" }, "<C-k>", function() require("smart-splits").move_cursor_up() end, { desc = "Move to above split" })
    map({ "n", "i", "t" }, "<C-l>", function() require("smart-splits").move_cursor_right() end, { desc = "Move to right split" })
    map("n", "<C-Up>", function() require("smart-splits").resize_up() end, { desc = "Resize split up" })
    map("n", "<C-Down>", function() require("smart-splits").resize_down() end, { desc = "Resize split down" })
    map("n", "<C-Left>", function() require("smart-splits").resize_left() end, { desc = "Resize split left" })
    map("n", "<C-Right>", function() require("smart-splits").resize_right() end, { desc = "Resize split right" })
  end,
  opts = {
    ignored_filetypes = { "nofile", "quickfix", "qf", "prompt" },
    ignored_buftypes = { "nofile" },
    at_edge = "wrap",
    cursor_follows_swapped_bufs = true,
    multiplexer_integration = in_tmux and "tmux" or false,
  },
}
