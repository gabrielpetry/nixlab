# home.nix
{ pkgs, username ? "user", homeDirectory ? "/home/user", ... }:
{
  home.username = username;
  home.homeDirectory = homeDirectory;
  home.stateVersion = "26.05";
  fonts.fontconfig.enable = true;

  home.packages = with pkgs; [
    nerd-fonts.jetbrains-mono
    nerd-fonts.fira-code
    nerd-fonts.hack
    nerd-fonts.comic-shanns-mono
    nerd-fonts.open-dyslexic

  ];
}
