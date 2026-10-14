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

## from a nixos usb (recommended)

1. flash a current nixos unstable iso. boot it. do not mount the samsung except read-only if you need files.
2. plug the wifi dongle. `nmtui` once to get the installer on the network. this is only for the live session.
3. partition the kingston, by-id only:

```bash
DISK=/dev/disk/by-id/ata-KINGSTON_SA400S37240G_50026B7785D7AA0E
# confirm this is 224g and has no mounted filesystems. abort if not.
lsblk -o NAME,SIZE,MODEL,MOUNTPOINTS "$DISK"

wipefs -a "$DISK"
sgdisk --zap-all "$DISK"
sgdisk -n1:0:+1G -t1:EF00 -c1:ESP "$DISK"
sgdisk -n2:0:0 -t2:8300 -c2:root "$DISK"

mkfs.vfat -F32 -n ESP "$DISK-part1"
mkfs.ext4 -L nixos "$DISK-part2"

mount "$DISK-part2" /mnt
mkdir -p /mnt/boot
mount "$DISK-part1" /mnt/boot
```

4. clone this flake onto the target (or copy from ubuntu if it is still up):

```bash
nix-shell -p git --run 'git clone https://github.com/atacolak/nixos-config /mnt/home/sf/nixos-config'
# private repo: use git@github.com:atacolak/nixos-config.git with a deploy key / forwarded agent
```

5. wifi psk onto the target, never into git:

```bash
install -d -m 700 /mnt/etc/nixos
printf 'WIFI_PSK=%s\n' 'the-psk' > /mnt/etc/nixos/wifi.env
chmod 600 /mnt/etc/nixos/wifi.env
```

6. install:

```bash
nixos-install --flake /mnt/home/sf/nixos-config#desktop
nixos-enter --root /mnt -c 'passwd sf'
```

7. reboot. firmware boot menu → kingston. ubuntu on the samsung is untouched.
8. `netbird up` (setup key / sso). do not put the key in nix. same for `tailscale up` if the node key was not preserved.

to keep the existing netbird ip `10.77.67.147`, copy `/var/lib/netbird` from ubuntu onto the kingston before first `netbird up`. same story for `/var/lib/tailscale` and `100.65.21.105`.

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
