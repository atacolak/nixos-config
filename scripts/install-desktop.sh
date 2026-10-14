#!/usr/bin/env bash
# install-desktop.sh — live-iso installer for sfub onto the unused Kingston SSD.
#
# from the nixos usb, as root:
#   mkdir -p /mnt-ubuntu
#   mount -o ro /dev/disk/by-id/nvme-SAMSUNG_MZVLQ1T0HBLB-00B00_S6F7NJ0R446229-part1 /mnt-ubuntu
#   INSTALL_DESKTOP=yes bash /mnt-ubuntu/home/sf/nixos-config/scripts/install-desktop.sh
#
# required: INSTALL_DESKTOP=yes
# optional: WIFI_PSK=...  SF_PASSWORD=...  COPY_OVERLAY=yes
# never formats the samsung. never writes the pny. never runs under ubuntu.

set -euo pipefail

KINGSTON_ID="ata-KINGSTON_SA400S37240G_50026B7785D7AA0E"
SAMSUNG_ID="nvme-SAMSUNG_MZVLQ1T0HBLB-00B00_S6F7NJ0R446229"
PNY_ID="usb-PNY_USB_3.2.1_FD_071C43EE28F29440-0:0"

die() { echo "!! $*" >&2; exit 1; }

[[ "$(id -u)" -eq 0 ]] || die "must run as root on the live iso"

[[ "${INSTALL_DESKTOP:-}" == "yes" ]] || die "refusing. set INSTALL_DESKTOP=yes (this eats the kingston)"

# ubuntu root is ext4 on the samsung. the live iso is tmpfs. if / is the samsung, stop.
root_src="$(findmnt -n -o SOURCE / || true)"
root_src_id="$(readlink -f "$root_src" 2>/dev/null || echo "$root_src")"
samsung="$(readlink -f "/dev/disk/by-id/${SAMSUNG_ID}" 2>/dev/null || true)"
kingston="$(readlink -f "/dev/disk/by-id/${KINGSTON_ID}" 2>/dev/null || true)"
pny="$(readlink -f "/dev/disk/by-id/${PNY_ID}" 2>/dev/null || true)"

[[ -n "$kingston" ]] || die "kingston by-id missing. wrong machine?"
[[ -n "$samsung" ]] || die "samsung by-id missing. refusing to guess disks"

case "$root_src_id" in
  "$samsung"|"${samsung}p1"|"${samsung}p2") die "running on ubuntu (samsung). this script is live-iso only" ;;
  "$kingston"|"${kingston}p1"|"${kingston}p2") die "already booted from kingston?" ;;
esac

if [[ -n "$pny" && "$kingston" == "$pny" ]]; then
  die "kingston by-id resolved to the pny stick. abort"
fi

k_model="$(lsblk -dno MODEL "$kingston" | tr -d '[:space:]')"
k_size="$(lsblk -dnb -o SIZE "$kingston")"
[[ "$k_model" == *KINGSTON* ]] || die "target model is '$k_model', expected KINGSTON"
# 200–250 GiB. the stick is 29g, the samsung is 954g.
[[ "$k_size" -ge 200000000000 && "$k_size" -le 250000000000 ]] || die "kingston size $k_size is not the 224g ssd"

if findmnt "$kingston" >/dev/null 2>&1 || findmnt "${kingston}1" >/dev/null 2>&1 || findmnt "${kingston}2" >/dev/null 2>&1; then
  die "kingston is mounted. unmount it first"
fi

echo ">> target $kingston  model=$k_model  bytes=$k_size"
echo ">> ubuntu $samsung  (read-only source, never formatted)"
lsblk -o NAME,SIZE,MODEL,SERIAL,TRAN,MOUNTPOINTS "$kingston" "$samsung"

# live session network: nixos-install needs cache.nixos.org
if ! ping -c 1 -W 3 1.1.1.1 >/dev/null 2>&1; then
  echo "!! no network. start nmtui, join Skynet, re-run."
  command -v nmtui >/dev/null && nmtui
  ping -c 1 -W 3 1.1.1.1 >/dev/null 2>&1 || die "still no network"
