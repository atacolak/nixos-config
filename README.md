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

for bluetooth management, use `bluetui`.
to manage wifi, use `nmtui`.
