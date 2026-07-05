{
  config,
  pkgs,
  lib,
  ...
}:
{
  services.desktopManager.plasma6.enable = true;
  services.displayManager.plasma6-login.enable = true;
}
