{
  config,
  herdrPackage,
  lib,
  pkgs,
  ...
}:
let
  herdrPaneNavigate = pkgs.writeShellApplication {
    name = "herdr-pane-navigate";
    runtimeInputs = [
      herdrPackage
      pkgs.jq
    ];
    text = ''
      direction="''${1:?direction is required}"
      key="''${2:?key is required}"
      pane="''${HERDR_ACTIVE_PANE_ID:?HERDR_ACTIVE_PANE_ID is required}"

      if herdr pane process-info --pane "$pane" \
        | jq -e 'any(.result.process_info.foreground_processes[]?; ((.argv[0] // .name // "") | split("/") | last | test("^\\.?n?vim(-wrapped)?$")))' \
          >/dev/null; then
        herdr pane send-keys "$pane" "$key" >/dev/null
      else
        herdr pane focus --pane "$pane" --direction "$direction" >/dev/null
      fi
    '';
  };
in
{
  imports = [ ../multiplexer.nix ];

  home.packages = [
    herdrPackage
    herdrPaneNavigate
  ];

  xdg.configFile."herdr/config.toml".source = ./config.toml;

  programs.bash.initExtra = lib.mkIf (config.nixlab.multiplexer.autoStart == "herdr") ''
    if [[ -z "''${TMUX:-}" ]] && [[ "''${HERDR_ENV:-0}" != "1" ]] && [[ -z "''${TERM_PROGRAM:-}" ]] && command -v herdr >/dev/null 2>&1; then
      herdr
    fi
  '';
}
