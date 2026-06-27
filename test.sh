#!/usr/bin/env bash
set -euo pipefail

readonly repo_root="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly state_dir="$repo_root/.qemu-noble"
readonly image_url="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
readonly image_name="ubuntu-24.04-server-cloudimg-amd64.img"
readonly vm_disk_name="noble-server-cloudimg-amd64-overlay.qcow2"
readonly seed_name="seed.img"
readonly user_data_name="user-data"
readonly meta_data_name="meta-data"
readonly pid_name="qemu.pid"
readonly serial_log_name="serial.log"
readonly target_host="127.0.0.1"
readonly target_port="2222"
readonly vm_memory_mb="4096"
readonly vm_cpus="2"

usage() {
  cat <<'EOF'
Usage: ./test.sh <command>

Commands:
  up       Download and start the Ubuntu QEMU target
  reload   Recreate the QEMU target from the base image
  halt     Stop the QEMU target
  destroy  Remove the QEMU target and local state
  ssh      Open an SSH session to the target
  status   Show VM status
  ip       Print the SSH target

Example nixos-anywhere target:
  root@127.0.0.1 -p 2222
EOF
}

state_path() {
  printf '%s/%s\n' "$state_dir" "$1"
}

require_commands() {
  local commands=(curl qemu-img qemu-system-x86_64 cloud-localds ssh)
  local cmd

  for cmd in "${commands[@]}"; do
    command -v "$cmd" >/dev/null || {
      printf 'required command not found: %s\n' "$cmd" >&2
      exit 1
    }
  done
}

ensure_ssh_key() {
  if [[ ! -f "$HOME/.ssh/id_ed25519.pub" ]]; then
    printf 'missing SSH public key: %s\n' "$HOME/.ssh/id_ed25519.pub" >&2
    exit 1
  fi
}

ensure_state_dir() {
  mkdir -p "$state_dir"
}

download_base_image() {
  local image_path
  image_path="$(state_path "$image_name")"

  if [[ ! -f "$image_path" ]]; then
    curl -fL "$image_url" -o "$image_path"
  fi
}

render_cloud_init() {
  local user_data meta_data authorized_key

  user_data="$(state_path "$user_data_name")"
  meta_data="$(state_path "$meta_data_name")"
  authorized_key="$(<"$HOME/.ssh/id_ed25519.pub")"

  cat >"$user_data" <<EOF
#cloud-config
hostname: nixanywhere-target
manage_etc_hosts: true
disable_root: false
ssh_pwauth: false
users:
  - default
  - name: root
    lock_passwd: true
    ssh_authorized_keys:
      - $authorized_key
write_files:
  - path: /etc/ssh/sshd_config.d/99-nixanywhere.conf
    permissions: "0644"
    content: |
      PermitRootLogin prohibit-password
      PasswordAuthentication no
runcmd:
  - systemctl restart ssh
EOF

  cat >"$meta_data" <<EOF
instance-id: nixanywhere-target
local-hostname: nixanywhere-target
EOF
}

build_seed_image() {
  local seed_image user_data meta_data
  seed_image="$(state_path "$seed_name")"
  user_data="$(state_path "$user_data_name")"
  meta_data="$(state_path "$meta_data_name")"

  rm -f "$seed_image"
  cloud-localds "$seed_image" "$user_data" "$meta_data"
}

build_overlay_disk() {
  local base_image vm_disk
  base_image="$(state_path "$image_name")"
  vm_disk="$(state_path "$vm_disk_name")"

  if [[ ! -f "$vm_disk" ]]; then
    qemu-img create -f qcow2 -F qcow2 -b "$base_image" "$vm_disk" 30G >/dev/null
  fi
}

