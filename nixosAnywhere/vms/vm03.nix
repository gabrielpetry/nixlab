{
  ...
}:

let
in
{
  imports = [
    ./vms.nix
  ];
  networking.hostName = "vm03";
  networking.interfaces.eth0.ipv4.addresses = [
    {
      address = "10.10.130.103";
      prefixLength = 24;
    }
  ];
}
