#!/usr/bin/env bash
# Script to trigger quickshell:wallpaperSelectorRandom action
# This will select a random wallpaper automatically
# Runs every 30 minutes via cron or systemd timer

set -euo pipefail

# Get the real path of this script, resolving symlinks
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" || echo "${BASH_SOURCE[0]}")"
CONFIG_DIR="$(cd "$(dirname "$SCRIPT_PATH")/../.." && pwd)"

# Extract qsConfig value from hyprland.conf
if [[ -f "$CONFIG_DIR/hyprland.conf" ]]; then
    QS_CONFIG="$(grep -E '^\$qsConfig\s*=' "$CONFIG_DIR/hyprland.conf" | awk -F'=' '{print $2}' | tr -d ' ')"
else
    QS_CONFIG="ii"  # Default value from hyprland.conf
fi

echo "[$(date '+%Y-%m-%d %H:%M:%S')] Triggering random wallpaper selection..."

# Method 1: Use hyprctl dispatch (primary method)
if command -v hyprctl >/dev/null 2>&1; then
    # Syntax from keybinds.conf: global, quickshell:wallpaperSelectorRandom
    if hyprctl dispatch global "quickshell:wallpaperSelectorRandom" >/dev/null 2>&1; then
        echo "Success: Random wallpaper selected via hyprctl dispatch"
        exit 0
    else
        echo "Warning: hyprctl dispatch failed, trying fallback..."
    fi
fi

# Method 2: Fallback - use the switchwall.sh script directly
SWITCHWALL_SCRIPT="$HOME/.config/quickshell/$QS_CONFIG/scripts/colors/switchwall.sh"
if [[ -f "$SWITCHWALL_SCRIPT" ]]; then
    echo "Running switchwall.sh as fallback..."
    if bash "$SWITCHWALL_SCRIPT"; then
        echo "Success: Wallpaper changed via switchwall.sh"
        exit 0
    else
        echo "Error: switchwall.sh failed"
        exit 1
    fi
else
    echo "Error: switchwall.sh not found at $SWITCHWALL_SCRIPT"
    exit 1
fi