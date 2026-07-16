{
  imports = [ ./install.nix ];

  networking.hostName = "vm02";
  networking.interfaces.eth1.ipv4.addresses = [
    {
      address = "10.10.130.102";
      prefixLength = 24;
    }
  ];
}
