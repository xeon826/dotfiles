#!/usr/bin/env bash
# Script to switch monitor configurations
# Usage: switch-monitors.sh [triple|bigscreen|all]

set -euo pipefail

# Get the real path of this script, resolving symlinks
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" || echo "${BASH_SOURCE[0]}")"
CONFIG_DIR="$(cd "$(dirname "$SCRIPT_PATH")/../.." && pwd)"
MONITORS_CONF="${CONFIG_DIR}/monitors.conf"
TRIPLE_CONF="${CONFIG_DIR}/triple.monitors.conf"
BIGSCREEN_CONF="${CONFIG_DIR}/bigscreen.monitors.conf"
ALL_CONF="${CONFIG_DIR}/all.monitors.conf"

# Ensure autoreload is disabled
echo "Disabling auto reload in Hyprland..."
if ! hyprctl keyword misc:disable_autoreload true; then
    echo "Warning: Failed to disable auto reload. Continuing anyway." >&2
fi

# Check argument
if [[ $# -ne 1 ]]; then
    echo "Usage: $0 [triple|bigscreen|all]"
    exit 1
fi

case "$1" in
    triple)
        echo "Switching to triple monitor configuration..."
        if [[ ! -f "$TRIPLE_CONF" ]]; then
            echo "Error: Source file $TRIPLE_CONF not found." >&2
            exit 1
        fi
        cp -f "$TRIPLE_CONF" "$MONITORS_CONF"
        ;;
    bigscreen)
        echo "Switching to bigscreen monitor configuration..."
        if [[ ! -f "$BIGSCREEN_CONF" ]]; then
            echo "Error: Source file $BIGSCREEN_CONF not found." >&2
            exit 1
        fi
        cp -f "$BIGSCREEN_CONF" "$MONITORS_CONF"
        ;;
    all)
        echo "Switching to all monitors configuration..."
        if [[ ! -f "$ALL_CONF" ]]; then
            echo "Error: Source file $ALL_CONF not found." >&2
            exit 1
        fi
        cp -f "$ALL_CONF" "$MONITORS_CONF"
        ;;
    *)
        echo "Invalid argument: $1"
        echo "Usage: $0 [triple|bigscreen|all]"
        exit 1
        ;;
esac

# Reload Hyprland configuration
echo "Reloading Hyprland configuration..."
if ! hyprctl reload; then
    echo "Warning: hyprctl reload returned non-zero exit status." >&2
fi

echo "Monitor configuration switched successfully."