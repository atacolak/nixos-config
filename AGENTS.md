# agents guide for this nixos configuration

this repo is the declarative source of truth for two machines:
`sfnix` (flake attr `laptop`) and `sfub` (flake attr `desktop`).
edit nix files here; do not hand-edit generated files in `/etc`, `/run/current-system`, or `/nix/store`.

this file is the entrypoint for agents. read it first, then read the relevant runbook under `docs/runbooks/` before changing anything nontrivial.

## topology / entrypoints

start here:

- `README.md`
  - human-facing why-this-exists plaque. short by design.

- `AGENTS.md`
  - agent contract, repo topology, invariants, and traps.

- `docs/known-constraints.md`
  - facts that should not be rediscovered or casually "cleaned up".

- `docs/verification.md`
  - command matrix for proving specific classes of changes.

- `docs/rollback.md`
  - recovery commands when a switch breaks something.

- `docs/runbooks/*.md`
  - recipes for common edits. use these to make minimal changes without archaeology.

config entrypoints:

- `flake.nix`
  - pins inputs and wires both hosts through `mkNixos`.
  - keep this boring. add inputs only when there is a real consumer.

- `hosts/laptop/` and `hosts/desktop/`
  - host identity and hardware. this directory should answer: "what is this machine?"
  - hostname, hardware scan, and host-only modules live here.
  - laptop-only: `bluetooth.nix` (csr/realtek airpods), `keyboard.nix` (i8042 kmonad), `lid.nix` (hibernate uuid).
  - desktop-only: `nvidia.nix` (proprietary, not nouveau), `wifi.nix` (ssid; psk outside the store), kingston `hardware-configuration.nix`.

- `modules/common.nix`
  - shared system composition (sway/gdm, netbird, home-manager consumer modules, user, locale).

- `modules/*.nix`
  - machine/system configuration grouped by ownership.
  - use modules for services, desktop enablement, networking, nix settings, and system packages.
  - do not put laptop adapter policy or nvidia in a shared module.

- `home/sf.nix`
  - user-level configuration for `sf` via home manager.
  - put shell aliases, ssh client config, user packages, xdg config files, and per-user env vars here.

- `home/files/`
  - declarative user config files linked into `~/.config` by home manager.
  - sway, kitty, fuzzel, swaynotificationcenter, i3status-rust, gtk, and cursor/sound config live here.

- `home/scripts/`
  - helper scripts wrapped from `home/sf.nix` with `pkgs.writeShellApplication` or similar.
  - scripts are not available to the user until wrapped and added to `home.packages`.

- `pkgs/*.nix`
  - local package definitions.
  - package files should build artifacts, not configure the system.

## completion contract

a change is not complete until the appropriate proof exists.

for nix or home-manager changes:

1. inspect first:
   - `git status --short`
   - read the relevant module/runbook, not just the file you think is involved
2. make the smallest coherent change.
3. if adding files that nix imports or reads, run `git add` before eval.
   - nix flakes cannot see untracked files. this is not optional.
4. evaluate:
   - `nix eval --raw .#nixosConfigurations.laptop.config.system.build.toplevel`
   - `nix eval --raw .#nixosConfigurations.desktop.config.system.build.toplevel`
     if the change can touch shared modules or home.
5. switch only the machine you are on, after eval passes, unless the user explicitly says not to:
   - on sfnix: `sudo nixos-rebuild switch --flake .#laptop`
   - on sfub: `sudo nixos-rebuild switch --flake .#desktop`
   - never switch `#desktop` on sfnix or `#laptop` on sfub. `nixrebuild` refuses this.
6. verify runtime behavior with commands from `docs/verification.md`.
7. commit if the user asked for a commit.
8. summarize the git diff-level change and the verification performed.

for docs-only changes:

1. inspect `git status --short`.
2. edit the docs.
3. verify links/paths by reading the touched docs.
4. commit if the user asked for a commit.

never claim a nixos change worked just because the file was edited. a successful rebuild and runtime check are the evidence.

## ownership rules

put settings where they belong:

- nixos system config:
  - boot, kernel, hardware, firmware
  - networkmanager, tailscale daemon, openssh server
  - users and groups
  - pipewire service, bluetooth controller behavior
  - display managers and system desktop enablement
  - firewall, power management, system gc
  - flatpak service (`modules/flatpak.nix`)

- home manager:
  - shell aliases
  - ssh client config
  - user cli/gui packages
  - editor/shell/git config
  - xdg config files under `/home/sf/.config`
  - per-user environment variables

