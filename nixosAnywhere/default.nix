{
  inputs,
  system,
  username,
}:

let
  inherit (import ./lib.nix { inherit inputs system username; }) mkHost;
in
{
  vm01 = mkHost [
    ./vms/vm01.nix
  ];
  vm02 = mkHost [
    ./vms/vm02.nix
  ];
  vm03 = mkHost [
    ./vms/vm03.nix
  ];
}
