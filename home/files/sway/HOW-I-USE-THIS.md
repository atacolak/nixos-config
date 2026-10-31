# this file sits next to `config`

the bindings are in `home/files/sway/config`. `$mod` is Mod4. caps becomes Mod4 through kmonad, so when i say Caps+W i mean this file's `$mod+w`.

"it is how i USE and EXPECT from my system."

"i am still on sway. i am kinda scared to go bc it has to work very very good and almost flawlessly!!"

## caps as prefix (the language)

the first lines of the sway config already admit the split of labour:

```
# caps emits mod4 via kmonad; fast double-tap caps still toggles caps lock.
set $mod Mod4
```

apps i live in, current workspace only (`wmutil cycle-or-run --scope current`):

| i press | sway line | what it does |
|---|---|---|
| Caps+T | `bindsym $mod+t` ~L121 | cycle-or-run kitty |
| Caps+F | `bindsym $mod+f` ~L119 | cycle-or-run firefox |
| Caps+C | `bindsym $mod+c` ~L120 | cycle-or-run code |
| Caps+D | `bindsym $mod+d` ~L122 | cycle-or-run thunar |

absent window launches; existing one on *this* desktop focuses. not "whatever firefox is on desktop 7".

## caps+w is a deck, not overview

"how i use caps+w to collapse selected windows into one that i can alt-tab or alt-shift-tab to switch like a deck of cards"

exact binds, not a paraphrase:

```
bindsym $mod+w layout tabbed
bindsym Mod1+Tab exec --no-startup-id $i3_cycle_tab_sibling
bindsym Mod1+Shift+Tab exec --no-startup-id $i3_cycle_tab_sibling --reverse
```

`$i3_cycle_tab_sibling` is `home/scripts/i3-cycle-tab-sibling`: nearest tabbed/stacked parent, siblings only. a global window walker is a wrong answer even if it "feels similar".

Caps+E stacking, Caps+S default, Caps+G toggle split live on L197–L200.

## tree and resize are modes, not one-shots

"Caps+Y tree mode and Caps+R resize mode are real multi-keystroke interactions."

```
bindsym $mod+y mode "tree"
bindsym $mod+r mode "resize"
```

tree mode then `t/f/c/d` (and Shift for vertical) spawns a *local* sibling. resize mode is 10px / Shift 40px. Esc/Return leaves the mode.

Caps+U / Caps+I are `focus parent` / `focus child` (L204–L205).

## prove it like a human, or leave it red

"i want very good tiling and for it to actually work. make them do whatever they can to make sure their testing is as close to how a human would. even if it takes actually sending those key presses."

from ssh, do not inject into the live seat. from inside the session:

```bash
swaymsg -t get_version
swaymsg -t get_tree
```

a mocked tree is not this file.

sha256 of this `config` when this page was written: `56f45031c9beaec0c5ef7c4deaed8e86fbdf30eb12bf67391162f15068d7fe44`
