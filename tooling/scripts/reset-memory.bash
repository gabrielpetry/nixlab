#!/usr/bin/env bash
set -euo pipefail

if [[ "${EUID}" -ne 0 ]]; then
  echo "Run this script as root (sudo)." >&2
  exit 1
fi

echo "Syncing filesystem buffers..."
sync

echo "Dropping page cache, dentries, and inodes..."
echo 3 > /proc/sys/vm/drop_caches

echo "Resetting swap..."
swapoff -a
swapon -a

echo "Done."

