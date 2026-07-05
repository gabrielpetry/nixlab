{
  inputs,
  system,
  username,
}:

let
  inherit (inputs) nixpkgs disko;

  commonModules = [
    disko.nixosModules.disko
    ../nixosModules/common.nix
    ../nixosModules/firewall/firewall.nix
    ../nixosModules/docker/docker.nix
    ../nixosModules/exporters/otel.nix

    {
      nix.settings.trusted-users = [
        "root"
        username
      ];
      nixlab.docker.extraUsers = [ username ];
      services.openssh.settings = {
        KbdInteractiveAuthentication = false;
        PasswordAuthentication = false;
        PermitRootLogin = "prohibit-password";
      };

      nixlab.firewall.enable = true;

      nixlab.otelHostMetrics = {
        enable = true;
        otlpEndpoint = "otel-collector:4317"; # gRPC host:port, NOT a http(s):// URL
        otlpInsecure = true;
      };

      security.sudo.wheelNeedsPassword = false;
    }
  ];
in
{
  mkHost =
    modules:
    nixpkgs.lib.nixosSystem {
      inherit system;
      specialArgs = {
        inherit username;
      };
      modules = commonModules ++ modules;
    };
}
