{
  userConfig ? { },
  ...
}:

let
  k3sTokenSecretId = userConfig.k3s.tokenSecretId or null;
in
{
  imports = [
    ./vm01-install.nix
    ./vms.nix
  ];

  nixlab.k3s = {
    tokenFile = null;
    nodeIp = "10.10.130.101";
    flannelIface = "eth1";
    server = {
      enable = true;
      tlsSans = [ "10.10.130.101" ];
    };
  };

  bws = {
    enable = true;
    files.k3s-token = {
      path = "/var/lib/bws/k3s-token.cred";
      mode = "0400";
      owner = "root";
      group = "root";
      secretId = k3sTokenSecretId;
      storage = "systemd-credential";
      restartServices = [ "k3s" ];
    };
    systemd.k3s.files = [
      {
        name = "k3s-token";
        environmentVariable = "K3S_TOKEN_FILE";
      }
    ];
  };

  assertions = [
    {
      assertion = k3sTokenSecretId != null;
      message = "Provide userConfig.k3s.tokenSecretId in the non-versioned user-config.nix.";
    }
  ];
}
