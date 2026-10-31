# nixos as i actually live it

this is the operator-first story for the *isolated* flake at
`~/workspace/nixos-config-observeos-plasma` (`feat/observeos-plasma`).
it is not the dirty `~/nixos-config` checkout. it is not a switch.

the operator asked for the configs to be a form of art:

> "you take ownership of my nixos configs too, making sure they are a form of ART, making sure it has personal writing-blogposting-ish stuff which would make it actually amusing to read, too."

and, specifically:

> "the fact that our system is literally declarative does help on this, of course. we can know so much more as opposed to a more closed system would."

> "i really liked nixOS's declarative surface because i can literally make it extremely hard for agents to not know what is up with the system they are running or to lie (lol)? they write the system anyway, i tell that what i want and they do the system work."

so: the runnable nix stays syntax-pristine. this file, `hosts/laptop/KEYBOARD.md`, `home/files/sway/HOW-I-USE-THIS.md`, and `docs/OPERATOR-NOTES.md` are the writing. if an agent "summarizes" the quotes into smoother prose, that is a bug.

operator phrasing lives in `docs/OPERATOR-NOTES.md` (copied, not rewritten).

## where the body of the language is

| lived thing | file | notes |
|---|---|---|
| caps prefix / double-tap | `hosts/laptop/keyboard.nix` | kmonad `multi-tap 300 lmet caps`. origin reddit *or* stackoverflow, **unverified**. |
| same, in words | `hosts/laptop/KEYBOARD.md` | beside the nix, not inside it |
| caps+w deck, cycle-or-run, tree/resize | `home/files/sway/config` | `$mod` = Mod4 = kmonad lmet |
| same, in words | `home/files/sway/HOW-I-USE-THIS.md` | beside the config |
| rollback if a *future* switch is bad | `docs/rollback.md` | `nixrollback`; does not revert git |
| smallest proof | `docs/verification.md` | eval ≠ switch |
| plasma shortcuts sitting dark | `home/plasma-observeos/plasma-shortcuts.nix` | `enable` defaults **false**, **not imported** from `home/sf.nix` |

i am still on sway. obs-36o.2.5 stays deferred.

> "i am still on sway. i am kinda scared to go bc it has to work very very good and almost flawlessly!!"

## declarative reproducibility (how an agent is supposed to not lie)

nixos evaluation is the cheap honesty check. it does **not** change the running generation.

from this isolated worktree, not from dirty `~/nixos-config`:

```bash
cd /home/sf/workspace/nixos-config-observeos-plasma
git status --short
git log -1 --oneline
nix eval --raw .#nixosConfigurations.laptop.config.system.build.toplevel
```

flakes only see **tracked** files (`docs/known-constraints.md`). a new nix path that is not `git add`'d is invisible. markdown in this commit is not imported by the flake, so it cannot change that toplevel.

observed on 2026-10-30, live machine (this is the *running* system, not the isolated candidate):

```text
readlink /run/current-system
# ...-nixos-system-sfnix-26.11.20260813.0e251e2
systemctl is-active kmonad-internal.service   # active
```

the isolated HEAD when this was written: `87b91012bde5d61ae9ae0d0bd873d0e17362b2fa`
(`feat: package observeos-tree as a declarative KWin script`).
parent trail includes `9a2476e` (unactivated plasma shortcuts) and `ffc4652` (plasma6.enable in the candidate only).

hashes of the two files that actually define the keyboard language, same in this worktree and in live `~/nixos-config` at time of writing:

```text
56f45031c9beaec0c5ef7c4deaed8e86fbdf30eb12bf67391162f15068d7fe44  home/files/sway/config
160761fc7f347daa7852fec515ad83de83a0d7ff122a9259fb65fd259a617136  hosts/laptop/keyboard.nix
```

`nixos-rebuild switch` is forbidden here. `docs/verification.md` even says not to do theatrical rebuilds for docs-only edits. good.

## failed experiments (kept red, not retconned)

these happened. they stay in the story so nobody "fixes" them by lying.

1. **caps origin.** i remember reddit or stackoverflow. no url. a tidy blog origin would be fake. `docs/OPERATOR-NOTES.md` forbids it.
2. **kmonad comment vs compositor.** `keyboard.nix` still mentions Hyprland. live session is Sway. left the nix alone.
3. **duplicate KDE shortcut INI.** first generated `kglobalshortcutsrc` reused option names (`set-mute-toggle`, `playerctl`, `brightness`). last-wins dropped mute/play/brightness-down; `observeos-cycle.desktop` overwrite dropped Caps+T/F/C/D from desktop files. tests that only `assertIn` a substring were false-green. repaired in observeOS, copied here as unique desktops under `home/plasma-observeos/generated/applications/observeos-cycle-{kitty,firefox,code,thunar}.desktop`. still **not enabled**.
4. **i3-resurrect is not "retired because we don't care".** `docs/PHASE-0-DESKTOP-PARITY.md:40` (observeOS) says keep the *ability* to preserve/work with layouts. the scripts are not ported. classification is deferred, not "undesired".
5. **polonium / mocked trees.** a nested KWin lab without the required local tab/stack/parent-child behavior is a FAIL, not "plasma ready". tiling lives in other beads. this narrative does not claim the deck works under KWin.
6. **global `XDG_CURRENT_DESKTOP=sway`.** leaking that into a plasma session is how you get the wrong portals. isolated `home/sf.nix` dropped the global; Sway's GDM session file still sets it for Sway. do not put it back globally.
7. **sfnix unreachable.** inventory was done from these hashed snapshots while netbird was Connecting. later ssh confirmed the hashes still match. that is not the same as P0-K.
8. **Meta+L.** stock KDE lock is Meta+L. my Caps+L is focus right (`bindsym $mod+l focus right`). any plasma port has to move lock to Caps+semicolon (`$mod+semicolon` → `i3-lock`). not activated.

## rollback (when someone *does* switch, later)

from `docs/rollback.md`:

```bash
nixrollback           # previous generation
nixrollback --list
```

boot menu if it cannot boot. rollback does **not** revert git. inspect the diff, `nixrebuild --eval`, then maybe switch.

this docs commit does not create a generation. there is nothing to roll back except `git revert` of the markdown.

## plasma shortcuts: present, dark, on purpose

`home/plasma-observeos/NOT-ACTIVATED.txt` is the warning label.

```nix
options.observeos.plasmaShortcuts.enable = lib.mkEnableOption "...";
# default false. home/sf.nix does not import the module.
```

do not set `enable = true`. do not import it into the live user. do not copy `kglobalshortcutsrc` into `~/.config`.

## human-grade proof still outstanding

> "make them do whatever they can to make sure their testing is as close to how a human would. even if it takes actually sending those key presses."

physical Caps double-tap on this kmonad device: **NOT RUN**.
live Caps+W deck under plasma: **NOT RUN**.
operator stays on sway until that is actually true.

"it is as if the agent is here." only if the agent can point at these files and the running unit and not invent the rest.
