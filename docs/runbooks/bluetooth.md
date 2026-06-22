# runbook: bluetooth

read `docs/known-constraints.md` first.

## current intended state

internal realtek controller is disabled because airpods failed on it.
usb csr dongle is used for bluetooth audio.

known addresses:

```text
internal realtek/lite-on: F4:6A:DD:26:38:42
usb csr dongle:          00:1A:7D:DA:71:13
```

owned by:

```text
modules/bluetooth.nix
```

## safe inspection

```bash
bluetoothctl list
hciconfig -a
wpctl status
systemctl --no-pager status bluetooth
journalctl -b -u bluetooth --since '10 min ago' --no-pager
```

## before changing bluetooth config

confirm whether the user wants:

- normal maintenance of the csr dongle path
- retesting the internal realtek controller
- adding support for another dongle/device

these are different tasks. do not conflate them.

## after changing bluetooth config

```bash
nix eval --raw .#nixosConfigurations.laptop.config.system.build.toplevel
sudo nixos-rebuild switch --flake .#laptop
bluetoothctl list
hciconfig -a
wpctl status
journalctl -b -u bluetooth --since '10 min ago' --no-pager
```

if airpods connect but no sink appears in `wpctl status`, pipewire does not have a usable bluetooth audio transport yet. do not debug output selection before proving the sink exists.
