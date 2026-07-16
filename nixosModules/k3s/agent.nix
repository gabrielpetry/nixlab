{
  config,
  lib,
  ...
}:

let
  cfg = config.nixlab.k3s.agent;
  k3sCfg = config.nixlab.k3s;
  flag = name: value: "--${name}=${value}";
  optionalFlag = name: value: lib.optional (value != null) (flag name value);
in
{
  options.nixlab.k3s.agent = {
    enable = lib.mkEnableOption "k3s agent";

    serverAddr = lib.mkOption {
      type = lib.types.nullOr lib.types.nonEmptyStr;
      default = null;
      example = "https://10.10.130.101:6443";
      description = "K3s server URL the agent joins.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.serverAddr != null;
        message = "nixlab.k3s.agent.serverAddr must be set when the agent is enabled.";
      }
    ];

    services.k3s = {
      enable = true;
      role = "agent";
      package = k3sCfg.package;
      serverAddr = cfg.serverAddr;
      extraFlags =
        lib.optional (k3sCfg.tokenFile != null) "--token-file=${k3sCfg.tokenFile}"
        ++ optionalFlag "node-ip" k3sCfg.nodeIp
        ++ optionalFlag "flannel-iface" k3sCfg.flannelIface;
    };
  };
}
