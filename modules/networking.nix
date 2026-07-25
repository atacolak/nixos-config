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
  SUBSYSTEM=="hidraw", KERNEL=="hidraw*", ATTRS{idVendor}=="1bbb", ATTRS{idProduct}=="af50", TAG+="uaccess", MODE="0660"
  SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="df11", TAG+="uaccess", MODE="0660"
'';
}

