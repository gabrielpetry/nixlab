{ pkgs, ... }:
let
  sources = pkgs.callPackage ../_sources/generated.nix {};

  srcByArch = {
    "x86_64-linux"  = sources.pi-coding-agent-x64;
    "aarch64-linux" = sources.pi-coding-agent-arm64;
  };

  source = srcByArch.${pkgs.stdenv.hostPlatform.system};

  pi-coding-agent = pkgs.stdenv.mkDerivation {
    pname = "pi-coding-agent";
    inherit (source) version src;

    nativeBuildInputs = [ pkgs.autoPatchelfHook pkgs.makeWrapper ];
    buildInputs = [ pkgs.stdenv.cc.cc.lib ];

    dontBuild = true;

    installPhase = ''
      mkdir -p $out/share/pi $out/bin
      cp -r . $out/share/pi/
      makeWrapper $out/share/pi/pi $out/bin/pi \
        --chdir $out/share/pi
    '';
  };
in {
  home.packages = [ pi-coding-agent ];
}