is_running() {
  local pid_file pid
  pid_file="$(state_path "$pid_name")"

  [[ -f "$pid_file" ]] || return 1
  pid="$(<"$pid_file")"

  kill -0 "$pid" 2>/dev/null || {
    rm -f "$pid_file"
    return 1
  }

  if [[ ! -r "/proc/$pid/cmdline" ]]; then
    rm -f "$pid_file"
    return 1
  fi

  if ! tr '\0' ' ' <"/proc/$pid/cmdline" | grep -Fq -- '-name nixanywhere-target'; then
    rm -f "$pid_file"
    return 1
  fi
}

wait_for_ssh() {
  local attempt

  for attempt in $(seq 1 60); do
    if ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=2 -p "$target_port" "root@$target_host" true >/dev/null 2>&1; then
      return 0
    fi

    sleep 2
  done

  printf 'timed out waiting for SSH on %s:%s\n' "$target_host" "$target_port" >&2
  return 1
}

qemu_accel() {
  if [[ -r /dev/kvm && -w /dev/kvm ]]; then
    printf 'kvm'
  else
    printf 'tcg'
  fi
}

start_vm() {
  local vm_disk seed_image pid_file serial_log
  vm_disk="$(state_path "$vm_disk_name")"
  seed_image="$(state_path "$seed_name")"
  pid_file="$(state_path "$pid_name")"
  serial_log="$(state_path "$serial_log_name")"

  if is_running; then
    printf 'VM is already running.\n'
    return 0
  fi

  rm -f "$pid_file"

  qemu-system-x86_64 \
    -name nixanywhere-target \
    -machine q35,accel="$(qemu_accel)" \
    -cpu max \
    -m "$vm_memory_mb" \
    -smp "$vm_cpus" \
    -daemonize \
    -display none \
    -serial "file:$serial_log" \
    -pidfile "$pid_file" \
    -drive file="$vm_disk",if=virtio,format=qcow2 \
    -drive file="$seed_image",if=virtio,format=raw,media=cdrom \
    -netdev user,id=net0,hostfwd=tcp:127.0.0.1:${target_port}-:22 \
    -device virtio-net-pci,netdev=net0 \
    -device virtio-rng-pci

  wait_for_ssh
}

stop_vm() {
  local pid_file pid
  pid_file="$(state_path "$pid_name")"

  if ! is_running; then
    printf 'VM is not running.\n'
    return 0
  fi

  ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -o ConnectTimeout=5 -p "$target_port" "root@$target_host" 'shutdown -h now' >/dev/null 2>&1 || true

  for _ in $(seq 1 30); do
    if ! is_running; then
      rm -f "$pid_file"
      return 0
    fi

    sleep 1
  done

  if is_running; then
    pid="$(<"$pid_file")"
    kill "$pid" >/dev/null 2>&1 || true
  fi

  rm -f "$pid_file"
}

recreate_vm() {
  stop_vm
  rm -f "$(state_path "$vm_disk_name")"
  rm -f "$(state_path "$seed_name")"
  up_vm
}

up_vm() {
  require_commands
  ensure_ssh_key
  ensure_state_dir
  download_base_image
  render_cloud_init
  build_seed_image
  build_overlay_disk
  start_vm
}

main() {
  local command="${1:-}"

  case "$command" in
  up)
    up_vm
    ;;
  reload)
    recreate_vm
    ;;
  halt)
    stop_vm
    ;;
  destroy)
    stop_vm
    rm -rf "$state_dir"
    ;;
  ssh)
    require_commands
    ssh -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null -p "$target_port" "root@$target_host"
    ;;
  status)
    if is_running; then
      printf 'running (pid %s)\n' "$(<"$(state_path "$pid_name")")"
    else
      printf 'stopped\n'
    fi
    ;;
  ip)
    printf 'root@%s -p %s\n' "$target_host" "$target_port"
    ;;
  "" | -h | --help | help)
    usage
    ;;
  *)
    printf 'Unknown command: %s\n\n' "$command" >&2
    usage >&2
    exit 1
    ;;
  esac
}

main "$@"
