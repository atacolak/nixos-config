{ pkgs, ... }:

let
  csrDongleAddress = "00:1A:7D:DA:71:13";

  disableCsrDongle = pkgs.writeShellScript "disable-csr-bluetooth-dongle" ''
    for hci_path in /sys/class/bluetooth/hci*; do
      [ -e "$hci_path" ] || continue
      hci_name="$(basename "$hci_path")"

      address=""
      if [ -r "$hci_path/address" ]; then
        address="$(cat "$hci_path/address")"
      else
        address="$(${pkgs.bluez}/bin/hciconfig "$hci_name" 2>/dev/null | ${pkgs.gawk}/bin/awk '/BD Address:/ { print $3; exit }')"
      fi

      if [ "$address" = "${csrDongleAddress}" ]; then
        ${pkgs.bluez}/bin/hciconfig "$hci_name" down || true
      fi
    done
  '';
in
{
  # The CSR USB bluetooth dongle is flaky (constant HCI command timeouts).
  # Keep it disabled and use the internal Realtek RTL8821CE bluetooth instead.
  
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
  # restarting bluetooth can bring the CSR dongle back up while
  # the oneshot below still looks "active (exited)" to systemd.
  systemd.services.bluetooth.postStart = ''
    ${disableCsrDongle}
  '';

  systemd.services.disable-csr-bluetooth-dongle = {
    description = "Disable flaky CSR USB bluetooth dongle";
    after = [ "bluetooth.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      ${disableCsrDongle}
    '';
  };

  powerManagement.resumeCommands = ''
    ${disableCsrDongle}
  '';
}
