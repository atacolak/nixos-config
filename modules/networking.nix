{ ... }:

{
  networking.networkmanager.enable = true;

  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  programs.mosh.enable = true;
  services.openssh.enable = true;
  
  services.udev.extraRules = ''
  KERNEL=="hidraw*", SUBSYSTEM=="hidraw", ATTRS{idVendor}=="1bbb", ATTRS{idProduct}=="af3c", MODE="0660", TAG+="uaccess"
'';

}

