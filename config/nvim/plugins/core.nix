{ ... }: {
  programs.nixvim.plugins = {
    web-devicons.enable = true;
    which-key.enable = true;
    comment.enable = true;
    gitsigns.enable = true;
    luasnip.enable = true;
    friendly-snippets.enable = true;
    twilight.enable = true;
    visual-multi.enable = true;
    render-markdown.enable = true;
    rainbow-delimiters.enable = true;
    indent-blankline.enable = true;
    copilot-chat.enable = true;
  };
}
