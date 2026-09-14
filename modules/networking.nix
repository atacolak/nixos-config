{ ... }:

{
  networking.networkmanager.enable = true;

  services.tailscale = {
    enable = true;
    openFirewall = true;
  };

  # Pin client+UI to v0.77.1 (nixpkgs 26.11 pin is still 0.76.3).
  # Same derivation as nixpkgs master pkgs/by-name/ne/netbird/package.nix.
  nixpkgs.overlays = [
    (final: prev: {
      netbird = final.callPackage ../pkgs/netbird.nix { };
      netbird-ui = final.callPackage ../pkgs/netbird.nix { componentName = "ui"; };
    })
  ];

  # Client mesh (wt0, UDP 51820).
  # `enable` ≡ clients.default { port = 51820; interface = "wt0"; hardened = false; }
  # netbird-ui wrapper is installed automatically (xserver/GDM is on).
  # Login after switch: `netbird up` (setup key / SSO). Do not put keys in nix.
  services.netbird.enable = true;

  programs.mosh.enable = true;
  services.openssh.enable = true;

  services.udev.extraRules = ''
    SUBSYSTEM=="hidraw", KERNEL=="hidraw*", ATTRS{idVendor}=="1bbb", ATTRS{idProduct}=="af50", TAG+="uaccess", MODE="0660"
    SUBSYSTEM=="usb", ATTR{idVendor}=="0483", ATTR{idProduct}=="df11", TAG+="uaccess", MODE="0660"
  '';
}
