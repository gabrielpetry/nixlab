{
  ...
}:

let
in
{
  imports = [
    ./vms.nix
  ];
  networking.hostName = "vm02";
  networking.interfaces.eth0.ipv4.addresses = [
    {
      address = "10.10.130.102";
      prefixLength = 24;
    }
  ];
}
