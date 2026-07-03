{ ... }: {
  programs.nixvim.plugins.auto-session = {
    enable = true;
    settings = {
      auto_save = true;
      auto_restore = true;
      auto_create = true;
      auto_restore_last_session = true;
      bypass_save_filetypes = [ "gitcommit" "gitrebase" ];
    };
  };
}
