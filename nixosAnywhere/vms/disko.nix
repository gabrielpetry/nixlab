{
  lib,
  ...
}:
{
  boot.loader.grub = {
    enable = true;
  };

  boot.initrd.availableKernelModules = [
    "ata_piix"
    "sd_mod"
    "sr_mod"
    "virtio_blk"
    "virtio_pci"
  ];

  disko.devices = {
    disk.vda = {
      type = "disk";
      device = lib.mkDefault "/dev/vda";
      content = {
        type = "gpt";
        partitions = {
          MBR = {
            type = "EF02";
            size = "1M";
            priority = 1;
          };

          home = {
            size = "20G";
            priority = 2;
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/home";
            };
          };

          root = {
            size = "100%";
            priority = 3;
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/";
            };
          };
        };
      };
    };
  };
}
