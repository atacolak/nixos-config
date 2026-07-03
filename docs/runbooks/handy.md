# Handy transcription app

## overlay position (sway)

handy's self-positioning is broken on sway/wayland. its overlay_position setting is ignored.
instead we hard-code the recording overlay position via sway's for_window rule.

in modules/desktop.nix (programs.sway.extraConfig) — applied via nixos-rebuild switch:

    for_window [class="Handy" title="Recording"] move position center, move down 400 px, border none, sticky enable
    no_focus [class="Handy" title="Recording"]

- move position center — centers horizontally on 1920-wide display
- move down 400 px — pushes from vertical center toward bottom (1920x1080)
- sticky enable — overlay follows across all workspaces
- no_focus — don't steal focus when recording starts

to tweak: adjust the move down pixel value. reload sway: swaymsg reload

## paste / typing on wayland

### the problem

handy's internal keyboard simulation uses the enigo crate's X11 backend (xtest_fake_input).
on sway/wayland, those keystrokes go to xwayland's fake X server and never reach native
wayland windows. the tool logs success but nothing types.

### the fix

1. install wtype (wayland-native virtual keyboard):
   - added to home.packages in home/sf.nix

2. handy settings in ~/.local/share/com.pais.handy/settings_store.json:
   - typing_tool: wtype — uses wayland zwp_virtual_keyboard_v1 protocol
   - paste_method: direct — types text character-by-character via wtype
   - keyboard_implementation: handy_keys — avoids tauri x11-dependent keyboard api
   - clipboard_handling: copy_to_clipboard — copies via wl-clipboard (works fine)

### debugging

- log: ~/.local/share/com.pais.handy/logs/handy.log
- if paste breaks after updates, check log for enigo::platform::x11 — that's the x11 backend
- verify typing tools: which wtype ydotool dotool
- handy binary enums (for settings reference):
  - typing_tool: wtype, kwtype, dotool, ydotool, xdotool
  - paste_method: ctrl_v, direct, shift_insert, ctrl_shift_v, external_script
  - keyboard_implementation: tauri, handy_keys
  - clipboard_handling: dont_modify, copy_to_clipboard
  - overlay_position: top, bottom

## global shortcuts

sway owns ctrl+space (handy internal tauri shortcut doesn't work on sway).
bound in sway config:

    bindsym --no-repeat Control+space exec --no-startup-id handy --toggle-transcription
    bindsym --no-repeat Control+Shift+space exec --no-startup-id handy --toggle-post-process

handy's own bindings are remapped to obscure chords (ctrl+alt+shift+f12/f11) by
handy-sway-start so they don't conflict.

## model

parakeet-unified-en-0.6b (Q8_0 GGUF). managed by handy built-in model downloader.
stored at ~/.local/share/com.pais.handy/models/