fi

if [[ -z "${WIFI_PSK:-}" ]]; then
  printf 'wifi psk for Skynet (not stored in git): '
  stty -echo
  IFS= read -r WIFI_PSK
  stty echo
  echo
  [[ -n "$WIFI_PSK" ]] || die "empty psk"
fi

ubuntu_mnt="/mnt-ubuntu"
if ! findmnt "$ubuntu_mnt" >/dev/null 2>&1; then
  mkdir -p "$ubuntu_mnt"
  mount -o ro "${samsung}p1" "$ubuntu_mnt"
fi
[[ -f "$ubuntu_mnt/home/sf/nixos-config/flake.nix" ]] \
  || die "flake not at $ubuntu_mnt/home/sf/nixos-config"

echo ">> partitioning kingston (esp 1g + ext4 rest)"
wipefs -a "$kingston"
sgdisk --zap-all "$kingston"
sgdisk -n1:0:+1G -t1:EF00 -c1:ESP "$kingston"
sgdisk -n2:0:0 -t2:8300 -c2:root "$kingston"
udevadm settle || true
partprobe "$kingston" || true
sleep 1
esp="${kingston}-part1"
rootp="${kingston}-part2"
if [[ ! -b "$esp" ]]; then
  esp="${kingston}1"
  rootp="${kingston}2"
fi
# prefer by-id partitions matching hardware-configuration.nix
if [[ -b "/dev/disk/by-id/${KINGSTON_ID}-part1" ]]; then
  esp="/dev/disk/by-id/${KINGSTON_ID}-part1"
  rootp="/dev/disk/by-id/${KINGSTON_ID}-part2"
fi
[[ -b "$esp" && -b "$rootp" ]] || die "partitions did not appear (esp=$esp root=$rootp)"

mkfs.vfat -F32 -n ESP "$esp"
mkfs.ext4 -F -L nixos "$rootp"

mount "$rootp" /mnt
mkdir -p /mnt/boot
mount "$esp" /mnt/boot

echo ">> copying flake from ubuntu"
mkdir -p /mnt/home/sf
cp -a "$ubuntu_mnt/home/sf/nixos-config" /mnt/home/sf/nixos-config
chown -R 1000:1000 /mnt/home/sf 2>/dev/null || true

install -d -m 700 /mnt/etc/nixos
printf 'WIFI_PSK=%s\n' "$WIFI_PSK" > /mnt/etc/nixos/wifi.env
chmod 600 /mnt/etc/nixos/wifi.env
unset WIFI_PSK

if [[ "${COPY_OVERLAY:-}" == "yes" ]]; then
  echo ">> copying netbird/tailscale node keys from ubuntu"
  if [[ -d "$ubuntu_mnt/var/lib/netbird" ]]; then
    mkdir -p /mnt/var/lib
    cp -a "$ubuntu_mnt/var/lib/netbird" /mnt/var/lib/netbird
  fi
  if [[ -d "$ubuntu_mnt/var/lib/tailscale" ]]; then
    mkdir -p /mnt/var/lib
    cp -a "$ubuntu_mnt/var/lib/tailscale" /mnt/var/lib/tailscale
  fi
fi

echo ">> nixos-install #desktop"
nixos-install --no-root-passwd --flake /mnt/home/sf/nixos-config#desktop

if [[ -n "${SF_PASSWORD:-}" ]]; then
  echo "sf:${SF_PASSWORD}" | nixos-enter --root /mnt -- chpasswd
  unset SF_PASSWORD
else
  echo ">> set password for sf (gdm)"
  nixos-enter --root /mnt -- passwd sf
fi

umount -R /mnt
echo ">> done. firmware boot menu → kingston. not the pny, not ubuntu."
echo ">> first boot: netbird up  (unless COPY_OVERLAY=yes kept the keys)"
