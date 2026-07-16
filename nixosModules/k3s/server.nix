{
  config,
  pkgs,
  lib,
  ...
}:

let
  cfg = config.nixlab.k3s.server;
  k3sCfg = config.nixlab.k3s;
  yaml = pkgs.formats.yaml { };

  psaConfig = yaml.generate "k3s-psa.yaml" {
    apiVersion = "apiserver.config.k8s.io/v1";
    kind = "AdmissionConfiguration";
    plugins = [
      {
        name = "PodSecurity";
        configuration = {
          apiVersion = "pod-security.admission.config.k8s.io/v1";
          kind = "PodSecurityConfiguration";
          defaults = {
            enforce = cfg.podSecurity.enforce;
            enforce-version = cfg.podSecurity.enforceVersion;
            audit = cfg.podSecurity.audit;
            audit-version = cfg.podSecurity.auditVersion;
            warn = cfg.podSecurity.warn;
            warn-version = cfg.podSecurity.warnVersion;
          };
          exemptions = {
            usernames = [ ];
            runtimeClasses = [ ];
            namespaces = cfg.podSecurity.exemptNamespaces;
          };
        };
      }
    ];
  };

  auditPolicy = yaml.generate "k3s-audit-policy.yaml" {
    apiVersion = "audit.k8s.io/v1";
    kind = "Policy";
    omitStages = [ "RequestReceived" ];
    rules = [
      {
        level = "None";
        resources = [
          {
            group = "authentication.k8s.io";
            resources = [ "tokenreviews" ];
          }
        ];
      }
      {
        level = "Metadata";
        verbs = [
          "create"
          "update"
          "patch"
          "delete"
          "deletecollection"
        ];
        resources = [
          {
            group = "";
            resources = [
              "configmaps"
              "serviceaccounts"
              "persistentvolumes"
              "persistentvolumeclaims"
              "services"
            ];
          }
          {
            group = "apps";
            resources = [
              "daemonsets"
              "deployments"
              "replicasets"
              "statefulsets"
            ];
          }
          {
            group = "autoscaling";
            resources = [ "horizontalpodautoscalers" ];
          }
          {
            group = "batch";
            resources = [
              "cronjobs"
              "jobs"
            ];
          }
          {
            group = "networking.k8s.io";
            resources = [
              "ingresses"
              "networkpolicies"
            ];
          }
          {
            group = "rbac.authorization.k8s.io";
            resources = [
              "clusterrolebindings"
              "clusterroles"
              "rolebindings"
              "roles"
            ];
          }
          {
            group = "admissionregistration.k8s.io";
            resources = [
              "mutatingwebhookconfigurations"
              "validatingwebhookconfigurations"
            ];
          }
        ];
      }
      {
        level = "Metadata";
        verbs = [
          "create"
          "update"
          "patch"
          "delete"
          "deletecollection"
        ];
        resources = [
          {
            group = "";
            resources = [
              "pods"
              "namespaces"
            ];
          }
          {
            group = "certificates.k8s.io";
            resources = [ "certificatesigningrequests" ];
          }
        ];
      }
      {
        level = "Metadata";
        resources = [
          {
            group = "";
            resources = [
              "pods/log"
              "pods/status"
            ];
          }
        ];
      }
      {
        level = "Metadata";
        users = [ "system:kube-proxy" ];
        verbs = [ "watch" ];
      }
      {
        level = "Metadata";
        userGroups = [ "system:nodes" ];
      }
      {
        level = "Metadata";
        namespaces = [ "kube-system" ];
      }
      { level = "Metadata"; }
    ];
  };

  auditLogDirectory = builtins.dirOf cfg.audit.logFile;
  auditGroup = if cfg.audit.readerGroup == null then "root" else cfg.audit.readerGroup;
  auditPolicyEtcPath = lib.removePrefix "/etc/" cfg.audit.policyPath;
  kubeApiserverArg = name: value: "--kube-apiserver-arg=${name}=${toString value}";
  flag = name: value: "--${name}=${value}";
  optionalFlag = name: value: lib.optional (value != null) (flag name value);

  baseFlags = [
    "--bind-address=${cfg.bindAddress}"
    "--protect-kernel-defaults=true"
    (kubeApiserverArg "anonymous-auth" "false")
    "--kube-controller-manager-arg=bind-address=127.0.0.1"
    "--kube-scheduler-arg=bind-address=127.0.0.1"
  ]
  ++ lib.optional (k3sCfg.tokenFile != null) "--token-file=${k3sCfg.tokenFile}";

  podSecurityFlags = lib.optional cfg.podSecurity.enable (
    kubeApiserverArg "admission-control-config-file" psaConfig
  );

  auditFlags = lib.optionals cfg.audit.enable (
    [
      (kubeApiserverArg "audit-policy-file" cfg.audit.policyPath)
      (kubeApiserverArg "audit-log-path" cfg.audit.logFile)
      (kubeApiserverArg "audit-log-format" "json")
      (kubeApiserverArg "audit-log-maxage" cfg.audit.maxAge)
      (kubeApiserverArg "audit-log-maxbackup" cfg.audit.maxBackups)
      (kubeApiserverArg "audit-log-maxsize" cfg.audit.maxSize)
      (kubeApiserverArg "audit-log-mode" "batch")
    ]
    ++ lib.optional (cfg.audit.batchMaxSize != null) (
      kubeApiserverArg "audit-log-batch-max-size" cfg.audit.batchMaxSize
    )
  );

  optionalFlags =
    lib.optional cfg.disableHelmController "--disable-helm-controller"
    ++ optionalFlag "node-ip" k3sCfg.nodeIp
    ++ optionalFlag "flannel-iface" k3sCfg.flannelIface
    ++ map (flag "tls-san") cfg.tlsSans;
