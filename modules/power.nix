{ ... }:

{
  hardware.enableRedistributableFirmware = true;
  hardware.graphics.enable = true;

  services.fstrim.enable = true;
  services.fwupd.enable = true;
  services.power-profiles-daemon.enable = true;

  zramSwap = {
    enable = true;
    algorithm = "zstd";
    memoryPercent = 50;
  };

  boot.kernel.sysctl = {
    "vm.swappiness" = 100;
    "vm.page-cluster" = 0;
  };
}
