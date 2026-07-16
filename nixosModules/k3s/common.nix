{
  config,
  pkgs,
  lib,
  userConfig ? { },
  ...
}:

let
  cfg = config.nixlab.k3s;
  enabled = cfg.server.enable || cfg.agent.enable;
in
{
  options.nixlab.k3s = {
    package = lib.mkOption {
      type = lib.types.package;
      default = pkgs.k3s_1_36;
      defaultText = "pkgs.k3s_1_36";
      description = "K3s package to run.";
    };

    tokenFile = lib.mkOption {
      type = lib.types.nullOr lib.types.nonEmptyStr;
      default = userConfig.k3s.tokenFile or "/run/secrets/k3s-token";
      description = ''
        Runtime path to the k3s cluster token file. The token value must not be stored in Nix.
        Set to null to omit --token-file and inject the token via K3S_TOKEN_FILE instead
        (for example, through a bws systemd credential attachment).
      '';
    };

    nodeIp = lib.mkOption {
      type = lib.types.nullOr lib.types.nonEmptyStr;
      default = null;
      description = "Node IP address advertised by k3s. Set per host.";
    };

    flannelIface = lib.mkOption {
      type = lib.types.nullOr lib.types.nonEmptyStr;
      default = null;
      description = "Network interface used by flannel. Set per host when required.";
    };

    openFirewall = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Open the K3s cluster ports in the NixOS firewall.";
    };
  };

  config = lib.mkIf enabled {
    assertions = [
      {
        assertion = cfg.tokenFile == null || !(lib.hasPrefix "/nix/store/" cfg.tokenFile);
        message = "nixlab.k3s.tokenFile must point to a runtime secret path, not the Nix store.";
      }
    ];

    boot.kernel.sysctl = {
      "vm.panic_on_oom" = 0;
      "vm.overcommit_memory" = 1;
      "kernel.panic" = 10;
      "kernel.panic_on_oops" = 1;
    };

    networking.firewall = lib.mkIf cfg.openFirewall {
      allowedTCPPorts = lib.optional cfg.server.enable 6443 ++ [ 10250 ];
      allowedUDPPorts = [ 8472 ];
    };
  };
}
