# home.nix
{ pkgs, username ? "user", homeDirectory ? "/home/user", ... }:
{
  home.username = username;
  home.homeDirectory = homeDirectory;
  home.stateVersion = "26.11";
}
