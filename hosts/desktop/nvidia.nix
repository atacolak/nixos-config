{ config, ... }:

{
  # proprietary nvidia userspace + nvidia's open kernel module.
  # this is NOT nouveau. Ada (RTX 4070) wants the open kernel module.
  services.xserver.videoDrivers = [ "nvidia" ];

  hardware.graphics = {
    enable = true;
    enable32Bit = true;
  };

  hardware.nvidia = {
    modesetting.enable = true;
    nvidiaSettings = true;
    open = true;
    powerManagement.enable = false;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
  };

  boot.kernelParams = [
    "nvidia_drm.fbdev=1"
  ];
}
