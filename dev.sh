#!/usr/bin/env bash

set -Eeuo pipefail

# shellcheck source=lib/bash-simple-doc.sh
source "$(dirname "${BASH_SOURCE[0]}")/lib/bash-simple-doc.sh"
unset name # this is already set in nix
export PROJECT_ROOT
PROJECT_ROOT="$(git rev-parse --show-toplevel)"
readonly VM_DIR="${PROJECT_ROOT}/.vm"
readonly VM_CONFIG="${VM_DIR}/machines"
readonly UBUNTU_CLOUD_IMAGE_URL="https://cloud-images.ubuntu.com/noble/current/noble-server-cloudimg-amd64.img"
readonly UBUNTU_CLOUD_IMAGE="${VM_DIR}/ubuntu-server-amd64.img"
readonly SSH_KEY="${VM_DIR}/ssh/id_rsa"
export VIRSH_NETWORK="nixlab"
export VIRSH_NETWORK_BRIDGE_NAME="virbr100"
readonly TEMPLATES_DIR="${PROJECT_ROOT}/.vm/templates"

function ensure_dirs {
	mkdir -p "$VM_DIR" ||
		log_fail "Failed to create vm directory"
	mkdir -p "$(dirname "$SSH_KEY")" ||
		log_fail "Failed to create ssh directory"
	mkdir -p "$VM_CONFIG" ||
		log_fail "Failed to create vm config directory"
}

function download_iso {
	@internal
	@doc "Download the ubuntu cloud image"

	if [[ -f "$UBUNTU_CLOUD_IMAGE" ]]; then
		log_debug "Skipping, image already downloaded"
	else
		wget -O "$UBUNTU_CLOUD_IMAGE" "$UBUNTU_CLOUD_IMAGE_URL" ||
			log_fail "Failed to download ubuntu cloud image"
	fi
}

function generate_ssh_key {
	@internal
	@doc "Generate ssh key pair for the virtual machine"

	if [[ -f "$SSH_KEY" ]]; then
		log_debug "Skipping, ssh key already generated"
	else
		ssh-keygen -t rsa -b 4096 -f "$SSH_KEY" -N "" ||
			log_fail "Failed to generate ssh key"
	fi
}

function generate_cloud_init_user_data {
	@internal
	@doc "Generate cloud-init user-data file for the virtual machine"
	@arg "required" "--name|-n" "name of the virtual machine"
	local name
	@args "$@"

	mkdir -p "${VM_CONFIG}/${name}" || log_fail "Failed to create vm directory for ${name}"
	local user_data_file="${VM_CONFIG}/${name}/user-data.yaml"
	if [[ -f "$user_data_file" ]]; then
		log_debug "Skipping, user-data already generated $user_data_file"
	else
		export password ssh_public_key
		password=$(openssl rand -base64 12)
		ssh_public_key=$(cat "${SSH_KEY}.pub")
		log_debug "Generating user-data file for ${name} with password ${password} and ssh_public_key ${ssh_public_key}"
		envsubst <"${TEMPLATES_DIR}/user-data.yaml" >"$user_data_file" ||
			log_fail "Failed to generate user-data"
		log_info "Generated user-data file at ${user_data_file}"
	fi
}

function generate_cloud_init_network_config {
	@internal
	@doc "Generate cloud-init network-config file for the virtual machine"
	@arg "required" "--name|-n" "name of the virtual machine"
	@arg "required" "--ip|-i" "full IP address of the virtual machine"
	local name ip
	@args "$@"
	mkdir -p "${VM_CONFIG}/${name}" || log_fail "Failed to create vm directory for ${name}"
	local network_config_file="${VM_CONFIG}/${name}/network-config.yaml"
	if [[ -f "$network_config_file" ]]; then
		log_debug "Skipping, network-config already generated $network_config_file"
	else
		export IP="${ip}"
		log_debug "Generating network-config file for ${name} with IP ${ip}"
		envsubst <"${TEMPLATES_DIR}/network-config.yaml" >"$network_config_file" ||
			log_fail "Failed to generate network-config"
		log_info "Generated network-config file at ${network_config_file}"
	fi
}

