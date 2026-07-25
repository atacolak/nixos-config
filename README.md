# sfnix config

this repo is the recipe for my laptop.

nixos uses these files to build the operating system.
home manager uses these files to build my user settings.

future agents can inspect this repo, change it, rebuild the machine, verify the result, and commit the change.

if something is configured here, it should survive reboots and rebuilds.
if something is changed by clicking around in the ui, it is probably temporary until it is moved here.

rough split:

- `hosts/` says what machine this is
- `modules/` says how the system behaves
- `home/` says how my user environment behaves
- `pkgs/` contains local packages
- `docs/` contains short runbooks and known constraints so agents do not rediscover context
- `AGENTS.md` tells agents how to edit this without being dumb

this repo should stay boring.
boring means recoverable.

## daily use

**rebuild**: `sudo nixos-rebuild switch --flake /home/sf/nixos-config#laptop`

**add a vs code extension**: edit `home/sf.nix` → rebuild → restart vs code.

**change vs code settings**: just do it in vs code. templates are placed once, then you own them.

for bluetooth management, use `bluetui`.
to manage wifi, use `nmtui`.
## commands

`rhtml` — serve a remote html file over tailscale. `rhtml host:path` or `rhtml path` (uses default host). `rhtml --stop` to kill the server.

`clip-push` — copy sfnix clipboard to ata-ubuntu. `clip-pull` — copy ata-ubuntu clipboard to sfnix.

`mullvad-sg` — launch mullvad-browser through Singapore WireGuard tunnel. only that browser sees the vpn; tailscale/firefox/everything else stays on normal connection. needs `sudo systemctl start vpn-netns` once after boot.

`nwg-displays` — gui for managing sway outputs (position, resolution, enable/disable). for ar glasses or second screen.

`calibre` — ebook library manager. `ebook-viewer` for quick reading. oled: preferences → dark mode + margin controls.

`fuzzel` — app launcher. `$mod+space`. pinned to laptop screen only (won't open on glasses).

`bluetui` — bluetooth. `nmtui` — wifi.

## env

`PI_OFFLINE=1` is set in sessionVariables.

## rebuild

`sudo nixos-rebuild switch --flake ~/nixos-config#laptop`
