return {
  "stevearc/aerial.nvim",
  commit = "645d108a5242ec7b378cbe643eb6d04d4223f034",
  event = "User AstroFile",
  specs = {
    {
      "AstroNvim/astrocore",
      opts = function(_, opts)
        local maps = opts.mappings
        maps.n["<Leader>lS"] = { function() require("aerial").toggle() end, desc = "Symbols outline" }
      end,
    },
  },
  opts = function(_, opts)
    local ok, ts_helpers = pcall(require, "aerial.backends.treesitter.helpers")
    if ok then
      -- Neovim removed TSNode:start()/end_(); use the stable range() API instead.
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

    opts = require("astrocore").extend_tbl(opts, {
      attach_mode = "global",
      backends = { "lsp", "treesitter", "markdown", "man" },
      layout = { min_width = 28 },
      show_guides = true,
      filter_kind = false,
      guides = {
        mid_item = "├ ",
        last_item = "└ ",
        nested_top = "│ ",
        whitespace = "  ",
      },
      keymaps = {
        ["[y"] = "actions.prev",
        ["]y"] = "actions.next",
        ["[Y"] = "actions.prev_up",
        ["]Y"] = "actions.next_up",
        ["{"] = false,
        ["}"] = false,
        ["[["] = false,
        ["]]"] = false,
      },
      on_attach = function(bufnr)
        local astrocore = require "astrocore"
        astrocore.set_mappings({
          n = {
            ["]y"] = { function() require("aerial").next(vim.v.count1) end, desc = "Next symbol" },
            ["[y"] = { function() require("aerial").prev(vim.v.count1) end, desc = "Previous symbol" },
            ["]Y"] = { function() require("aerial").next_up(vim.v.count1) end, desc = "Next symbol upwards" },
            ["[Y"] = { function() require("aerial").prev_up(vim.v.count1) end, desc = "Previous symbol upwards" },
          },
        }, { buffer = bufnr })
      end,
    })

    local large_buf = vim.tbl_get(require("astrocore").config, "features", "large_buf")
    if large_buf then
      opts.disable_max_lines, opts.disable_max_size = large_buf.lines or nil, large_buf.size or nil
    end

    return opts
  end,
}
