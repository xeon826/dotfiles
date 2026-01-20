#!/usr/bin/env bash

# Get info about the active window
active_window_info=$(hyprctl activewindow -j)

# Check if the active window is fullscreen (fullscreen values can be 0, 1, or 2)
is_fullscreen=$(echo "$active_window_info" | jq -r '.fullscreen')
# Check if the active window is in pseudo state (maximized in Hyprland)
is_pseudo=$(echo "$active_window_info" | jq -r '.pseudo')

# If the window is fullscreen, exit fullscreen
if [[ "$is_fullscreen" != "0" ]]; then
	hyprctl dispatch fullscreen 0
fi

# If the window is in pseudo state (maximized), exit pseudo state
if [[ "$is_pseudo" == "true" ]]; then
	hyprctl dispatch pseudo
fi

for cmd in "$@"; do
	[[ -z "$cmd" ]] && continue
	eval "command -v ${cmd%% *}" >/dev/null 2>&1 || continue
	eval "$cmd" &
	exit
done
