{
  inputs,
  system,
  username,
}:

let
  inherit (import ./lib.nix { inherit inputs system username; }) mkHost;
in
{
  # Clone a private repository into nixosAnywhere/local/ and use its
  # default.nix as the attrset entrypoint for private hosts.
  #
  # my-host = mkHost [
  #   ./local/my-host/disko.nix
  #   ./local/my-host/default.nix
  # ];
}