in
{
  options.nixlab.k3s.server = {
    enable = lib.mkEnableOption "k3s server";

    bindAddress = lib.mkOption {
      type = lib.types.nonEmptyStr;
      default = "0.0.0.0";
      description = "Address k3s binds the API server listener to.";
    };

    tlsSans = lib.mkOption {
      type = lib.types.listOf lib.types.nonEmptyStr;
      default = [ ];
      description = "Additional TLS SANs for the k3s API server certificate. Set host-specific IPs/DNS names explicitly.";
    };

    disableHelmController = lib.mkOption {
      type = lib.types.bool;
      default = true;
      description = "Disable the bundled k3s Helm controller.";
    };

    disableComponents = lib.mkOption {
      type = lib.types.listOf lib.types.nonEmptyStr;
      default = [ ];
      description = "Bundled k3s components to disable via --disable.";
    };

    podSecurity = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Pod Security Admission configuration.";
      };

      enforce = lib.mkOption {
        type = lib.types.enum [
          "privileged"
          "baseline"
          "restricted"
        ];
        default = "baseline";
        description = "Default Pod Security Admission enforce level.";
      };

      enforceVersion = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "latest";
        description = "Default Pod Security Admission enforce version.";
      };

      audit = lib.mkOption {
        type = lib.types.enum [
          "privileged"
          "baseline"
          "restricted"
        ];
        default = "restricted";
        description = "Default Pod Security Admission audit level.";
      };

      auditVersion = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "latest";
        description = "Default Pod Security Admission audit version.";
      };

      warn = lib.mkOption {
        type = lib.types.enum [
          "privileged"
          "baseline"
          "restricted"
        ];
        default = "restricted";
        description = "Default Pod Security Admission warning level.";
      };

      warnVersion = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "latest";
        description = "Default Pod Security Admission warning version.";
      };

      exemptNamespaces = lib.mkOption {
        type = lib.types.listOf lib.types.nonEmptyStr;
        default = [
          "kube-system"
          "kube-public"
          "kube-node-lease"
          "local-path-storage"
          "traefik"
          "argocd"
          "kyverno-system"
          "cert-manager"
          "secrets-store"
        ];
        description = "Namespaces exempt from default Pod Security Admission policy.";
      };
    };

    audit = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = true;
        description = "Enable Kubernetes API server audit logging.";
      };

      policyPath = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "/etc/rancher/k3s/audit-policy.yaml";
        description = "Path to the audit policy file used by kube-apiserver.";
      };

      logFile = lib.mkOption {
        type = lib.types.nonEmptyStr;
        default = "/var/log/rancher/k3s/audit/kube-apiserver-audit.json";
        description = "Path to the Kubernetes API server audit log file.";
      };

      readerGroup = lib.mkOption {
        type = lib.types.nullOr lib.types.nonEmptyStr;
        default = "wazuh";
        description = "Group granted read access to audit logs. Set to null to keep root-only access.";
      };

      maxAge = lib.mkOption {
        type = lib.types.ints.positive;
        default = 30;
        description = "Maximum number of days to retain audit logs.";
      };

      maxBackups = lib.mkOption {
        type = lib.types.ints.positive;
        default = 10;
        description = "Maximum number of rotated audit log files to retain.";
      };

      maxSize = lib.mkOption {
        type = lib.types.ints.positive;
        default = 100;
        description = "Maximum audit log size in megabytes before rotation.";
      };

      batchMaxSize = lib.mkOption {
        type = lib.types.nullOr lib.types.ints.positive;
        default = 1;
        description = "Maximum number of audit events per batch. Set null to omit the flag.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = !cfg.audit.enable || lib.hasPrefix "/etc/" cfg.audit.policyPath;
        message = "nixlab.k3s.server.audit.policyPath must be under /etc so NixOS can manage it declaratively.";
      }
    ];

    users.groups = lib.mkIf (cfg.audit.enable && cfg.audit.readerGroup != null) {
      ${cfg.audit.readerGroup} = { };
    };

    environment.etc = lib.mkIf cfg.audit.enable {
      ${auditPolicyEtcPath} = {
        source = auditPolicy;
        mode = "0640";
      };
    };

    systemd.tmpfiles.rules = lib.optionals cfg.audit.enable [
      "d /var/log/rancher 0755 root root -"
      "d /var/log/rancher/k3s 2750 root ${auditGroup} -"
      "d ${auditLogDirectory} 2750 root ${auditGroup} -"
      "f ${cfg.audit.logFile} 0640 root ${auditGroup} -"
    ];

    services.k3s = {
      enable = true;
      role = "server";
      package = k3sCfg.package;
      disable = cfg.disableComponents;
      extraFlags = baseFlags ++ podSecurityFlags ++ auditFlags ++ optionalFlags;
    };
  };
}
