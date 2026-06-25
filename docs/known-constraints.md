# known constraints

these are facts future agents should preserve unless explicitly asked to retest them.

## host and user

- host config target: `.#nixosConfigurations.laptop`
- machine hostname: `sfnix`
- normal user: `sf`
- home-manager is integrated as a nixos module, not run as a separate standalone flake.

## flakes see tracked files only

if a nix expression imports or reads a new file, that file must be tracked by git before `nix eval` can see it.

usually:

```bash
git add path/to/new-file
nix eval --raw .#nixosConfigurations.laptop.config.system.build.toplevel
```

if eval says a path is not tracked, do not debug nixpkgs. add the file.

## bluetooth hardware

internal realtek bluetooth/wifi is unreliable for airpods on this laptop.
observed failure mode: pairing/connecting may partly work, but a2dp transport fails or no pipewire sink appears.

known controllers:

```text
internal realtek/lite-on: F4:6A:DD:26:38:42
usb csr dongle:          00:1A:7D:DA:71:13
```

`modules/bluetooth.nix` intentionally disables the internal controller and lets the csr dongle handle bluetooth audio.

if bluetooth is changed, verify controller state and audio sink state. do not remove the workaround as "cleanup".

## sway

sway is the primary desktop session. the previous wayland compositor was removed from the active configuration and stale compositor-specific files should not be reintroduced as "cleanup".

managed source:

```text
home/files/sway/config
```

runtime target:

```text
~/.config/sway/config
```

home-manager owns the runtime file.

## keyboard

caps lock behavior is managed by kmonad in `modules/keyboard.nix`.

intended behavior:

- single/hold caps emits super/meta
- fast double-tap caps emits caps lock

fn-row media keys are handled in sway as `XF86...` keysyms.

## user config ownership

home-manager owns important files under `~/.config`, including sway, kitty, fuzzel, swaync, gtk, mimeapps, i3status-rust, and herdr config.

manual ui edits may work temporarily, but they are not durable until represented in this repo.

## herdr

package:

```text
pkgs/herdr.nix
```

system install:

```text
modules/herdr.nix
```

user config:

```text
home/sf.nix
```

runtime logs, sockets, and session files under `~/.config/herdr/` are state, not source.
