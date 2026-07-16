{
  config,
  lib,
  pkgs,
  userConfig ? { },
  ...
}:

let
  cfg = config.bws;

  sources = pkgs.callPackage ../../_sources/generated.nix { };
  bwsSources = {
    "x86_64-linux" = sources.bws-x64;
    "aarch64-linux" = sources.bws-arm64;
  };
  bwsSource =
    bwsSources.${pkgs.stdenv.hostPlatform.system}
      or (throw "bws is not available for ${pkgs.stdenv.hostPlatform.system}");
  bwsPackage = pkgs.stdenv.mkDerivation {
    pname = "bws";
    version = bwsSource.version;
    src = bwsSource.src;
    nativeBuildInputs = [
      pkgs.autoPatchelfHook
      pkgs.unzip
    ];
    dontUnpack = true;
    installPhase = ''
      install -d "$out/bin"
      unzip -p "$src" bws > "$out/bin/bws"
      chmod 755 "$out/bin/bws"
    '';
    meta = {
      description = "Bitwarden Secrets Manager CLI";
      homepage = "https://bitwarden.com/products/secrets-manager/";
      license = lib.licenses.gpl3Only;
      mainProgram = "bws";
      platforms = builtins.attrNames bwsSources;
    };
  };

  inherit (lib)
    concatMapStringsSep
    escapeShellArg
    getExe
    getExe'
    hasPrefix
    mapAttrs'
    mapAttrsToList
    mkEnableOption
    mkIf
    mkOption
    nameValuePair
    optionalAttrs
    optionalString
    unique
    types
    ;

  bwsExe = getExe cfg.package;
  jqExe = getExe pkgs.jq;
  serverArg = optionalString (cfg.serverUrl != null) "--server-url ${escapeShellArg cfg.serverUrl}";
  systemdCredsExe = getExe' pkgs.systemd "systemd-creds";

  envEntryModule =
    { ... }:
    {
      options = {
        secretId = mkOption {
          type = types.nullOr types.nonEmptyStr;
          default = null;
          description = "Bitwarden secret UUID used for this environment value.";
        };

        value = mkOption {
          type = types.nullOr types.str;
          default = null;
          description = "Literal environment value. This is not suitable for secrets because it can end up in the Nix store.";
        };
      };
    };

  fileModule =
    { ... }:
    {
      options = {
        path = mkOption {
          type = types.nonEmptyStr;
          description = "Absolute target path on the host.";
        };

        mode = mkOption {
          type = types.str;
          default = "0400";
          description = "File mode applied to the generated file.";
        };

        createParentDirectories = mkOption {
          type = types.bool;
          default = true;
          description = "Create the parent directory when it does not exist.";
        };

        directoryMode = mkOption {
          type = types.str;
          default = "0700";
          description = "Mode used when creating the parent directory.";
        };

        owner = mkOption {
          type = types.nullOr types.nonEmptyStr;
          default = null;
          description = "Owner applied to the generated file. Supported on NixOS only.";
        };

        group = mkOption {
          type = types.nullOr types.nonEmptyStr;
          default = null;
          description = "Group applied to the generated file. Supported on NixOS only.";
        };

        secretId = mkOption {
          type = types.nullOr types.nonEmptyStr;
          default = null;
          description = "Bitwarden secret UUID whose value becomes the full file content.";
        };

        env = mkOption {
          type = types.attrsOf (types.submodule envEntryModule);
          default = { };
          description = "Environment-style file entries rendered as KEY=VALUE lines.";
        };

        envFormat = mkOption {
          type = types.enum [
            "plain"
            "systemd"
          ];
          default = "plain";
          description = "How environment values are rendered when env is used.";
        };

        storage = mkOption {
          type = types.enum [
            "systemd-credential"
            "plain"
          ];
          default = "systemd-credential";
          description = ''
            How the fetched file is stored on disk.
            systemd-credential encrypts the file with systemd-creds(1); it can only be
            decrypted by systemd services that reference it via LoadCredentialEncrypted=.
            plain writes the raw value as a regular file (less secure, but usable by any
            consumer without systemd credential plumbing).
          '';
        };

        restartServices = mkOption {
          type = types.listOf types.nonEmptyStr;
          default = [ ];
          description = "Systemd services to restart after this file is refreshed successfully.";
        };
      };
    };

  systemdFileEntryModule =
    { ... }:
    {
      options = {
        name = mkOption {
          type = types.nonEmptyStr;
          description = "Name from bws.files that must be fetched before this systemd service starts.";
        };

        environmentVariable = mkOption {
          type = types.nullOr types.nonEmptyStr;
          default = null;
          description = ''
            If set, inject an Environment entry into the service pointing to the decrypted
            credential path. This is only relevant when the target file uses
            systemd-credential storage and the consumer expects a file-path env var.
          '';
        };
      };
    };

  validFileName = name: builtins.match "^[A-Za-z0-9_.-]+$" name != null;
  validEnvKey = key: builtins.match "^[A-Za-z_][A-Za-z0-9_]*$" key != null;
  hasEnvEntries = fileCfg: fileCfg.env != { };
  isAbsolutePath = path: hasPrefix "/" path;
  isStorePath = path: hasPrefix "/nix/store/" path;
  hasNewline = value: builtins.match ".*[\n\r].*" value != null;

  fileUnitName = fileName: "bws-file-${fileName}";
  fileHelpers = ''
    set -euo pipefail

    fetch_secret_value() {
      local secret_id="$1"

      ${bwsExe} secret get "$secret_id" ${serverArg} --output json | ${jqExe} -er '.value | strings'
    }

    require_single_line_env_value() {
      local key="$1"
      local value="$2"

      if [[ "$value" == *$'\n'* || "$value" == *$'\r'* ]]; then
        printf 'bws env value for %s must be a single line\n' "$key" >&2
        return 1
      fi
    }

    quote_systemd_env_value() {
      local value="$1"

      value="''${value//\\/\\\\}"
      value="''${value//\"/\\\"}"
      value="''${value//\$/\\$}"
      value="''${value//\`/\\\`}"

      printf '"%s"' "$value"
    }

    append_env_plain() {
      local target_file="$1"
      local key="$2"
      local value="$3"

      require_single_line_env_value "$key" "$value"
      printf '%s=%s\n' "$key" "$value" >> "$target_file"
    }

    append_env_systemd() {
      local target_file="$1"
      local key="$2"
      local value="$3"
      local rendered

      require_single_line_env_value "$key" "$value"
      rendered="$(quote_systemd_env_value "$value")"
      printf '%s=%s\n' "$key" "$rendered" >> "$target_file"
    }

    encrypt_to_file() {
      local cred_name="$1"
      local input_file="$2"
      local output_file="$3"

      ${systemdCredsExe} encrypt --with-key=auto --name="$cred_name" "$input_file" "$output_file"
    }
  '';

  mkChownLine =
    fileCfg: varName:
    let
      chownTarget =
        if fileCfg.owner != null && fileCfg.group != null then
          "${fileCfg.owner}:${fileCfg.group}"
        else if fileCfg.owner != null then
          fileCfg.owner
        else if fileCfg.group != null then
          ":${fileCfg.group}"
        else
          null;
    in
    optionalString (chownTarget != null) ''
      chown ${escapeShellArg chownTarget} "${"$"}${varName}"
    '';

  mkEnvAppendLine =
    envFormat: key: envCfg:
    let
      valueExpr =
        if envCfg.secretId != null then
          ''"$(fetch_secret_value ${escapeShellArg envCfg.secretId})"''
        else
          escapeShellArg envCfg.value;
    in
    ''
      append_env_${envFormat} "$tmp_plain" ${escapeShellArg key} ${valueExpr}
    '';

  mkFileScript =
    fileName: fileCfg:
    let
      tempTemplate = "${builtins.dirOf fileCfg.path}/.${builtins.baseNameOf fileCfg.path}.XXXXXX";

      contentScript =
        if fileCfg.secretId != null then
          ''
            fetch_secret_value ${escapeShellArg fileCfg.secretId} > "$tmp_plain"
          ''
        else
          ''
            : > "$tmp_plain"
            ${concatMapStringsSep "\n" (key: mkEnvAppendLine fileCfg.envFormat key fileCfg.env.${key}) (
              builtins.attrNames fileCfg.env
            )}
          '';

      finishScript =
        if fileCfg.storage == "systemd-credential" then
          ''
            tmp_enc="$(mktemp ${escapeShellArg tempTemplate})"
            encrypt_to_file ${escapeShellArg fileName} "$tmp_plain" "$tmp_enc"
            rm -f "$tmp_plain"
            chmod ${escapeShellArg fileCfg.mode} "$tmp_enc"
            ${mkChownLine fileCfg "tmp_enc"}
            mv -f "$tmp_enc" ${escapeShellArg fileCfg.path}
          ''
        else
          ''
            chmod ${escapeShellArg fileCfg.mode} "$tmp_plain"
            ${mkChownLine fileCfg "tmp_plain"}
            mv -f "$tmp_plain" ${escapeShellArg fileCfg.path}
          '';
    in
    ''
      tmp_plain="$(mktemp ${escapeShellArg tempTemplate})"
      trap 'rm -f "$tmp_plain"' EXIT
      ${contentScript}
      ${finishScript}
    '';

  mkFetchUnit =
    fileName: fileCfg:
    nameValuePair (fileUnitName fileName) {
      description = "Fetch Bitwarden secret file ${fileName}";
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];
      unitConfig.ConditionPathExists = cfg.tokenFile;

      serviceConfig = {
        Type = "oneshot";
        User = "root";
        Group = "root";
        LoadCredentialEncrypted = [ "bws-token:${cfg.tokenFile}" ];
        PrivateTmp = true;
        NoNewPrivileges = true;
        ProtectSystem = "strict";
        ReadWritePaths = [ (builtins.dirOf fileCfg.path) ];
      };

      script = ''
        export BWS_ACCESS_TOKEN="$(<"$CREDENTIALS_DIRECTORY/bws-token")"
        ${fileHelpers}
        ${mkFileScript fileName fileCfg}
      '';
    };

  mkRefreshTimer =
    fileName: _:
    nameValuePair (fileUnitName fileName) {
      description = "Refresh Bitwarden secret file ${fileName}";
      wantedBy = [ "timers.target" ];
      timerConfig = {
        OnBootSec = "5min";
        OnUnitActiveSec = cfg.refreshInterval;
        Persistent = true;
        Unit = "${fileUnitName fileName}-refresh.service";
      };
    };

  mkRefreshService =
    fileName: fileCfg:
    nameValuePair "${fileUnitName fileName}-refresh" {
      description = "Refresh Bitwarden secret file ${fileName} and restart consumers";
      serviceConfig = {
        Type = "oneshot";
        ExecStart = pkgs.writeShellScript "bws-refresh-${fileName}" ''
          set -euo pipefail
          ${getExe' pkgs.systemd "systemctl"} restart ${fileUnitName fileName}.service
          ${concatMapStringsSep "\n" (
            service: "${getExe' pkgs.systemd "systemctl"} try-restart ${escapeShellArg service}.service"
          ) fileCfg.restartServices}
        '';
      };
    };

  collectAttached =
    entries: f:
    lib.concatMap (
      entry:
      let
        fileCfg = cfg.files.${entry.name} or null;
      in
      if fileCfg == null then [ ] else f entry fileCfg
    ) entries;

  systemdAttachmentConfig = mapAttrs' (
    serviceName: serviceCfg:
    let
      fileNames = map (f: f.name) serviceCfg.files;
      units = map (fileName: "${fileUnitName fileName}.service") fileNames;

      credentialLoads = collectAttached serviceCfg.files (
        entry: fileCfg:
        lib.optional (fileCfg.storage == "systemd-credential") "${entry.name}:${fileCfg.path}"
      );

      environmentFileEntries = collectAttached serviceCfg.files (
        entry: fileCfg:
        lib.optional (hasEnvEntries fileCfg) (
          if fileCfg.storage == "systemd-credential" then "%d/${entry.name}" else fileCfg.path
        )
      );

      environmentVarEntries = collectAttached serviceCfg.files (
        entry: fileCfg:
        lib.optional (
          entry.environmentVariable != null && fileCfg.storage == "systemd-credential"
        ) "${entry.environmentVariable}=%d/${entry.name}"
      );

      conditionPaths = collectAttached serviceCfg.files (_: fileCfg: [ fileCfg.path ]);
    in
    nameValuePair serviceName {
      overrideStrategy = "asDropinIfExists";
      after = units;
      requires = units;
      serviceConfig =
        { }
        // optionalAttrs (credentialLoads != [ ]) { LoadCredentialEncrypted = credentialLoads; }
        // optionalAttrs (environmentFileEntries != [ ]) { EnvironmentFile = environmentFileEntries; }
        // optionalAttrs (environmentVarEntries != [ ]) { Environment = environmentVarEntries; };
      unitConfig.ConditionPathExists = unique conditionPaths;
    }
  ) cfg.systemd;

  allFiles = mapAttrsToList nameValuePair cfg.files;
  allEnvEntries = lib.concatLists (
    map (
      file:
      map (key: {
        inherit key;
        fileName = file.name;
        value = file.value.env.${key};
      }) (builtins.attrNames file.value.env)
    ) allFiles
  );
