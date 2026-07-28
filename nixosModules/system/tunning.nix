{
  config,
  lib,
  ...
}:

let
  cfg = config.nixlab.tunning;
in
{
  options.nixlab.tunning = {
    enable = lib.mkEnableOption "server performance tuning";

    fsFileMax = lib.mkOption {
      type = lib.types.ints.positive;
      default = 4194304;
      description = "Maximum number of file handles available system-wide.";
    };

    inotifyMaxUserWatches = lib.mkOption {
      type = lib.types.ints.positive;
      default = 2097152;
      description = "Maximum inotify watches available to a user.";
    };

    nofileSoftLimit = lib.mkOption {
      type = lib.types.ints.positive;
      default = 4194304;
      description = "Soft per-process open-file limit.";
    };

    nofileHardLimit = lib.mkOption {
      type = lib.types.ints.positive;
      default = 4194304;
      description = "Hard per-process open-file limit.";
    };

    netSomaxconn = lib.mkOption {
      type = lib.types.ints.positive;
      default = 65535;
      description = "Maximum number of queued socket connections.";
    };

    vmMaxMapCount = lib.mkOption {
      type = lib.types.ints.positive;
      default = 262144;
      description = "Maximum number of memory map areas per process.";
    };
  };

  config = lib.mkIf cfg.enable {
    boot.kernel.sysctl = {
      "fs.file-max" = cfg.fsFileMax;
      "fs.inotify.max_user_watches" = cfg.inotifyMaxUserWatches;
      "fs.inotify.max_user_instances" = cfg.inotifyMaxUserWatches;
      "fs.nr_open" = cfg.nofileHardLimit;
      "net.core.somaxconn" = cfg.netSomaxconn;
      "net.core.netdev_max_backlog" = 16384;
      "net.ipv4.tcp_max_syn_backlog" = 65535;
      "net.ipv4.tcp_tw_reuse" = 1;
      "net.netfilter.nf_conntrack_max" = 262144;
      "vm.max_map_count" = cfg.vmMaxMapCount;
      "vm.overcommit_memory" = 1;
      "vm.swappiness" = 10;
      "vm.vfs_cache_pressure" = 200;
      "kernel.pid_max" = 4194304;
    };

    security.pam.loginLimits = [
      {
        domain = "*";
        item = "nofile";
        type = "soft";
        value = cfg.nofileSoftLimit;
      }
      {
        domain = "*";
        item = "nofile";
        type = "hard";
        value = cfg.nofileHardLimit;
      }
    ];

    systemd.services.k3s.serviceConfig = {
      LimitNOFILE = cfg.nofileHardLimit;
    };
  };
}
