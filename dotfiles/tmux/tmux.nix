{ pkgs, ... }:
{
  programs.tmux = {
    enable = true;

    # ── Core options ──────────────────────────────────────────────────────────
    mouse = true;
    prefix = "C-b";
    baseIndex = 1;
    escapeTime = 0;
    historyLimit = 1000000;
    keyMode = "vi";
    terminal = "screen-256color";
    clock24 = true;

    extraConfig = ''
      # ── Terminal / display ──────────────────────────────────────────────────
      set -g extended-keys on
      set -g extended-keys-format csi-u
      set -g allow-passthrough on
      set -ga terminal-overrides ',xterm-256color:Tc'
      set -g detach-on-destroy on
      set -g renumber-windows on
      set -g set-clipboard on
      set -g status-position top

      # ── Reset all default keybindings, then re-bind essentials ─────────────
      unbind-key -a

      # Traditional prefix bindings (replicating tmux.reset.conf)
      bind ^X lock-server
      bind ^C new-window -c "#{pane_current_path}"
      bind * list-clients
      bind H previous-window
      bind L next-window
      bind r command-prompt "rename-window %%"
      bind R source-file ~/.tmux.conf
      bind ^A last-window
      bind ^W list-windows
      bind w list-windows
      bind z resize-pane -Z
      bind ^L refresh-client
      bind l refresh-client
      bind | split-window -v -c "#{pane_current_path}"
      bind - split-window -h -c "#{pane_current_path}"
      bind S split-window -h -c "#{pane_current_path}"
      bind s split-window -v -c "#{pane_current_path}"
      bind '"' choose-window
      bind h select-pane -L
      bind j select-pane -D
      bind k select-pane -U
      bind l select-pane -R
      bind -r -T prefix , resize-pane -L 20
      bind -r -T prefix . resize-pane -R 20
      bind -r -T prefix - resize-pane -D 7
      bind -r -T prefix = resize-pane -U 7
      bind : command-prompt
      bind * setw synchronize-panes
      bind P set pane-border-status
      bind K send-keys "clear"\; send-keys "Enter"
      bind-key -T copy-mode-vi v send-keys -X begin-selection

      # ── Alt + number: direct window selection ──────────────────────────────
      bind -n M-1 select-window -t 1
      bind -n M-2 select-window -t 2
      bind -n M-3 select-window -t 3
      bind -n M-4 select-window -t 4
      bind -n M-5 select-window -t 5
      bind -n M-6 select-window -t 6
      bind -n M-7 select-window -t 7
      bind -n M-8 select-window -t 8
      bind -n M-9 select-window -t 9
      bind -n M-0 next-window
      bind -n M-n new-window

      # ── Pane navigation (Vim-aware, C-h/j/k/l) ─────────────────────────────
      # Uses #{@pane-is-vim} — set by Neovim / other editors via:
      #   :silent !tmux set-option -p @pane-is-vim 1
      bind-key -n C-h if -F "#{@pane-is-vim}" 'send-keys C-h'  'select-pane -L'
      bind-key -n C-j if -F "#{@pane-is-vim}" 'send-keys C-j'  'select-pane -D'
      bind-key -n C-k if -F "#{@pane-is-vim}" 'send-keys C-k'  'select-pane -U'
      bind-key -n C-l if -F "#{@pane-is-vim}" 'send-keys C-l'  'select-pane -R'

      bind -n M-h previous-window
      bind -n M-l next-window

      # C-\  (switch to last pane, Vim-aware)
      if-shell -b 'tmux_version="$(tmux -V | sed -En "s/^tmux ([0-9]+(\.[0-9]+)?).*/\1/p")"; [ "$(printf "%s\n%s\n" "$tmux_version" "3.0" | sort -V | head -n1)" != "3.0" ]' \
          "bind-key -n 'C-\\' if -F \"#{@pane-is-vim}\" 'send-keys C-\\'  'select-pane -l'"
      if-shell -b 'tmux_version="$(tmux -V | sed -En "s/^tmux ([0-9]+(\.[0-9]+)?).*/\1/p")"; [ "$(printf "%s\n%s\n" "$tmux_version" "3.0" | sort -V | head -n1)" = "3.0" ]' \
          "bind-key -n 'C-\\' if -F \"#{@pane-is-vim}\" 'send-keys C-\\\\'  'select-pane -l'"

      # Same pane navigation in copy-mode-vi
      bind-key -T copy-mode-vi 'C-h' select-pane -L
      bind-key -T copy-mode-vi 'C-j' select-pane -D
      bind-key -T copy-mode-vi 'C-k' select-pane -U
      bind-key -T copy-mode-vi 'C-l' select-pane -R
      bind-key -T copy-mode-vi 'C-\' select-pane -l

      # ── Catppuccin Mocha theme ─────────────────────────────────────────────
      # Base UI
      set -g status on
      set -g status-interval 5
      set -g status-style "fg=#cdd6f4,bg=#1e1e2e"
      set -g message-style "fg=#cdd6f4,bg=#313244"
      set -g message-command-style "fg=#cdd6f4,bg=#313244"
      set -g pane-border-style "fg=#45475a"
      set -g pane-active-border-style "fg=#89b4fa"
      set -g display-panes-colour "#89b4fa"
      set -g display-panes-active-colour "#f9e2af"
      set -g clock-mode-colour "#89b4fa"
      set -g mode-style "fg=#1e1e2e,bg=#89b4fa,bold"

      # Windows
      setw -g window-status-separator ""
      setw -g window-status-style "fg=#a6adc8,bg=#1e1e2e"
      setw -g window-status-format "#[fg=#cdd6f4,bg=#45475a] #I:#W#{?window_flags, #{window_flags}, }"
      setw -g window-status-current-style "fg=#1e1e2e,bg=#89b4fa,bold"
      setw -g window-status-current-format "#[fg=#1e1e2e,bg=#89b4fa,bold] #I:#W#{?window_flags, #{window_flags}, }"
      setw -g window-status-activity-style "fg=#fab387,bg=#1e1e2e"
      setw -g window-status-bell-style "fg=#1e1e2e,bg=#f38ba8,bold"

      # Status line
      set -g status-left-length 100
      set -g status-right-length 100
      set -g status-left "#[fg=#1e1e2e,bg=#cba6f7,bold] #S "
      set -g status-right "#[fg=#cdd6f4,bg=#45475a] %Y-%m-%d #[fg=#cdd6f4,bg=#313244] %H:%M #[fg=#1e1e2e,bg=#89b4fa,bold] #H "

      # Copy mode / menus
      set -g menu-style "fg=#cdd6f4,bg=#1e1e2e"
      set -g menu-selected-style "fg=#1e1e2e,bg=#89b4fa,bold"
      set -g menu-border-style "fg=#89b4fa"
      set -g popup-style "fg=#cdd6f4,bg=#1e1e2e"
      set -g popup-border-style "fg=#89b4fa"
    '';
  };
}
