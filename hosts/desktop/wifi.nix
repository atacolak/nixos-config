{ ... }:

{
  # USB wifi: TP-Link/Techkey RTL88x2bu (0bda:b812), in-tree rtw88_8822bu.
  # firmware comes from hardware.enableRedistributableFirmware in modules/power.nix.
  # no extra driver USB. the live iso's kernel already has rtw88.

  # SSID is not a secret. the PSK is. $WIFI_PSK is interpolated from a
  # root-only env file that MUST NOT live in this repo or the nix store.
  #
  # create before first boot / nixos-install:
  #   sudo install -d -m 700 /mnt/etc/nixos
  #   printf 'WIFI_PSK=%s\n' 'the-psk' | sudo tee /mnt/etc/nixos/wifi.env
  #   sudo chmod 600 /mnt/etc/nixos/wifi.env
  networking.networkmanager.ensureProfiles.environmentFiles = [
    "/etc/nixos/wifi.env"
  ];

  networking.networkmanager.ensureProfiles.profiles.skynet = {
    connection = {
      id = "Skynet";
      type = "wifi";
      autoconnect = "true";
    };
    wifi = {
      ssid = "Skynet ⭐";
      mode = "infrastructure";
    };
    wifi-security = {
      auth-alg = "open";
      key-mgmt = "wpa-psk";
      psk = "$WIFI_PSK";
    };
    ipv4.method = "auto";
    ipv6.method = "auto";
  };
}
