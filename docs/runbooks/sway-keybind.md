# runbook: sway keybind

sway is the primary desktop session. its config is i3-style plain text, managed by home manager.

source:

```text
home/files/sway/config
```

runtime target:

```text
~/.config/sway/config
```

## change a bind

1. edit `home/files/sway/config`.
2. if a helper script is needed, put it in `home/scripts/` and wrap it in `home/sf.nix` with `pkgs.writeShellApplication` or `pkgs.writeScriptBin`.
3. run:

```bash
git add home/files/sway/config home/sf.nix home/scripts/<helper-if-any>
nix eval --raw .#nixosConfigurations.laptop.config.system.build.toplevel
sudo nixos-rebuild switch --flake .#laptop
```

4. from a live sway session, reload or verify:

```bash
swaymsg reload
swaymsg -t get_binding_state
swaymsg -t get_tree
```

from ssh, use the live socket:

```bash
sock=$(find /run/user/1000 -maxdepth 1 -type s -name 'sway-ipc.*.sock' | head -1)
swaymsg -s "$sock" reload
```

## handy shortcut note

handy's built-in tauri shortcut is not a reliable global shortcut under sway. bind handy actions at the compositor layer instead:

```text
bindsym --no-repeat Control+space exec --no-startup-id handy --toggle-transcription
```
