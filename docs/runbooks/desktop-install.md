# runbook: install nixos on sfub (kingston ssd)

two disks in this chassis:

```text
samsung nvme  954g  ubuntu   /dev/disk/by-id/nvme-SAMSUNG_MZVLQ1T0HBLB-00B00_S6F7NJ0R446229
kingston sata 224g  EMPTY    /dev/disk/by-id/ata-KINGSTON_SA400S37240G_50026B7785D7AA0E
```

nixos goes on the kingston. ubuntu stays on the samsung until we deliberately eat it later.
NEVER format, resize, or install a bootloader onto the samsung in this runbook.

the picker between ubuntu and nixos is the firmware boot menu (F12 / boot override), not dual-boot on one disk.

## wifi

the live path is a usb dongle: realtek RTL88x2bu (`0bda:b812`), driver `rtw88_8822bu`.
nixos-unstable's kernel already has it. no driver USB. no optical drive.

SSID is declared in `hosts/desktop/wifi.nix`. the PSK is NOT.
write it onto the target root before first boot (see below). do not commit it.

ethernet `enp5s0` exists but is down. ignore it.

## from a nixos usb

the pny already has `nixos-minimal-26.11`. boot it (firmware menu → usb).
leave the rtw88 dongle in. as root:

```bash
mkdir -p /mnt-ubuntu
mount -o ro /dev/disk/by-id/nvme-SAMSUNG_MZVLQ1T0HBLB-00B00_S6F7NJ0R446229-part1 /mnt-ubuntu
INSTALL_DESKTOP=yes bash /mnt-ubuntu/home/sf/nixos-config/scripts/install-desktop.sh
```

that script:

- refuses to run without `INSTALL_DESKTOP=yes`
- refuses if `/` is the samsung (you are still on ubuntu) or the pny got picked as kingston
- checks the target is the 224g kingston by-id
- `nmtui` if the live session has no net
- prompts for the skynet psk (or take `WIFI_PSK`)
- partitions **only** the kingston (1g esp + rest ext4)
- copies `~/nixos-config` off ubuntu read-only
- `nixos-install --flake …#desktop`
- `passwd sf` (or `SF_PASSWORD`)

optional: `COPY_OVERLAY=yes` copies `/var/lib/netbird` and `/var/lib/tailscale` so the overlay ips stay.

then firmware boot menu → kingston. not the pny, not ubuntu.


## from ubuntu with nix (optional later)

installing the nix package manager on ubuntu lets you:

- `nix eval` / `nix build .#nixosConfigurations.desktop.config.system.build.toplevel`
  proves the flake evaluates and the closure builds (kernel, nvidia, sway).
- it does NOT prove gdm+nvidia on real hardware, the rtw88 dongle after reboot, or netbird.
- `nixos-rebuild build-vm --flake .#desktop` is a qemu lie. no 4070, no dongle.
- `nixos-install --flake .#desktop --root /mnt` after mounting the kingston is a real install without rebooting ubuntu, provided the bootloader is written to the kingston ESP only.

do not `nixos-rebuild switch --flake .#desktop` while ubuntu is the running system.

## after it boots

- `hostname` is `sfub`. flake attr is `desktop`. `nixrebuild` maps that.
- `nmtui` only if `/etc/nixos/wifi.env` was wrong.
- set a password for gdm (`passwd`). ssh key is already in `modules/user.nix`.
- kmonad for the keychron is NOT in this host yet (bluetooth device path is unstable). caps-as-super is a follow-up.
- do not copy `hosts/laptop/bluetooth.nix` here.
