{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.nixlab.otelHostMetrics;
  yaml = pkgs.formats.yaml { };

  sources = pkgs.callPackage ../../_sources/generated.nix { };

  srcByArch = {
    "x86_64-linux" = sources.otelcol-contrib-x64;
    "aarch64-linux" = sources.otelcol-contrib-arm64;
  };

  source = srcByArch.${pkgs.stdenv.hostPlatform.system};

  collectorPackage = pkgs.stdenv.mkDerivation {
    pname = "otelcol-contrib";
    inherit (source) version src;

    sourceRoot = ".";

    nativeBuildInputs = [ pkgs.autoPatchelfHook ];

    dontBuild = true;

    installPhase = ''
      runHook preInstall
      install -Dm755 otelcol-contrib $out/bin/otelcol-contrib
      runHook postInstall
    '';

    meta.mainProgram = "otelcol-contrib";
  };

  collectorConfig = yaml.generate "otel-host-metrics.yaml" {
    receivers.hostmetrics = {
      collection_interval = "60s";
      scrapers = {
        cpu = { };
        disk = { };
        filesystem = { };
        load = { };
        memory = { };
        network = { };
        paging = { };
        processes = { };
      };
    };

    exporters.otlp = {
      endpoint = cfg.otlpEndpoint;
      tls.insecure = cfg.otlpInsecure;
    };

    processors.batch = { };

    service.pipelines.metrics = {
      receivers = [ "hostmetrics" ];
      processors = [ "batch" ];
      exporters = [ "otlp" ];
    };
  };
in
{
  options.nixlab.otelHostMetrics = {
    enable = lib.mkEnableOption "OpenTelemetry host metrics collector";

    otlpEndpoint = lib.mkOption {
      type = lib.types.nonEmptyStr;
      example = "otel-collector.monitoring.svc.cluster.local:4317";
      description = "OTLP gRPC endpoint in host:port form that receives host metrics.";
    };

    otlpInsecure = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Use an insecure plaintext OTLP gRPC connection instead of TLS.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion =
          !(lib.hasPrefix "http://" cfg.otlpEndpoint || lib.hasPrefix "https://" cfg.otlpEndpoint);
        message = "nixlab.otelHostMetrics.otlpEndpoint must be an OTLP gRPC host:port endpoint, not a URL with http:// or https://";
      }
    ];

    systemd.services.otel-host-metrics = {
      description = "OpenTelemetry Host Metrics Collector";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];

      serviceConfig = {
        Type = "simple";
        DynamicUser = true;
        ExecStart = "${lib.getExe collectorPackage} --config=${collectorConfig}";
        Restart = "always";
        RestartSec = "5s";

        NoNewPrivileges = true;
        PrivateTmp = true;
        PrivateDevices = true;
        ProtectSystem = "strict";
        ProtectHome = "read-only";
        ProtectControlGroups = true;
        ProtectKernelLogs = true;
        ProtectKernelModules = true;
        ProtectKernelTunables = true;
        LockPersonality = true;
        MemoryDenyWriteExecute = true;
        RestrictNamespaces = true;
        RestrictSUIDSGID = true;
        SystemCallArchitectures = "native";
        UMask = "0077";
        CapabilityBoundingSet = "";
        AmbientCapabilities = "";
      };
    };
  };
}
