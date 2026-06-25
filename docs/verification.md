# verification cheatsheet

use the smallest verification that proves the change. do not perform theatrical rebuilds for docs-only edits.

## nix evaluation

```bash
cd /home/sf/nixos-config
nix eval --raw .#nixosConfigurations.laptop.config.system.build.toplevel
```

## switch system

```bash
cd /home/sf/nixos-config
sudo nixos-rebuild switch --flake .#laptop
readlink /run/current-system
```

## home-manager as nixos service

```bash
systemctl --no-pager status home-manager-sf.service
systemctl --no-pager is-active home-manager-sf.service
```

check a managed file:

```bash
readlink ~/.config/sway/config
readlink ~/.config/herdr/config.toml
```

## sway

from inside the graphical sway session:

```bash
swaymsg -t get_version
swaymsg -t get_inputs
swaymsg -t get_tree
```

from ssh, find the live socket first:

```bash
find /run/user/1000 -maxdepth 1 -type s -name 'sway-ipc.*.sock'
swaymsg -s /run/user/1000/sway-ipc.*.sock reload
```

## key scripts

```bash
command -v kitty-shade task-terminal audio-toggle audio-input-toggle wmutil i3-spawn-here sway-kill-clean handy
```

## kmonad keyboard

```bash
systemctl --no-pager status kmonad-internal.service
systemctl --no-pager status kmonad-internal.path
journalctl -b -u kmonad-internal.service --no-pager | tail -80
```

## bluetooth and audio

```bash
bluetoothctl list
hciconfig -a
wpctl status
systemctl --no-pager status bluetooth
journalctl -b -u bluetooth --since '10 min ago' --no-pager
```

expected broad shape:

- internal realtek controller is down/disabled
- csr dongle is available
- bluetooth audio devices should appear in `wpctl status` only after bluez/pipewire have a real transport

## herdr

```bash
herdr --version
echo "$HERDR_CONFIG_PATH"
readlink ~/.config/herdr/config.toml
```

## git proof

```bash
git status --short
git diff --stat
git diff --cached --stat
```
