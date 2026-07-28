{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.nixlab.k3s.registryMirror;
  yaml = pkgs.formats.yaml { };
  registriesConfig = yaml.generate "k3s-registries.yaml" {
    mirrors.${cfg.remote}.endpoint = [ cfg.endpoint ];
  };
in
{
  options.nixlab.k3s.registryMirror = {
    enable = lib.mkEnableOption "a K3s container registry mirror";

    remote = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "docker.io";
      description = "Registry name whose pulls are redirected to the mirror.";
    };

    endpoint = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "http://127.0.0.1:5000";
      description = "Mirror endpoint URL.";
    };

    configPath = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "/etc/rancher/k3s/registries.yaml";
      description = "Path to the K3s registry configuration file.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = lib.hasPrefix "/etc/" cfg.configPath;
        message = "nixlab.k3s.registryMirror.configPath must be under /etc.";
      }
    ];

    environment.etc = {
      "${lib.removePrefix "/etc/" cfg.configPath}" = {
        source = registriesConfig;
        mode = "0644";
      };
    };

    systemd.services.k3s = {
      restartTriggers = [ registriesConfig ];
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
    };
  };
}
