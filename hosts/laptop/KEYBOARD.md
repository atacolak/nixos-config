# this file sits next to `keyboard.nix`

the executable nix is `hosts/laptop/keyboard.nix`. do not "clarify" it. this page is the lived story.

## what i actually press

"how i use caps lock as my prefix key, how i can rapid-press caps twice like double click and that toggles caps for me"

that is not a KDE remap and it is not a Sway `bindsym`. kmonad owns the physical key.

in `keyboard.nix` the layer is literally:

```
(defalias
  capdance (multi-tap 300 lmet caps)
)
```

device: `/dev/input/by-path/platform-i8042-serio-0-event-kbd`

single press / hold → `lmet` (Super/Meta, which Sway calls `$mod` / Mod4).
quick double tap inside 300ms → real Caps Lock.

the idea of "double-tap caps for caps lock, otherwise Super" is something i remember finding on reddit *or* stack overflow. i do not have the thread. do not invent one. the origin stays unverified.

## what is running (observed, not hoped)

on this laptop, 2026-10-30, without touching the unit:

```bash
systemctl --no-pager status kmonad-internal.service
```

observed: `active (running)`, unit name `kmonad-internal.service` (not a user unit named `kmonad`), triggered by `kmonad-internal.path`, device path matching the nix file.

physical P0-K (human at the seat proving single/hold vs double-tap) is still **NOT RUN**. a green systemd unit is not a finger on the key.

## leftover comment, left alone

`keyboard.nix` still says it "works under Wayland/Hyprland". the live daily driver is Sway. i did not tidy that sentence. executable nix stays pristine; this paragraph is the annotation.

## do not "help"

- do not add a KDE Caps remap. that would double-fire with kmonad.
- do not edit dirty `~/nixos-config`.
- do not `nixos-rebuild switch` for a markdown file.
- plasma shortcut module in `home/plasma-observeos/` stays `enable = false` and is not imported.

sha256 of this `keyboard.nix` when this page was written: `160761fc7f347daa7852fec515ad83de83a0d7ff122a9259fb65fd259a617136`
