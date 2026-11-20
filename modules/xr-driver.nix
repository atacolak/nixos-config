{
  pkgs,
  lib,
  ...
}:

let
  xrDriver = pkgs.callPackage ../pkgs/xr-driver.nix { };
  sdkLibPath = lib.makeLibraryPath [
    pkgs.stdenv.cc.cc
    pkgs.systemd
    pkgs.libusb1
  ];
in
{
  boot.kernelModules = [ "uinput" ];

  services.udev.packages = [ xrDriver ];

  systemd.user.services.xr-driver = {
    description = "XR glasses user-space driver";
    partOf = [ "plasma-workspace-wayland.target" ];
    after = [ "plasma-workspace-wayland.target" ];
    wantedBy = [ "plasma-workspace-wayland.target" ];
    environment.LD_LIBRARY_PATH = "${xrDriver}/lib/xr-driver/x86_64:${xrDriver}/lib/xr-driver/x86_64/viture:${sdkLibPath}";
    serviceConfig = {
      Type = "simple";
      ExecStart = "${xrDriver}/bin/xrDriver";
      Restart = "on-failure";
      RestartSec = 2;
    };
  };
}
