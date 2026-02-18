#!/bin/bash

# Get the active window class
WINDOW_CLASS=$(hyprctl activewindow | grep -E "^\s+class:" | awk '{print $2}')

# List of browser classes
BROWSERS="^chrome$|^google-chrome$|^firefox$|^librewolf$|^floorp$|^brave$|^chromium$|^vivaldi$|^opera$"

# Debug logging
echo "browser-pagedown: ARG=$1, WINDOW_CLASS=$WINDOW_CLASS" >> /tmp/browser-pagedown.log

# Check if current window is a browser
if echo "$WINDOW_CLASS" | grep -qiE "$BROWSERS"; then
    echo "browser-pagedown: Matched browser" >> /tmp/browser-pagedown.log
    # Execute the key press with Ctrl modifier
    case "$1" in
        up)
            wtype -M ctrl -k Page_Up -m ctrl 2>&1 | tee -a /tmp/browser-pagedown.log
            ;;
        down)
            wtype -M ctrl -k Page_Down -m ctrl 2>&1 | tee -a /tmp/browser-pagedown.log
            ;;
        w)
            wtype -M ctrl -k w -m ctrl 2>&1 | tee -a /tmp/browser-pagedown.log
            ;;
    esac
fi
