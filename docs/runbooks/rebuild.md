# runbook: rebuild

use `nixrebuild`. do not retype the flake path.

```bash
nixrebuild           # eval, then sudo switch
nixrebuild --eval    # eval only
nixrebuild --dry     # dry-run
```

it:

- `cd`s to `/home/sf/nixos-config`
- refuses untracked nix-read files (flake cannot see them)
- refuses to switch if `services.netbird.enable` is not `true`
- then `sudo nixos-rebuild switch --flake ~/nixos-config#laptop` on sfnix, `#desktop` on sfub

you type sudo. agents should not run this unattended.

rollback: `nixrollback` (see `docs/rollback.md`).

## when not to switch

skip switch only if:

- the user asked for a draft only
- you are changing docs only
- eval fails and you are still debugging

## after switch

verify the relevant runtime behavior using `docs/verification.md`.
check `systemctl is-active netbird` before you walk away.
