{ pkgs, lib, ... }:
let
  openspec = pkgs.buildNpmPackage rec {
    pname = "openspec";
    version = "1.4.1";

    src = pkgs.fetchurl {
      url = "https://registry.npmjs.org/@fission-ai/openspec/-/openspec-${version}.tgz";
      hash = "sha256-wDm2F6lhSZ9JRmeRhCYZGJmY7d3IsFz+2yLDIUKgx3o=";
    };

    npmDepsHash = "sha256-qYktmlDToJUZ4IJyggI6w3n53VhKNrrWhCu3Bq6R6SU=";

    postPatch = ''
      cp ${./openspec-package-lock.json} package-lock.json
    '';

    dontNpmBuild = true;

    meta = {
      description = "AI-native system for spec-driven development";
      homepage = "https://github.com/fission-ai/openspec";
      license = lib.licenses.mit;
      mainProgram = "openspec";
    };
  };
in
{
  home.packages = [ openspec ];
}
