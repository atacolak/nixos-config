# rollback

use this when a switch succeeds but the new system is bad.

```bash
nixrollback           # previous generation
nixrollback 109       # that generation
nixrollback --list    # list generations
```

does not revert git. inspect the tree, then `nixrebuild` only once you know why the new gen was bad.

## boot-time rollback

if the machine cannot boot/use the new generation, choose an older generation from the systemd-boot menu.

## after rollback

1. inspect the bad git diff.
2. revert or patch the repo.
3. `nixrebuild --eval`
4. `nixrebuild` only after understanding the failure mode.
