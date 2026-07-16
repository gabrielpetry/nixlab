{
  inputs,
  system,
  username,
  userConfig ? { },
}:

let
  inherit (import ./lib.nix { inherit inputs; }) mkHost;
in
{
  # Example for optional private hosts if you want to keep separate files.
  # my-host = mkHost {
  #   inherit system username userConfig;
  #   modules = [
  #     ./local/my-host/default.nix
  #   ];
  # };
}
