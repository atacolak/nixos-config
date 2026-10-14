# Hardware scan for sfub (Gigabyte B550M DS3H AC R2, Ryzen 5 5600).
# Filesystems target the unused Kingston SATA SSD, NEVER the Samsung NVMe
# ubuntu currently lives on. by-id so /dev/sda cannot silently become the
# wrong disk. partition layout is in docs/runbooks/desktop-install.md.
{ config, lib, modulesPath, ... }:

{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
  ];

  boot.initrd.availableKernelModules = [
    "nvme"
    "xhci_pci"
    "ahci"
    "usb_storage"
    "sd_mod"
    "usbhid"
    "r8169"
  ];
  boot.initrd.kernelModules = [ ];
  boot.kernelModules = [
    "kvm-amd"
    "rtw88_8822bu"
  ];
  boot.extraModulePackages = [ ];

  fileSystems."/" = {
    device = "/dev/disk/by-id/ata-KINGSTON_SA400S37240G_50026B7785D7AA0E-part2";
    fsType = "ext4";
  };

  fileSystems."/boot" = {
    device = "/dev/disk/by-id/ata-KINGSTON_SA400S37240G_50026B7785D7AA0E-part1";
    fsType = "vfat";
    options = [
      "fmask=0077"
      "dmask=0077"
    ];
  };

  nixpkgs.hostPlatform = lib.mkDefault "x86_64-linux";
  hardware.cpu.amd.updateMicrocode = lib.mkDefault config.hardware.enableRedistributableFirmware;
}
