{ ... }:

{
  imports = [
    ./hardware-configuration.nix
    ./bluetooth.nix
    ./keyboard.nix
    ./lid.nix
    ../../modules/common.nix
  ];

  networking.hostName = "sfnix";

  system.stateVersion = "26.05";
}
