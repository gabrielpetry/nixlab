{
  config,
  pkgs,
  lib,
  ...
}:

let
in
{
  environment.systemPackages = with pkgs; [
    # Core CLI
    bash
    bash-completion
    cacert
    curl
    entr
    gawk
    git
    gnumake
    htop
    jq
    lynx
    nano
    ncdu
    ncurses
    ripgrep
    rsync
    sudo
    tree
    uv
    wget2
    yq
    zip
    unzip

    # Shells
    fish
    zsh

    # Languages & runtimes
    gcc
    lua5_4
    luarocks
    perl
    python3
    ruby

    # Python tools
    pipx
    python3Packages.pip
    python3Packages.pyserial
    python3Packages.tkinter
    python3Packages.virtualenv

    # Build tools & libs
    cmake
    libffi
    libyaml
    openssl
    openssl.dev
    pkg-config
    readline
    linuxHeaders

    # Editors
    vim

    # Filesystem & storage
    extundelete
    fuse2
    cryptsetup

    # Networking
    bind
    inetutils
    openssh
    nfs-utils
  ];

  boot.supportedFilesystems = [ "nfs" ];

  services = {
    openssh.enable = true;
  };
}
