{ pkgs, ... }:

{
  environment.systemPackages = with pkgs; [
    vim
    wget
    git
    curl
    tailscale
    mosh
    tmux
    pciutils
    usbutils
    mullvad
  ];

  programs.firefox.enable = true;
}
