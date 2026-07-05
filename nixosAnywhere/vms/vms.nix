{
  lib,
  username,
  ...
}:

let
  sshKeyPath = ../../.vagrant/ssh/nixlab_dev_key.pub;
  sshAuthorizedKeys =
    if builtins.pathExists sshKeyPath then
      [ (lib.strings.removeSuffix "\n" (builtins.readFile sshKeyPath)) ]
    else
      [ ];
in
{
  imports = [
    ./disko.nix # All the vms use the same disk layout
  ];
  nixlab.docker = {
    extraUsers = [ "vagrant" ];
    enable = true;
  };

  networking.useDHCP = lib.mkDefault false;
  networking = {
    # Each vm should define it's own ip
    # interfaces.eth0.ipv4.addresses = [
    #   {
    #     address = "10.10.130.101";
    #     prefixLength = 24;
    #   }
    # ];
    # QEMU user-mode networking uses .2 as the guest-visible gateway.
    defaultGateway = {
      address = "10.10.130.2";
      interface = "eth0";
    };
    nameservers = [
      "1.1.1.1"
      "1.0.0.1"
    ];
  };

  nix.settings.experimental-features = [
    "nix-command"
    "flakes"
  ];

  users.users.root.openssh.authorizedKeys.keys = sshAuthorizedKeys;
  # for a real machine you whould use ${username} instead of vagrant
  # for the vms we wan't to make vagrant ssh keep working
  # users.users.${username} = {
  users.users.vagrant = {
    isNormalUser = true;
    home = "/var/vagrant";
    description = "${username} admin user";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = sshAuthorizedKeys;
  };

  system.stateVersion = "26.11";
}