in
{
  options.bws = {
    enable = mkEnableOption "Bitwarden-managed runtime files";

    package = mkOption {
      type = types.package;
      default = bwsPackage;
      defaultText = "nvfetcher-managed bws release";
      description = "Bitwarden Secrets Manager CLI package.";
    };

    tokenFile = mkOption {
      type = types.nullOr types.nonEmptyStr;
      default = userConfig.bws.tokenFile or null;
      example = "/var/lib/bws/bws-token.cred";
      description = "Path to the encrypted Bitwarden Secrets Manager access token file (created with systemd-creds encrypt).";
    };

    serverUrl = mkOption {
      type = types.nullOr types.nonEmptyStr;
      default = null;
      example = "https://bitwarden.example.com";
      description = "Optional Bitwarden server URL for self-hosted or EU deployments.";
    };

    refreshInterval = mkOption {
      type = types.nonEmptyStr;
      default = "1h";
      example = "30min";
      description = "Default refresh cadence for NixOS systemd timers that re-fetch Bitwarden-managed files.";
    };

    files = mkOption {
      type = types.attrsOf (types.submodule fileModule);
      default = { };
      description = "Files whose content is fetched from Bitwarden at activation or runtime.";
    };

    systemd = mkOption {
      type = types.attrsOf (
        types.submodule (
          { ... }: {
            options.files = mkOption {
              type = types.listOf (types.submodule systemdFileEntryModule);
              default = [ ];
              description = "File entries that must be fetched and injected as systemd credentials before this service starts.";
            };
          }
        )
      );
      default = { };
      description = "NixOS-only helper to order Bitwarden files before selected systemd services.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.tokenFile != null;
        message = "bws.tokenFile must be set when bws.enable is true.";
      }
      {
        assertion = cfg.tokenFile == null || !isStorePath cfg.tokenFile;
        message = "bws.tokenFile must point to a host path, not the Nix store.";
      }
      {
        assertion = cfg.tokenFile == null || isAbsolutePath cfg.tokenFile;
        message = "bws.tokenFile must be an absolute host path.";
      }
    ]
    ++ lib.concatMap (file: [
      {
        assertion = validFileName file.name;
        message = "bws.files.${file.name} must use only letters, numbers, '.', '_' or '-'.";
      }
      {
        assertion = isAbsolutePath file.value.path;
        message = "bws.files.${file.name}.path must be an absolute path.";
      }
      {
        assertion = !isStorePath file.value.path;
        message = "bws.files.${file.name}.path must not point into the Nix store.";
      }
      {
        assertion = (file.value.secretId != null) != hasEnvEntries file.value;
        message = "bws.files.${file.name} must set exactly one of secretId or env.";
      }
    ]) allFiles
    ++ lib.concatMap (entry: [
      {
        assertion = validEnvKey entry.key;
        message = "bws.files.${entry.fileName}.env.${entry.key} is not a valid environment variable name.";
      }
      {
        assertion = (entry.value.secretId != null) != (entry.value.value != null);
        message = "bws.files.${entry.fileName}.env.${entry.key} must set exactly one of secretId or value.";
      }
      {
        assertion = entry.value.value == null || !hasNewline entry.value.value;
        message = "bws.files.${entry.fileName}.env.${entry.key}.value must be a single line.";
      }
    ]) allEnvEntries
    ++ lib.concatMap (
      serviceName:
      let
        serviceCfg = cfg.systemd.${serviceName};
        names = map (entry: entry.name) serviceCfg.files;
        envNames = map (entry: entry.environmentVariable) (
          builtins.filter (entry: entry.environmentVariable != null) serviceCfg.files
        );
      in
      [
        {
          assertion = lib.unique names == names;
          message = "bws.systemd.${serviceName}.files must not contain duplicate file names.";
        }
        {
          assertion = lib.unique envNames == envNames;
          message = "bws.systemd.${serviceName}.files must not contain duplicate environmentVariable values.";
        }
      ]
      ++ map (entry: {
        assertion = entry.environmentVariable == null || validEnvKey entry.environmentVariable;
        message = "bws.systemd.${serviceName}.files environmentVariable must be a valid environment variable name.";
      }) serviceCfg.files
    ) (builtins.attrNames cfg.systemd)
    ++ lib.concatMap (
      serviceName:
      let
        serviceCfg = cfg.systemd.${serviceName};
        fileNames = map (f: f.name) serviceCfg.files;
      in
      map (fileName: {
        assertion = builtins.hasAttr fileName cfg.files;
        message = "bws.systemd.${serviceName}.files references undefined bws.files.${fileName}.";
      }) fileNames
      ++ map (entry: {
        assertion =
          entry.environmentVariable == null
          || !(builtins.hasAttr entry.name cfg.files)
          || cfg.files.${entry.name}.storage == "systemd-credential";
        message = "bws.systemd.${serviceName}.files entries with environmentVariable require systemd-credential storage.";
      }) serviceCfg.files
    ) (builtins.attrNames cfg.systemd);

    systemd.services =
      (optionalAttrs (cfg.tokenFile != null) (mapAttrs' mkFetchUnit cfg.files))
      // (optionalAttrs (cfg.tokenFile != null) (mapAttrs' mkRefreshService cfg.files))
      // systemdAttachmentConfig;
    systemd.timers = optionalAttrs (cfg.tokenFile != null) (mapAttrs' mkRefreshTimer cfg.files);
    systemd.tmpfiles.rules = map (
      file: "d ${escapeShellArg (builtins.dirOf file.value.path)} ${file.value.directoryMode} root root -"
    ) (builtins.filter (file: file.value.createParentDirectories) allFiles);
  };
}
