{ pkgs, ... }:
{
  programs.starship = {
    enable = true;
    enableBashIntegration = true;
    settings = {
      add_newline = false;

      format = ''
        [╭─](dimmed) $status$time[took ](dimmed)$cmd_duration$username$hostname$directory''${custom.git_clean}''${custom.git_dirty}$kubernetes
        [╰─](dimmed) $character
      '';

      status = {
        disabled = false;
        format = "[$symbol$maybe_int]($style) ";
        success_symbol = "✔";
        symbol = "✘ ";
        style = "red";
        success_style = "green";
        map_symbol = false;
      };

      time = {
        disabled = false;
        format = "[$time](dimmed) ";
        time_format = "%H:%M:%S";
      };

      cmd_duration = {
        min_time = 0;
        show_milliseconds = false;
        format = "[$duration]($style) ";
        style = "green";
      };

      username = {
        show_always = true;
        format = "[│](dimmed) [ $user](blue)";
      };

      hostname = {
        ssh_only = false;
        format = "[@](dimmed)[$hostname](blue) ";
      };

      directory = {
        format = "[│](dimmed)  [ $path](bold cyan) ";
        home_symbol = "~";
        truncation_length = 100;
        truncate_to_repo = false;
      };

      custom = {
        git_clean = {
          command = "git rev-parse --abbrev-ref HEAD";
          when = ''git rev-parse --is-inside-work-tree 2>/dev/null && [ -z "$(git status --porcelain 2>/dev/null)" ]'';
          format = "[│](dimmed) [ $output](green) ";
        };
        git_dirty = {
          command = ''printf "%s ✱" "$(git rev-parse --abbrev-ref HEAD)"'';
          when = ''git rev-parse --is-inside-work-tree 2>/dev/null && [ -n "$(git status --porcelain 2>/dev/null)" ]'';
          format = "[│](dimmed) [ $output](red) ";
        };
      };

      git_branch.disabled = true;
      git_status.disabled = true;

      kubernetes = {
        disabled = false;
        format = "[│](dimmed) [󱃾 $context](blue)[:](dimmed)[$namespace](cyan) ";
      };

      character = {
        success_symbol = "[❯](green)";
        error_symbol = "[❯](red)";
        format = "$symbol ";
      };
    };
  };
}
