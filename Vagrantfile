require "fileutils"

def env_int(name, default)
  value = ENV.fetch(name, "").strip
  value.empty? ? default : Integer(value)
end

machine_count = env_int("MACHINE_COUNT", 1)
vm_cpus = env_int("VM_CPUS", 2)
vm_memory = env_int("VM_MEMORY", 2048)
ip_prefix = ENV.fetch("VAGRANT_IP_PREFIX", "10.10.130")
ssh_port_base = env_int("VAGRANT_SSH_PORT_BASE", 50021)

ssh_dir = File.expand_path(".vagrant/ssh", __dir__)
shared_private_key = File.join(ssh_dir, "nixlab_dev_key")
shared_public_key = "#{shared_private_key}.pub"

unless File.exist?(shared_private_key)
  # This uses a shared private key for all VMs for easy SSH access.
  # This is in no way a secure key, and should only be used for local development.
  FileUtils.mkdir_p(ssh_dir)

  system(
    "ssh-keygen",
    "-t", "ed25519",
    "-N", "",
    "-C", "nixlab-vagrant-local-dev",
    "-f", shared_private_key
  ) || raise("failed to generate shared Vagrant SSH key")

  File.chmod(0o600, shared_private_key)
end

shared_public_key_content = File.read(shared_public_key).strip

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"

  # Use the generated repo-local key for every VM. Keep the box's default
  # insecure key as a fallback so first-time provisioning can install our key.
  config.ssh.insert_key = false
  config.ssh.private_key_path = [
    shared_private_key,
    File.expand_path("~/.vagrant.d/insecure_private_key")
  ]

  # Avoid synced-folder complexity while testing installs.
  config.vm.synced_folder ".", "/vagrant", disabled: true

  (1..machine_count).each do |index|
    vm_name = format("vm%02d", index)
    vm_ip = "#{ip_prefix}.#{100 + index}"
    ssh_host_port = ssh_port_base + index

    config.vm.define vm_name do |machine|
      machine.vm.hostname = vm_name

      machine.vm.provider "qemu" do |qe|
        qe.name = vm_name
        qe.memory = vm_memory.to_s
        qe.smp = vm_cpus.to_s
        qe.ssh_port = ssh_host_port.to_s
        qe.ssh_auto_correct = true
        qe.extra_netdev_args = "net=#{ip_prefix}.0/24,dhcpstart=#{vm_ip}"
      end

      machine.vm.provision "shell", inline: <<~SHELL
        set -eu
        export DEBIAN_FRONTEND=noninteractive

        install -d -m 700 -o vagrant -g vagrant /home/vagrant/.ssh
        printf '%s\n' '#{shared_public_key_content}' > /home/vagrant/.ssh/authorized_keys
        chown vagrant:vagrant /home/vagrant/.ssh/authorized_keys
        chmod 600 /home/vagrant/.ssh/authorized_keys

        echo 'kexec-tools kexec-tools/load_kexec boolean false' | debconf-set-selections
        apt-get install -y kexec-tools
      SHELL
    end
  end
end
