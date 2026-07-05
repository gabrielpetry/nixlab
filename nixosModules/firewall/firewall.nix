{
  config,
  lib,
  ...
}:

let
  cfg = config.nixlab.firewall;
in
{
  options.nixlab.firewall = {
    enable = lib.mkEnableOption "server firewall configuration";

    extraTcpPorts = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [
        22
        80
        443
      ];
      description = "TCP ports to allow in the firewall.";
    };

    extraUdpPorts = lib.mkOption {
      type = lib.types.listOf lib.types.port;
      default = [ 41641 ];
      description = "UDP ports to allow in the firewall.";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall = {
      enable = true;
      allowedTCPPorts = cfg.extraTcpPorts;
      allowedUDPPorts = cfg.extraUdpPorts;
    };
  };
}
