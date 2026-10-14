{ ... }:

{
  imports = [
    ./desktop.nix
    ./flatpak.nix
    ./herdr.nix
    ./locale.nix
    ./networking.nix
    ./nix.nix
    ./packages.nix
    ./power.nix
    ./user.nix
    ./vpn-netns.nix
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;
}
