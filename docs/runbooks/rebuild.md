# runbook: rebuild

use for nixos or home-manager changes.

## loop

```bash
cd /home/sf/nixos-config
git status --short
```

if new nix-read files were added:

```bash
git add path/to/file
```

flakes cannot see untracked files.

then:

```bash
nix eval --raw .#nixosConfigurations.laptop.config.system.build.toplevel
sudo nixos-rebuild switch --flake .#laptop
readlink /run/current-system
systemctl --no-pager is-active home-manager-sf.service
```

## when not to switch

skip switch only if:

- the user asked for a draft only
- you are changing docs only
- eval fails and you are still debugging

## after switch

verify the relevant runtime behavior using `docs/verification.md`.
