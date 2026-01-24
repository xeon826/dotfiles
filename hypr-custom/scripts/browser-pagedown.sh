#!/bin/bash

# Get the active window class
WINDOW_CLASS=$(hyprctl activewindow | grep -E "^\s+class:" | awk '{print $2}')

# List of browser classes
BROWSERS="^chrome$|^google-chrome$|^firefox$|^librewolf$|^floorp$|^brave$|^chromium$|^vivaldi$|^opera$"

# Check if current window is a browser
if echo "$WINDOW_CLASS" | grep -qiE "$BROWSERS"; then
    # Execute the key press with Ctrl modifier
    case "$1" in
        up)
            wtype -M Ctrl -k Page_Up -m Ctrl
            ;;
        down)
            wtype -M Ctrl -k Page_Down -m Ctrl
            ;;
    esac
fi