- local packages:
  - custom derivations such as `pkgs/herdr.nix`

if unsure, ask: "does this configure the machine, the user, or a build artifact?"

## runbook map

use these before editing common areas:

- `docs/runbooks/rebuild.md`
  - eval/switch/verify loop and flake gotchas.

- `docs/runbooks/add-package.md`
  - where to add system packages, user packages, or local derivations.

- `docs/runbooks/home-manager-file.md`
  - how to add managed files under `~/.config` or user scripts.

- `docs/runbooks/sway-keybind.md`
  - how to alter sway binds or add helper commands.

- `docs/runbooks/bluetooth.md`
  - how to touch laptop bluetooth without breaking the airpods/dongle workaround.

- `docs/runbooks/roblox.md`
  - Sober (Flathub) for Roblox player. not wine.

- `docs/runbooks/desktop-install.md`
  - install `#desktop` onto the kingston ssd. never the samsung ubuntu nvme.

## bluetooth warning

airpods audio is load-bearing on the laptop. adapter policy and bluez flags must stay aligned.

intended state:

```text
CSR USB dongle UP:     00:1A:7D:DA:71:13   (AirPods audio)
Realtek internal DOWN: F4:6A:DD:26:38:42
bluetoothd:            -P headset          (HFP off)
AirPods MAC:           2C:32:6A:C1:8D:00
helper:                airpods-fix
module:                hosts/laptop/bluetooth.nix
```

`Connected: yes` without a PipeWire sink / MediaTransport is failure (usually bad bond Type=0 or no encryption).

do not invert adapter policy or drop `-P headset` as cleanup. if changing bluetooth, read:

```text
docs/runbooks/bluetooth.md
docs/known-constraints.md
```

and verify with `airpods-fix --status` after rebuild.

desktop bluetooth is `hosts/desktop/bluetooth.nix`. do not import the laptop module there.

## herdr

`herdr` is packaged in `pkgs/herdr.nix` and installed system-wide by `modules/herdr.nix`.

user config for herdr lives in home manager:

```text
home/sf.nix -> xdg.configFile."herdr/config.toml"
```

runtime logs/sockets/session files under `/home/sf/.config/herdr/` are state, not source config. do not put sockets, logs, or session json into nix.

## adding packages

- package needed by the whole system or root? add to `modules/packages.nix`.
- package only for `sf`? add to `home/sf.nix`.
- package not in nixpkgs? create or update a derivation in `pkgs/` and consume it from a module or home config.
- flathub app (Sober)? add the app id in `modules/flatpak.nix`.

avoid dumping everything into `environment.systemPackages`.

## adding modules

create a new module only when it has a clear owner and repeated reason to exist.

good module names:

- `bluetooth.nix`
- `desktop.nix`
- `flatpak.nix`
- `networking.nix`
- `power.nix`

bad module names:

- `misc.nix`
- `stuff.nix`
- `fixes.nix`

if a module cannot be described in one plain sentence, it is probably fake structure.

## do not

- do not edit `/etc/xdg/herdr/config.toml`; edit `home/sf.nix`.
- do not manually replace `~/.config/sway/config`; home-manager owns it.
- do not delete `hosts/laptop/bluetooth.nix` because the usb dongle workaround looks temporary.
- do not put passwords, api keys, private ssh keys, tokens, or sudo passwords into nix files.
- do not add untracked files and then run nix eval expecting flakes to see them.
- do not claim a graphical setting works from an ssh tty without checking the actual runtime state where possible.
- do not install Roblox via wine, grapejuice, vinegar, or proton. Sober only.
- do not put a wifi psk, netbird setup key, or nvidia ICD hacks for the other gpu in this repo.
- do not format the samsung nvme while installing desktop nixos. kingston only. see `docs/runbooks/desktop-install.md`.

## secrets

never put secrets, api keys, private ssh keys, tokens, or passwords into nix files.
anything in the nix store may be readable by other local users.
use a secrets tool later (`sops-nix`, `agenix`, systemd credentials, or another explicit secret path outside the store).

## flakes and future agent capability work

this repo may later expose dev shells or consume local capability flakes for agents.
keep the boundary clear:

- flakes/devshells provide reproducible command environments.
- skills/documentation teach an agent how to use those commands.
- tool calls are host-provided execution interfaces and may have stronger semantics than raw shell.
- flakes alone are not a security sandbox.

when adding agent dev shells, prefer starting in this flake under `devShells` before splitting into separate flakes. split only once another repo or host actually reuses the capability set.
