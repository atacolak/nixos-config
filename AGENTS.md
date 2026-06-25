# agents guide for this nixos configuration

this repo is the declarative source of truth for the laptop named `sfnix`.
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
  - pins inputs and wires the laptop system together.
  - keep this boring. add inputs only when there is a real consumer.

- `hosts/laptop/configuration.nix`
  - host identity and composition.
  - this file should answer: "what is this machine?"
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
5. switch only after eval passes, unless the user explicitly says not to:
   - `sudo nixos-rebuild switch --flake .#laptop`
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
  - how to touch bluetooth without breaking the airpods/dongle workaround.

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

do not remove this unless you are intentionally retesting bluetooth hardware. if changing it, read:

```text
docs/runbooks/bluetooth.md
docs/known-constraints.md
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

## do not

- do not edit `/etc/xdg/herdr/config.toml`; edit `home/sf.nix`.
- do not manually replace `~/.config/sway/config`; home-manager owns it.
- do not delete `modules/bluetooth.nix` because the usb dongle workaround looks temporary.
- do not put passwords, api keys, private ssh keys, tokens, or sudo passwords into nix files.
- do not add untracked files and then run nix eval expecting flakes to see them.
- do not claim a graphical setting works from an ssh tty without checking the actual runtime state where possible.

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
