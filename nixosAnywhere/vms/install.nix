{
  lib,
  username,
  ...
}:

let
  envSshKeyPath = builtins.getEnv "NIXLAB_VM_SSH_PUBKEY_FILE";
  sshKeyPath = if envSshKeyPath != "" then envSshKeyPath else ../../.vagrant/ssh/nixlab_dev_key.pub;
  sshAuthorizedKeys =
    if builtins.pathExists sshKeyPath then
      [ (lib.strings.removeSuffix "\n" (builtins.readFile sshKeyPath)) ]
    else
      [ ];
in
{
  imports = [ ./disko.nix ];

  nix.settings.trusted-users = [ "vagrant" ];
  security.sudo.wheelNeedsPassword = false;

  networking.useDHCP = lib.mkDefault false;
  networking = {
    interfaces.eth0.useDHCP = true;
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
  users.users.vagrant = {
    isNormalUser = true;
    home = "/var/vagrant";
    description = "${username} admin user";
    extraGroups = [ "wheel" ];
    openssh.authorizedKeys.keys = sshAuthorizedKeys;
  };

  system.stateVersion = "26.11";
}
