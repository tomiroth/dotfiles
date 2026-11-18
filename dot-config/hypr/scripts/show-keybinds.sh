#!/usr/bin/env bash
set -euo pipefail

# Ghostty is the preferred terminal in this dotfiles repository. The fallbacks
# make the guide useful if the config is copied to another machine.
keybinds="${XDG_CONFIG_HOME:-$HOME/.config}/hypr/keybinds.txt"

if command -v ghostty >/dev/null 2>&1; then
    exec ghostty --fullscreen=false --class=hyprland-keybinds --title='Hyprland keybindings' -e less -R "$keybinds"
elif command -v kitty >/dev/null 2>&1; then
    exec kitty --class hyprland-keybinds --title 'Hyprland keybindings' less -R "$keybinds"
elif command -v foot >/dev/null 2>&1; then
    exec foot --app-id=hyprland-keybinds less -R "$keybinds"
else
    notify-send 'Hyprland keybindings' "Open $keybinds" 2>/dev/null || true
fi
