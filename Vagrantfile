def env_int(name, default)
  value = ENV.fetch(name, "").strip
  value.empty? ? default : Integer(value)
end

machine_count = env_int("MACHINE_COUNT", 1)
vm_cpus = env_int("VM_CPUS", 2)
vm_memory = env_int("VM_MEMORY", 2048)
ip_prefix = ENV.fetch("VAGRANT_IP_PREFIX", "10.10.130")

Vagrant.configure("2") do |config|
  config.vm.box = "bento/ubuntu-24.04"

  # Avoid synced-folder complexity while testing installs.
  config.vm.synced_folder ".", "/vagrant", disabled: true

  (1..machine_count).each do |index|
    vm_name = format("vm%02d", index)
    vm_ip = "#{ip_prefix}.#{100 + index}"

    config.vm.define vm_name do |machine|
      machine.vm.hostname = vm_name
      machine.vm.network "private_network", ip: vm_ip

      machine.vm.provider "qemu" do |qe|
        qe.name = vm_name
        qe.memory = vm_memory.to_s
        qe.smp = vm_cpus.to_s
        qe.ssh_auto_correct = true
      end

      machine.vm.provision "shell", inline: <<~SHELL
        set -eu
        export DEBIAN_FRONTEND=noninteractive
        echo 'kexec-tools kexec-tools/load_kexec boolean false' | debconf-set-selections
        apt-get update
        apt-get install -y kexec-tools
      SHELL
    end
  end
end
