# rollback

use this when a switch succeeds but the new system is bad.

## immediate rollback

```bash
sudo nixos-rebuild switch --rollback
```

## inspect generations

```bash
sudo nix-env --list-generations --profile /nix/var/nix/profiles/system
```

## boot-time rollback

if the machine cannot boot/use the new generation, choose an older generation from the systemd-boot menu.

## after rollback

1. inspect the bad git diff.
2. revert or patch the repo.
3. run eval again.
4. switch again only after understanding the failure mode.

rollback changes the active system generation. it does not automatically revert git.
