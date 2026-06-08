# home.nix
{ username ? "user", homeDirectory ? "/home/user", ... }:
{
  home.username = username;
  home.homeDirectory = homeDirectory;
  home.stateVersion = "26.05";
  fonts.fontconfig.enable = true;
}
