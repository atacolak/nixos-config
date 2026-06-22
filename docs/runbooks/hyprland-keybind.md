# runbook: hyprland keybind

hyprland config is plain `.conf`, not lua.

edit:

```text
home/files/hypr/hyprland.conf
```

## change a bind

1. find the existing bind block.
2. preserve comments that explain hardware key meanings.
3. use `bind`, `bindl`, `binde`, or `bindel` intentionally:
   - `l` works while locked
   - `e` repeats while held
4. eval and switch.
5. verify from a graphical hyprland session:

```bash
hyprctl configerrors
hyprctl binds
```

## add a helper command for a bind

1. add script in `home/scripts/`.
2. wrap it in `home/sf.nix`.
3. add wrapped package to `home.packages`.
4. add the bind in `home/files/hypr/hyprland.conf`.
5. `git add` all new files before eval.
6. verify:

```bash
command -v <helper>
hyprctl binds | rg '<key-or-helper>'
```

## fn-row note

hyprland generally sees fn-row actions as `XF86...` symbols, not as literal `fn+fN`.
