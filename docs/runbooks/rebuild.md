# runbook: rebuild

use `nixrebuild`. do not retype the flake path.

```bash
nixrebuild           # password first, then eval, then switch
nixrebuild --eval    # dry-run: eval only, no sudo
nixrebuild --check   # alias for --eval
nixrebuild --dry     # password first, then sudo dry-run
```

agents dry-run with `nixrebuild --eval`. that is the check that would have
caught an untracked `home/files/herdr/config.toml` before a switch.

it:

- `cd`s to `/home/sf/nixos-config`
- refuses untracked nix-read files (flake cannot see them). that includes
  `home/files/**`, `modules/**`, `hosts/**`, `pkgs/**`, `*.nix`
- for a real rebuild: asks sudo **first**, then evals, then switches
  (password is not delayed until after a long eval)
  keeps sudo alive during eval so it does not expire
- skips switch if the eval matches the running system
- refuses to switch if `services.netbird.enable` is not `true`
- then `sudo nixos-rebuild switch --flake ~/nixos-config#laptop` on sfnix, `#desktop` on sfub

you type sudo. agents should not run this unattended. agents may run `--eval`.
run it from kitty. sway has no polkit popup.

rollback: `nixrollback` (see `docs/rollback.md`).

## when not to switch

skip switch only if:

- the user asked for a draft only
- you are changing docs only
- eval fails and you are still debugging

## after switch

verify the relevant runtime behavior using `docs/verification.md`.
check `systemctl is-active netbird` before you walk away.
