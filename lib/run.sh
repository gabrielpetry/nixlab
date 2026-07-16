#!/usr/bin/env bash
set -euo pipefail

script_dir="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
project_root="$(git -C "$script_dir" rev-parse --show-toplevel)"

cd "$project_root"

# Require a clean tree so generated and updated files are deliberate.
if git -C "$project_root" rev-parse --git-dir >/dev/null 2>&1; then
  changes="$(git -C "$project_root" status --porcelain)"
  if [[ -n "$changes" ]]; then
    echo "Error: The repository has uncommitted changes. Commit or clean them before running." >&2
    echo "$changes" >&2
    exit 1
  fi
fi

test -d /nix ||
  sh <(curl -fSs --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --no-daemon

[ -z "${__ETC_PROFILE_NIX_SOURCED:-}" ] &&
  . "$HOME/.nix-profile/etc/profile.d/nix.sh"

# sadly claude is unfree

mkdir -p "$HOME/.config/nix"
if ! grep -Fqx 'experimental-features = nix-command flakes' "$HOME/.config/nix/nix.conf" 2>/dev/null; then
  printf '%s\n' 'experimental-features = nix-command flakes' >>"$HOME/.config/nix/nix.conf"
fi

# Generate user config dynamically so the flake evaluates with current user values
cat >"$project_root/user-config.nix" <<EOF
{
  username = "$(whoami)";
  homeDirectory = "$HOME";

  bws = {
    tokenFile = "/var/lib/bws/bws-token.cred";
  };

  k3s = {
    tokenFile = "/run/secrets/k3s-token";
  };
}
EOF

export NIXPKGS_ALLOW_UNFREE=1
nvfetcher

if [[ "${NIXLAB_UPDATE:-0}" == "1" ]]; then
  nix flake update
fi

# Use path: so Nix sees all files (including gitignored user-config.nix)
nix run home-manager/master -- switch --flake "path:$project_root" --show-trace --impure

for plugin in get-all klock ktop; do
  krew list 2>/dev/null | grep -q "^${plugin}$" || krew install "$plugin"
done
