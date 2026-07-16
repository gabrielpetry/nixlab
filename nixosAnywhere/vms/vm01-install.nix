{
  imports = [ ./install.nix ];

  networking.hostName = "vm01";
  networking.interfaces.eth1.ipv4.addresses = [
    {
      address = "10.10.130.101";
      prefixLength = 24;
    }
  ];
}
