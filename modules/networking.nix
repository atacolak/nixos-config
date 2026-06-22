{ ... }:

{
  networking.networkmanager.enable = true;

  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  programs.mosh.enable = true;
  services.openssh.enable = true;
}
