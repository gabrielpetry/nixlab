{
  ...
}:

let
in
{
  imports = [
    ./vms.nix # All the vms use the same disk layout
  ];
  networking.hostName = "vm01";
  networking.interfaces.eth0.ipv4.addresses = [
    {
      address = "10.10.130.101";
      prefixLength = 24;
    }
  ];
}
