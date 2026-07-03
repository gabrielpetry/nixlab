{ ... }:
{
  programs.nixvim.extraConfigLuaPost = ''
    require("minuet").setup({
      provider = "openai_fim_compatible",
      n_completions = 1,
      context_window = tonumber(vim.env.MINUET_CONTEXT_WINDOW) or 2048,
      request_timeout = tonumber(vim.env.MINUET_REQUEST_TIMEOUT) or 3,
      throttle = tonumber(vim.env.MINUET_THROTTLE) or 400,
      debounce = tonumber(vim.env.MINUET_DEBOUNCE) or 100,

      virtualtext = {
        auto_trigger_ft = { "*" },
        keymap = {
          accept = nil,
          accept_line = "<A-a>",
          accept_n_lines = "<A-z>",
          next = "<A-]>",
          prev = "<A-[>",
          dismiss = "<A-e>",
        },
      },

      provider_options = {
        openai_fim_compatible = {
          api_key = "TERM",
          name = "Ollama",
          end_point = vim.env.MINUET_ENDPOINT or "http://localhost:11434/v1/completions",
          model = vim.env.MINUET_MODEL or "qwen2.5-coder:3b",
          optional = {
            max_tokens = tonumber(vim.env.MINUET_MAX_TOKENS) or 256,
            top_p = tonumber(vim.env.MINUET_TOP_P) or 0.9,
            reasoning_effort = 'none',
          },
        },
      },
    })

    vim.g.ai_accept = function()
      local ok, virtualtext = pcall(require, "minuet.virtualtext")
      if not ok then return end
      if not virtualtext.action.is_visible() then return end

      virtualtext.action.accept()
      return true
    end
  '';
}
