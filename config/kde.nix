{ ... }:
{
  xdg.configFile."plasma-workspace/env/flatpak.sh".text = ''
    export XDG_DATA_DIRS="$HOME/.local/share/flatpak/exports/share:/var/lib/flatpak/exports/share:''${XDG_DATA_DIRS:-/usr/local/share:/usr/share}"
  '';
}
