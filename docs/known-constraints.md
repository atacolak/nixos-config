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

AirPods audio is load-bearing and adapter-specific on this laptop.

known controllers:

```text
usb csr dongle (USE FOR AIRPODS):  00:1A:7D:DA:71:13
internal realtek/lite-on (DISABLE): F4:6A:DD:26:38:42
AirPods MAC:                        2C:32:6A:C1:8D:00
```

`modules/bluetooth.nix` intentionally:

- keeps the **CSR USB dongle up** for bluetooth audio
- forces the **internal Realtek controller down**
- runs `bluetoothd -P headset` so HFP cannot race A2DP
- disables btusb autosuspend

Do not invert adapter policy as "cleanup". Docs and code must match.

Working AirPods session requires **all** of:

- bond on CSR with `LinkKey Type` 4 or 7 (not 0)
- ACL `AUTH ENCRYPT` (encryption completed)
- A2DP `MediaTransport1` present
- PipeWire sink visible in `wpctl status`

`Connected: yes` alone is not success. Common false success: ACL up, encryption missing, `avdtp Permission denied (13)`, no sink.

User recovery helper:

```text
airpods-fix           # soft reconnect
airpods-fix --status
airpods-fix --pair    # white-flashing in case, then in-ears when prompted
airpods-fix --reset-bt
```

If bluetooth is changed, verify controller state, bluetoothd flags, encryption/transport, and sink state. Read `docs/runbooks/bluetooth.md` first.

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

exception: vs code `settings.json` and `keybindings.json` are one-time templates — after initial placement, the user owns them and rebuilds do not overwrite (see `docs/decisions.md`).

## vs code

extensions are nix-managed. the extensions directory (`~/.vscode/extensions/`) contains symlinks to nix store paths.

`mutableExtensionsDir` must stay OFF. turning it on causes vs code to ignore `.extensions-immutable.json` and mark all nix-managed extensions as removed.

settings and keybindings are template-managed via `home.activation.placeVscodeTemplates` using `files/vscode/place-templates.sh`. do not use home-manager's `userSettings` or `keybindings` options — they create read-only symlinks that break vs code's ability to persist user changes.

the atacol theme is placed via `home.file` into `~/.vscode/extensions/local.atacol-0.0.1/`.

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
