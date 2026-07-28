{
  config,
  herdrPackage,
  lib,
  ...
}:
{
  imports = [ ../multiplexer.nix ];

  home.packages = [ herdrPackage ];

  xdg.configFile."herdr/config.toml".source = ./config.toml;

  programs.bash.initExtra = lib.mkIf (config.nixlab.multiplexer.autoStart == "herdr") ''
    if [[ -z "''${TMUX:-}" ]] && [[ "''${HERDR_ENV:-0}" != "1" ]] && [[ -z "''${TERM_PROGRAM:-}" ]] && command -v herdr >/dev/null 2>&1; then
      herdr
    fi
  '';
}
