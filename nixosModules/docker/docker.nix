{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.nixlab.docker;
in
{

  options.nixlab.docker = {
    enable = lib.mkEnableOption "Docker with user group";
    extraUsers = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = "Users to add to the docker group";

    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      docker
      docker-compose
    ];

    virtualisation.docker = {
      enable = true;
      autoPrune.enable = true;
    };

    users.groups.docker.members = cfg.extraUsers;
  };
}
