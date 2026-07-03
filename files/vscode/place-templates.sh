#!/bin/bash
SETTINGS="$HOME/.config/Code/User/settings.json"
KEYBINDINGS="$HOME/.config/Code/User/keybindings.json"

SETTINGS_SRC="$1"
KEYBINDINGS_SRC="$2"

if [ ! -f "$SETTINGS" ]; then
  cp "$SETTINGS_SRC" "$SETTINGS"
  chmod u+w "$SETTINGS"
fi

if [ ! -f "$KEYBINDINGS" ]; then
  cp "$KEYBINDINGS_SRC" "$KEYBINDINGS"
  chmod u+w "$KEYBINDINGS"
fi
