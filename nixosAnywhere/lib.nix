{
  inputs,
}:

let
  inherit (inputs) nixpkgs disko;
in
{
  mkHost =
    {
      system,
      username,
      userConfig ? { },
      profile ? "full",
      modules,
    }:
    let
      baseModules = [
        disko.nixosModules.disko
        ../nixosModules/common.nix
        ../nixosModules/firewall/firewall.nix
      ];
      runtimeModules = [
        ../nixosModules/bws/bws.nix
        ../nixosModules/docker/docker.nix
        ../nixosModules/exporters/otel.nix
        ../nixosModules/system/tunning.nix
        ../nixosModules/k3s/common.nix
        ../nixosModules/k3s/registry-mirror.nix
        ../nixosModules/k3s/server.nix
        ../nixosModules/k3s/agent.nix
      ];
      commonModules =
        baseModules
        ++ nixpkgs.lib.optionals (profile == "full") runtimeModules
        ++ [
          {
            nixpkgs.config.allowUnfreePredicate =
              pkg: profile == "full" && builtins.elem (nixpkgs.lib.getName pkg) [ "bws" ];

            services.openssh.settings = {
              KbdInteractiveAuthentication = false;
              PasswordAuthentication = false;
              PermitRootLogin = "prohibit-password";
            };

            nixlab.firewall.enable = true;
            nixlab.tunning.enable = true;
            nixlab.k3s.registryMirror.enable = true;

          }
        ];
    in
    nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit username userConfig;
      };
      modules = commonModules ++ modules;
    };
}
