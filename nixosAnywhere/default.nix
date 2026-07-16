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
  vm01 = mkHost {
    inherit system username userConfig;
    modules = [
      ./vms/vm01.nix
    ];
  };
  vm01-install = mkHost {
    inherit system username userConfig;
    profile = "install";
    modules = [ ./vms/vm01-install.nix ];
  };
  vm02 = mkHost {
    inherit system username userConfig;
    modules = [
      ./vms/vm02.nix
    ];
  };
  vm02-install = mkHost {
    inherit system username userConfig;
    profile = "install";
    modules = [ ./vms/vm02-install.nix ];
  };
  vm03 = mkHost {
    inherit system username userConfig;
    modules = [
      ./vms/vm03.nix
    ];
  };
  vm03-install = mkHost {
    inherit system username userConfig;
    profile = "install";
    modules = [ ./vms/vm03-install.nix ];
  };
}
