{ pkgs, ... }:

let
  internalBluetoothAddress = "F4:6A:DD:26:38:42";

  disableInternalBluetooth = pkgs.writeShellScript "disable-internal-realtek-bluetooth" ''
    for hci_path in /sys/class/bluetooth/hci*; do
      [ -e "$hci_path/address" ] || continue

      if [ "$(cat "$hci_path/address")" = "${internalBluetoothAddress}" ]; then
        ${pkgs.bluez}/bin/hciconfig "$(basename "$hci_path")" down || true
      fi
    done
  '';
in
{
  # The laptop has a Realtek RTL8821CE wifi/bt combo chip. Its bluetooth side
  # repeatedly failed AirPods A2DP setup while the wifi driver spammed firmware
  # errors. Prefer the USB bluetooth dongle and keep the internal controller down.
  networking.networkmanager.wifi.powersave = false;

  boot.extraModprobeConfig = ''
    options btusb enable_autosuspend=N
  '';

  systemd.services.disable-internal-realtek-bluetooth = {
    description = "Disable flaky internal Realtek bluetooth controller";
    after = [ "bluetooth.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      ${disableInternalBluetooth}
    '';
  };

  powerManagement.resumeCommands = ''
    ${disableInternalBluetooth}
  '';
}
