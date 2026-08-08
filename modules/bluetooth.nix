{ pkgs, ... }:

let
  # USB CSR dongle — used for AirPods A2DP (and other BT audio when it works).
  csrDongleAddress = "00:1A:7D:DA:71:13";

  # Internal Lite-On / Realtek RTL8821CE — unreliable for AirPods on this laptop.
  # Observed: ACL connects, auth looks OK, encryption never completes, A2DP dies
  # with Permission denied / no MediaTransport; adapter also goes "deaf" after
  # power cycles and needs USB reset.
  realtekAddress = "F4:6A:DD:26:38:42";

  # Keep ONLY the CSR adapter up. Bonds are per-controller; AirPods must be
  # paired on CSR (see docs/runbooks/bluetooth.md).
  preferCsrDisableRealtek = pkgs.writeShellScript "prefer-csr-disable-realtek-bt" ''
    set -euo pipefail
    for hci_path in /sys/class/bluetooth/hci*; do
      [ -e "$hci_path" ] || continue
      hci_name="$(basename "$hci_path")"

      address=""
      if [ -r "$hci_path/address" ]; then
        address="$(cat "$hci_path/address")"
      else
        address="$(${pkgs.bluez}/bin/hciconfig "$hci_name" 2>/dev/null | ${pkgs.gawk}/bin/awk '/BD Address:/ { print $3; exit }')"
      fi

      case "$address" in
        ${realtekAddress})
          ${pkgs.bluez}/bin/hciconfig "$hci_name" down || true
          ;;
        ${csrDongleAddress})
          ${pkgs.bluez}/bin/hciconfig "$hci_name" up || true
          ;;
      esac
    done
  '';
in
{
  # AirPods path on sfnix:
  #   CSR USB dongle (00:1A:7D:DA:71:13) = audio
  #   internal Realtek (F4:6A:DD:26:38:42) = forced down
  #   bluetoothd -P headset = no HFP race against A2DP
  #
  # Do not "clean up" these without reading docs/runbooks/bluetooth.md and
  # docs/known-constraints.md. Wrong adapter + HFP race is why audio dies
  # while bluetoothctl still says Connected: yes.

  networking.networkmanager.wifi.powersave = false;

  hardware.bluetooth = {
    enable = true;
    powerOnBoot = true;

    settings = {
      General = {
        # dual = BR/EDR + LE (AirPods need both at times)
        ControllerMode = "dual";
        MultiProfile = "multiple";
        FastConnectable = true;
        Experimental = true;
        # Helps re-bonding flaky Apple devices without interactive PIN.
        JustWorksRepairing = "always";
        # Realtek path was worse with SC forced; keep off globally for this host.
        SecureConnections = "false";
        Privacy = "off";
      };
      Policy.AutoEnable = true;
    };
  };

  environment.systemPackages = with pkgs; [
    bluez
    bluez-tools
  ];

  # USB BT autosuspend wedges both adapters under load.
  boot.extraModprobeConfig = ''
    options btusb enable_autosuspend=N
  '';

  # Disable BlueZ headset/HFP plugin so it cannot race A2DP on AirPods.
  # Symptom: avdtp_connect_cb() Permission denied (13) while HFP also tries
  # (and fails) on the same ACL link.
  #
  # Tradeoff: DJI Mic Mini advertises Handsfree and may need HFP to capture.
  # That is a separate problem — do not re-enable headset casually to "fix mic"
  # or AirPods will regress. See docs/runbooks/bluetooth.md.
  systemd.services.bluetooth.serviceConfig.ExecStart = [
    ""
    "${pkgs.bluez}/libexec/bluetooth/bluetoothd -f /etc/bluetooth/main.conf -P headset"
  ];

  # Re-assert adapter policy whenever bluetoothd starts. Without this, a
  # restart can leave Realtek as default and CSR down.
  systemd.services.bluetooth.postStart = ''
    ${preferCsrDisableRealtek}
  '';

  systemd.services.prefer-csr-bluetooth = {
    description = "Prefer CSR USB bluetooth dongle; disable internal Realtek";
    after = [ "bluetooth.service" ];
    wantedBy = [ "multi-user.target" ];

    serviceConfig = {
      Type = "oneshot";
      RemainAfterExit = true;
    };

    script = ''
      ${preferCsrDisableRealtek}
    '';
  };

  powerManagement.resumeCommands = ''
    ${preferCsrDisableRealtek}
  '';
}
