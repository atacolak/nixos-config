{ ... }:

{
  # Hibernation: resume from the on-disk swap partition.
  # zram has higher priority (5 vs -2), so runtime swap stays on zram;
  # the kernel only touches the disk swap when writing the hibernation image.
  boot.resumeDevice = "/dev/disk/by-uuid/6b1723b3-6e0e-4cc3-adf3-75fc63c8f1c1";
  boot.kernelParams = [ "resume=UUID=6b1723b3-6e0e-4cc3-adf3-75fc63c8f1c1" ];

  services.logind.settings.Login = {
    HandleLidSwitch = "suspend";
    HandleLidSwitchExternalPower = "ignore";
  };
}
