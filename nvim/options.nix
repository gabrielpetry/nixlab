{ ... }: {
  programs.nixvim.globals = {
    mapleader = " ";
    maplocalleader = ",";
  };

  programs.nixvim.opts = {
    backspace = [ "indent" "eol" "start" "nostop" ];
    breakindent = true;
    clipboard = "unnamedplus";
    cmdheight = 0;
    completeopt = [ "menu" "menuone" "noselect" ];
    confirm = true;
    copyindent = true;
    cursorline = true;
    expandtab = true;
    ignorecase = true;
    infercase = true;
    laststatus = 3;
    linebreak = true;
    mouse = "a";
    number = true;
    preserveindent = true;
    pumheight = 10;
    relativenumber = true;
    scrolloff = 8;
    shiftround = true;
    shiftwidth = 0;
    showmode = false;
    showtabline = 2;
    sidescrolloff = 8;
    signcolumn = "yes";
    smartcase = true;
    smartindent = true;
    softtabstop = 2;
    splitbelow = true;
    splitright = true;
    tabclose = "uselast";
    tabstop = 2;
    termguicolors = true;
    timeoutlen = 500;
    title = true;
    undofile = true;
    updatetime = 300;
    virtualedit = "block";
    winborder = "rounded";
    wrap = false;
    writebackup = false;
    fillchars = {
      eob = " ";
    };
  };
}
