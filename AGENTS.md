# agents guide for this nixos configuration

this repo is the declarative source of truth for the laptop named `sfnix`.
edit nix files here; do not hand-edit generated files in `/etc`, `/run/current-system`, or `/nix/store`.

## working loop

1. inspect before editing:
   - `git status --short`
   - read the relevant module, not just the file you think is involved
2. make the smallest coherent change.
3. evaluate:
   - `nix eval --raw .#nixosConfigurations.laptop.config.system.build.toplevel`
4. switch only after eval passes:
   - `sudo nixos-rebuild switch --flake .#laptop`
5. verify the runtime behavior with real commands.
6. show `git diff`-level summary in your final response.

never claim a nixos change worked just because the file was edited. a successful rebuild and runtime check are the evidence.

## file map

- `flake.nix`
  - pins inputs and wires the laptop system together.
  - keep this boring. add inputs only when there is a real consumer.

- `hosts/laptop/configuration.nix`
  - host identity and composition.
  - this file should answer: “what is this machine?”
  - keep hardware scan import, hostname, locale/timezone, bootloader, user account, and imported modules here.

- `hosts/laptop/hardware-configuration.nix`
  - generated hardware scan.
  - do not casually edit. if hardware changes, regenerate intentionally.

- `modules/*.nix`
  - machine/system configuration grouped by ownership.
  - use modules for services, hardware behavior, desktop enablement, networking, nix settings, and system packages.

- `home/sf.nix`
  - user-level configuration for `sf` via home manager.
  - put shell aliases, ssh client config, user packages, xdg config files, and per-user env vars here.

- `pkgs/*.nix`
  - local package definitions.
  - package files should build artifacts, not configure the system.

## ownership rules

put settings where they belong:

- nixos system config:
  - boot, kernel, hardware, firmware
  - networkmanager, tailscale daemon, openssh server
  - users and groups
  - pipewire service, bluetooth controller behavior
  - display managers and system desktop enablement
  - firewall, power management, system gc

- home manager:
  - shell aliases
  - ssh client config
  - user cli/gui packages
  - editor/shell/git config
  - xdg config files under `/home/sf/.config`
  - per-user environment variables

- local packages:
  - custom derivations such as `pkgs/herdr.nix`

if unsure, ask: “does this configure the machine, the user, or a build artifact?”

## bluetooth warning

this laptop has a broken-ish internal realtek bluetooth/wifi combo chip.
airpods failed on the internal controller and worked on the usb csr dongle.

`modules/bluetooth.nix` intentionally disables the internal controller with address:

```text
F4:6A:DD:26:38:42
```

and leaves the usb dongle controller available:

```text
00:1A:7D:DA:71:13
```

do not remove this unless you are intentionally retesting bluetooth hardware. if changing it, verify with:

```bash
bluetoothctl list
hciconfig -a
wpctl status
journalctl -b -u bluetooth --since '5 min ago'
```

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

avoid dumping everything into `environment.systemPackages`.

## adding modules

create a new module only when it has a clear owner and repeated reason to exist.

good module names:

- `bluetooth.nix`
- `desktop.nix`
- `networking.nix`
- `power.nix`

bad module names:

- `misc.nix`
- `stuff.nix`
- `fixes.nix`

if a module cannot be described in one plain sentence, it is probably fake structure.

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