function generate_cloud_init {
	@internal
	@doc "Generate cloud-init files for the virtual machine"
	@arg "required" "--name|-n" "name of the virtual machine"
	@arg "required" "--ip|-i" "full IP address of the virtual machine"
	local name ip
	@args "$@"

	generate_cloud_init_user_data --name "$name"

	generate_cloud_init_network_config --name "$name" --ip "$ip"

	export VM_HOSTNAME="${name}"
	envsubst <"${TEMPLATES_DIR}/meta-data.yaml" >"${VM_CONFIG:?}/${name:?}/meta-data.yaml" ||
		log_fail "Failed to generate meta-data"
}

function generate_virsh_network {
	@doc "Generate a virsh network for the virtual machine"
	@arg "required" "--ip" "IP address of the virsh network"
	@arg "required" "--netmask" "Netmask of the virsh network"

	local ip netmask
	@args "$@"

	export VIRSH_NETWORK_IP="${ip}"
	export VIRSH_NETWORK_NETMASK="${netmask}"

	if ! virsh net-info "$VIRSH_NETWORK" &>/dev/null; then
		envsubst <"${TEMPLATES_DIR}/virsh-network.xml" >"${VM_CONFIG}/${VIRSH_NETWORK}.xml" ||
			log_fail "Failed to generate virsh network xml"

		virsh net-define "${VM_CONFIG}/${VIRSH_NETWORK}.xml" ||
			log_fail "Failed to define virsh network"
	fi

	if ! virsh net-info "$VIRSH_NETWORK" | grep -qE "Active:\s+yes"; then
		virsh net-start "$VIRSH_NETWORK" ||
			log_fail "Failed to start virsh network"
	fi

	virsh net-autostart "$VIRSH_NETWORK" ||
		log_fail "Failed to set virsh network to autostart"

}

function install {
	@doc "Install the ubuntu vm using virt-install"
	@arg "required" "--name|-n" "name of the virtual machine"
	@arg "default=2" "--vcpu|-c" "amount of cpu cores"
	@arg "default=2048" "--memory|-m" "amount of memory"
	@arg "required" "--ip|-i" "full IP address of the virtual machine"
	local name vcpu memory ip
	@args "$@"

	download_iso

	generate_ssh_key --name "$name" ||
		log_fail "Failed to generate ssh key"

	generate_cloud_init --name "$name" --ip "$ip"


	sudo mkdir -p /var/lib/libvirt/images/nixlab/ ||
		log_fail "Failed to create vm image directory"
	local vm_image="/var/lib/libvirt/images/nixlab/${name}.qcow2"
	if [[ ! -f "$vm_image" ]]; then
		log_info "Creating vm image at ${vm_image}"
		sudo qemu-img convert -O qcow2 "$UBUNTU_CLOUD_IMAGE" "$vm_image" ||
			log_fail "Failed to convert base image to qcow2"
	fi
	local user_data meta_data network_config
	user_data="${VM_CONFIG}/${name}/user-data.yaml"
	meta_data="${VM_CONFIG}/${name}/meta-data.yaml"
	network_config="${VM_CONFIG}/${name}/network-config.yaml"
	virt-install \
		--name "${name}" \
		--noautoconsole \
		--import \
		--memory "${memory}" \
		--vcpus="${vcpu}" \
		--osinfo ubuntunoble \
		--disk bus=virtio,path="${vm_image}" \
		--network "network=${VIRSH_NETWORK},model=virtio" \
		--graphics none \
		--console pty,target_type=serial \
		--cloud-init "user-data=$user_data,meta-data=$meta_data,network-config=$network_config" ||
		log_fail "Failed to install virtual machine"
}

function destroy {
	@doc "Destroy the virtual machine"
	@arg "required" "--name|-n" "name of the virtual machine"
	local name
	@args "$@"
	
	virsh destroy "$name" || true
	virsh undefine "$name" || true

	if [[ -d "${VM_CONFIG}/${name}" ]]; then
		log_info "Removing cloud init files at ${VM_CONFIG}/${name}"
		rm -rf "${VM_CONFIG:?}/${name:?}" ||
			log_fail "Failed to remove cloud init files"
	fi

	if [[ -f "/var/lib/libvirt/images/nixlab/${name}.qcow2" ]]; then
		log_info "Removing virtual machine image at /var/lib/libvirt/images/nixlab/${name}.qcow2"
		sudo rm -f "/var/lib/libvirt/images/nixlab/${name}.qcow2" ||
			log_fail "Failed to remove virtual machine image"
	fi
}

