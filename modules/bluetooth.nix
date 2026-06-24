{ pkgs, ... }:

let
  internalBluetoothAddress = "F4:6A:DD:26:38:42";

  disableInternalBluetooth = pkgs.writeShellScript "disable-internal-realtek-bluetooth" ''
    for hci_path in /sys/class/bluetooth/hci*; do
      [ -e "$hci_path" ] || continue
      hci_name="$(basename "$hci_path")"

      address=""
      if [ -r "$hci_path/address" ]; then
        address="$(cat "$hci_path/address")"
      else
        address="$(${pkgs.bluez}/bin/hciconfig "$hci_name" 2>/dev/null | ${pkgs.gawk}/bin/awk '/BD Address:/ { print $3; exit }')"
      fi

      if [ "$address" = "${internalBluetoothAddress}" ]; then
        ${pkgs.bluez}/bin/hciconfig "$hci_name" down || true
      fi
    done
  '';
in
{
  # The laptop has a Realtek RTL8821CE wifi/bt combo chip. Its bluetooth side
  # repeatedly failed AirPods A2DP setup while the wifi driver spammed firmware
  # errors. Prefer the USB bluetooth dongle and keep the internal controller down.
  networking.networkmanager.wifi.powersave = false;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;

    settings.Policy.AutoEnable = true;
  };

  environment.systemPackages = [ pkgs.bluez ];

  boot.extraModprobeConfig = ''
    options btusb enable_autosuspend=N
  '';

  # Also run the disable hook whenever BlueZ starts or restarts. Without this,
  # restarting bluetooth can bring the internal Realtek controller back up while
  # the oneshot below still looks "active (exited)" to systemd.
  systemd.services.bluetooth.postStart = ''
    ${disableInternalBluetooth}
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
