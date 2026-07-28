{ lib, ... }:
{
  options.nixlab.multiplexer.autoStart = lib.mkOption {
    type = lib.types.nullOr (
      lib.types.enum [
        "herdr"
        "tmux"
      ]
    );
    default = "herdr";
    description = "Terminal multiplexer to start automatically in interactive Bash shells.";
  };
}