function console {
	@doc "Connect to the virtual machine console"
	@arg "--name|-n" "name of the virtual machine"
	@position "name" "name of the virtual machine"
	local name
	@args "$@"

	virsh console "$name" ||
		log_fail "Failed to connect to virtual machine console"
}

function machine_cpu_time {
	@internal
	local name="$1"

	virsh domstats --cpu-total "$name" | grep '^cpu.time=' | cut -d'=' -f2
}

function machine_vcpu_count {
	@internal
	local name="$1"

	virsh dominfo "$name" | grep 'CPU(s)' | awk '{print $2}'
}

function machine_status {
	@internal
	@doc "Status of the virtual machine"
	@arg "required" "--name|-n" "name of the virtual machine"
	@arg "--cpu" "cpu usage percentage"
	local name cpu="-"
	@args "$@"
	resources="$(virsh domstats --cpu-total --balloon "$name")"

	memory="$(echo "$resources" | grep 'balloon.rss' | cut -d'=' -f2)"             # KiB
	total_memory="$(virsh dominfo "$name" | grep 'Max memory' | awk '{print $3}')" #KiB
	memory_mb=$((memory / 1024))
	total_memory_mb=$((total_memory / 1024))
	status="$(virsh dominfo "$name" | grep 'State' | awk '{print $2}')"
	ip="$(grep -A 2 "addresses:" "${VM_CONFIG:?}/${name:?}/network-config.yaml" | awk '{print $2}' | cut -d'/' -f1 | grep -v '^$' | head -n 1)"
	printf "%-10s\t %-12s\t %-6s\t %-8s\t %s\n" \
		"$name" \
		"${memory_mb}MB/${total_memory_mb}MB" \
		"${cpu}" \
		"$status" \
		"$ip"
}

function ps {
	@doc "Status of the virtual machine"
	@arg "--name|-n" "name of the virtual machine"
	local name vcpu_count
	@args "$@"
	local interval_seconds=1
	local -a vms
	declare -A cpu_start cpu_end cpu_usage
	printf "%-10s\t %-12s\t %-6s\t %-8s\t %s\n" "NAME" "MEMORY" "CPU" "STATUS" "IP"
	if [[ -n "$name" ]]; then
		vms=("$name")
	else
		mapfile -t vms < <(virsh list --all --name | grep -v '^$')
	fi

	if [[ "${#vms[@]}" -eq 0 ]]; then
		return 0
	fi

	for vm in "${vms[@]}"; do
		cpu_start["$vm"]="$(machine_cpu_time "$vm" 2>/dev/null || printf '0')"
	done

	sleep "$interval_seconds"

	for vm in "${vms[@]}"; do
		cpu_end["$vm"]="$(machine_cpu_time "$vm" 2>/dev/null || printf '0')"
		vcpu_count="$(machine_vcpu_count "$vm")"
		cpu_usage["$vm"]="$(awk -v start="${cpu_start[$vm]:-0}" -v end="${cpu_end[$vm]:-0}" -v interval="$interval_seconds" -v vcpus="$vcpu_count" 'BEGIN {
			delta = end - start
			if (delta < 0 || interval <= 0 || vcpus <= 0) {
				printf "-"
				exit
			}
			printf "%.1f%%", (delta / (interval * 1000000000 * vcpus)) * 100
		}')"
	done

	for vm in "${vms[@]}"; do
		machine_status --name "$vm" --cpu "${cpu_usage[$vm]}"
	done
}

function cluster {
	@doc "Create a cluster of virtual machines"
	@arg "default=10.10.120" "--base-ip" "base IP address of the virtual machines"
	@arg "default=3" "--count" "number of virtual machines to create"
	local base_ip count
	@args "$@"
	create_virsh_network --ip "${base_ip}.1" --netmask 255.255.255.0
	for i in $(seq 1 "$count"); do
		ip="${base_ip}.$((i + 1))"
		name="vm${i}"
		install --name "$name" --ip "$ip"
	done
}

ensure_dirs

@main "$@"
