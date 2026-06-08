{ pkgs, ... }:
{
  home.file.".local/share/bash-completion/completions" = {
    source = ./completions;
    recursive = true;
  };

  home.file.".config/bash/plugins" = {
    source = ./plugins;
    recursive = true;
  };

  home.file.".config/bash/aliases.bash".source = ./aliases.bash;

  programs.bash = {
    enable = true;
    enableCompletion = true;
    historyFile = "$HOME/.bash_history";
    historyControl = [ "ignoreboth" ];
    historyFileSize = 40000;
    historySize = 200000;

    initExtra = ''
      export RED=$'\033[0;31m'
      export GREEN=$'\033[0;32m'
      export YELLOW=$'\033[0;33m'
      export BLUE=$'\033[0;34m'
      export MAGENTA=$'\033[0;35m'
      export CYAN=$'\033[0;36m'
      export WHITE=$'\033[0;37m'
      export NC=$'\033[0m'
      export EDITOR="nvim"
      export CACHE_DIR="$HOME/.cache"

      if [[ -z "$TMUX" ]] && [[ -z "$TERM_PROGRAM" ]] && command -v tmux; then
        tmux
      fi

      . "$HOME/.nix-profile/etc/profile.d/nix.sh"

      mkdir -p "$@" && cd "$@"

    '';

    shellAliases = {
      ssh = "TERM=xterm-256color ssh";
      ccat = "/bin/cat";
      cat = "bat";
      kubectl = "kubectl-cache";
      kubectl-raw = "kubecmd";
      grep = "grep --color=auto";
      ls = "ls --color=auto";
      sl = "ls";
      ll = "ls -lh";
      la = "ls -lah";
      tree = "tree -C";
      c = "ps aux | grep -v grep | grep --color -i";
      repo = "source \"$HOME/nixlab/tooling/scripts/repo\"";
    };

    shellOptions = [
      "autocd"
      "cdspell"
      "histappend"
      "checkwinsize"
      "nullglob"
      "globstar"
    ];

    bashrcExtra = ''
      [[ -f "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh" ]] && \
        source "$HOME/.nix-profile/etc/profile.d/hm-session-vars.sh"

      [ -x /usr/bin/lesspipe ] && eval "$(/usr/bin/lesspipe)"

      [ -x /usr/bin/dircolors ] && eval "$(dircolors -b)"

      # Completions are lazily loaded by bash-completion's dynamic loader
      # (_comp_load / __load_completion). The files are stored in
      # ~/.local/share/bash-completion/completions/ and are sourced
      # automatically on the first TAB press for each command.

      for plugins in $HOME/.config/bash/plugins/*; do
        source "$plugins"
      done

      unset VIRTUAL_ENV
      unset VIRTUAL_ENV_PROMPT

      if [ -n "$TMUX" ]; then
        export TMUX_PANE="$(tmux display-message -p '#{pane_id}' 2>/dev/null)"
      fi

      source ~/.config/bash/aliases.bash

    '';

  };
}
