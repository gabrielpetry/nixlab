{
  imports = [ ./install.nix ];

  networking.hostName = "vm03";
  networking.interfaces.eth1.ipv4.addresses = [
    {
      address = "10.10.130.103";
      prefixLength = 24;
    }
  ];
}
