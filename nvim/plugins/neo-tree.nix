{ ... }: {
  programs.nixvim.plugins.neo-tree = {
    enable = true;
    settings = {
      close_if_last_window = true;
      auto_clean_after_session_restore = true;
      log_to_file = false;
      popup_border_style = "rounded";
      sources = [ "filesystem" "buffers" "git_status" ];
      source_selector = {
        winbar = true;
        content_layout = "center";
        sources = [
          {
            source = "filesystem";
            display_name = "  File ";
          }
          {
            source = "buffers";
            display_name = "  Bufs ";
          }
          {
            source = "git_status";
            display_name = "  Git ";
          }
        ];
      };
      default_component_configs = {
        indent = {
          padding = 0;
          expander_collapsed = "";
          expander_expanded = "";
        };
        icon = {
          folder_closed = "";
          folder_open = "";
          folder_empty = "";
          folder_empty_open = "";
          default = "";
        };
        modified.symbol = "";
        git_status.symbols = {
          added = "✚";
          deleted = "✖";
          modified = "";
          renamed = "";
          untracked = "";
          ignored = "";
          unstaged = "";
          staged = "";
          conflict = "";
        };
      };
      filesystem = {
        follow_current_file = {
          enabled = true;
          leave_dirs_open = true;
        };
        hijack_netrw_behavior = "open_current";
        use_libuv_file_watcher = true;
      };
      window = {
        width = 30;
        mappings = {
          "<Space>" = false;
          "[b" = "prev_source";
          "]b" = "next_source";
          "Y" = "copy_to_clipboard";
          "h" = "close_node";
          "l" = "open";
        };
      };
    };
  };
}
