#!/usr/bin/env bash
set -euo pipefail

# Fail if there are untracked files in the git working tree
if git rev-parse --git-dir >/dev/null 2>&1; then
  untracked="$(git ls-files --others --exclude-standard)"
  if [[ -n "$untracked" ]]; then
    echo "Error: There are untracked files in the repository. Commit or clean them before running." >&2
    echo "$untracked" >&2
    exit 1
  fi
fi

test -f /nix ||
	sh <(curl -Ss --proto '=https' --tlsv1.2 -L https://nixos.org/nix/install) --no-daemon

[ -z "${__ETC_PROFILE_NIX_SOURCED:-}" ] &&
	. "$HOME/.nix-profile/etc/profile.d/nix.sh"

# sadly claude is unfree

grep -q experimental-features ~/.config/nix/nix.conf || {
	mkdir -p ~/.config/nix
	echo "experimental-features = nix-command flakes" >> ~/.config/nix/nix.conf
}

# Generate user config dynamically so the flake evaluates with current user values
cat > "$(dirname "$0")/user-config.nix" << EOF
{
  username = "$(whoami)";
  homeDirectory = "$HOME";
}
EOF

nvfetcher &
nix flake update &
wait -n

# Use path: so Nix sees all files (including gitignored user-config.nix)
nix run home-manager/master -- switch --flake "path:$(dirname "$0")" --show-trace

for plugin in get-all klock ktop; do
  krew list 2>/dev/null | grep -q "^${plugin}$" || krew install "$plugin"
done