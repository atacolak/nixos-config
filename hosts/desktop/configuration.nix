{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./bluetooth.nix
    ./nvidia.nix
    ./wifi.nix
    ../../modules/common.nix
  ];

  networking.hostName = "sfub";

  # firmware boot menu is the ubuntu-vs-nixos picker (two disks, two ESPs).
  # this timeout only affects generations on the kingston ESP.
  boot.loader.timeout = 8;

  system.stateVersion = "26.05";
}
