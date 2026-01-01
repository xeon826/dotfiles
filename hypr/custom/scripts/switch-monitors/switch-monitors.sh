#!/usr/bin/env bash
# Script to switch monitor configurations
# Usage: switch-monitors.sh [triple|bigscreen|all]

set -euo pipefail

# Get the real path of this script, resolving symlinks
SCRIPT_PATH="$(readlink -f "${BASH_SOURCE[0]}" || echo "${BASH_SOURCE[0]}")"
CONFIG_DIR="$(cd "$(dirname "$SCRIPT_PATH")/../.." && pwd)"
MONITORS_CONF="${CONFIG_DIR}/monitors.conf"
TRIPLE_CONF="${CONFIG_DIR}/scripts/switch-monitors/triple.monitors.conf"
BIGSCREEN_CONF="${CONFIG_DIR}/scripts/switch-monitors/bigscreen.monitors.conf"
ALL_CONF="${CONFIG_DIR}/scripts/switch-monitors/all.monitors.conf"

# Monitor names (ordered as they appear in configurations)
MONITORS=("HDMI-A-1" "DP-1" "DP-2" "DP-3")

# Function to check if a monitor is disabled in the given config file
is_monitor_disabled() {
    local config_file="$1"
    local monitor="$2"
    grep -q "^monitor=${monitor},disable" "$config_file" 2>/dev/null
}

# Function to detect current configuration based on monitors.conf
detect_current_config() {
    local enabled_count=0
    local hdmi_enabled=0

    # Check HDMI-A-1
    if ! is_monitor_disabled "$MONITORS_CONF" "HDMI-A-1"; then
        enabled_count=$((enabled_count + 1))
        hdmi_enabled=1
    fi

    # Check DP monitors
    for dp in "DP-1" "DP-2" "DP-3"; do
        if ! is_monitor_disabled "$MONITORS_CONF" "$dp"; then
            enabled_count=$((enabled_count + 1))
        fi
    done

    # Determine configuration
    if [[ $enabled_count -eq 1 && $hdmi_enabled -eq 1 ]]; then
        echo "bigscreen"
    elif [[ $enabled_count -eq 3 && $hdmi_enabled -eq 0 ]]; then
        echo "triple"
    elif [[ $enabled_count -eq 4 ]]; then
        echo "all"
    else
        echo "unknown"
    fi
}

# Function to get monitor ID by name
get_monitor_id() {
    local monitor_name="$1"
    hyprctl monitors -j | jq -r ".[] | select(.name == \"$monitor_name\") | .id"
}

# Function to wait for a monitor to become available
wait_for_monitor() {
    local monitor_name="$1"
    local max_attempts=20  # 20 * 0.5s = 10 seconds max
    local attempt=0

    echo "Waiting for monitor $monitor_name to become available..."
    while [[ $attempt -lt $max_attempts ]]; do
        if hyprctl monitors -j | jq -e ".[] | select(.name == \"$monitor_name\")" >/dev/null 2>&1; then
            echo "Monitor $monitor_name is now available"
            return 0
        fi
        sleep 0.5
        attempt=$((attempt + 1))
    done

    echo "Warning: Monitor $monitor_name did not become available within 10s" >&2
    return 1
}

# Function to move all clients from source monitor to destination monitor
move_clients_between_monitors() {
    local source_mon="$1"
    local dest_mon="$2"

    echo "Moving clients from $source_mon to $dest_mon..."

    # Get monitor IDs
    local source_id
    source_id=$(get_monitor_id "$source_mon")
    local dest_id
    dest_id=$(get_monitor_id "$dest_mon")

    if [[ -z "$source_id" ]]; then
        echo "Error: Source monitor $source_mon not found (maybe disabled)" >&2
        return 1
    fi
    if [[ -z "$dest_id" ]]; then
        echo "Error: Destination monitor $dest_mon not found (maybe disabled)" >&2
        return 1
    fi

    # Get list of client addresses on source monitor
    local clients
    clients=$(hyprctl clients -j | jq -r ".[] | select(.monitor == $source_id) | .address")

    if [[ -z "$clients" ]]; then
        echo "No clients found on $source_mon"
        return 0
    fi

    # Move each client to destination monitor
    local moved=0
    while IFS= read -r addr; do
        if [[ -n "$addr" ]]; then
            echo "Moving client $addr to monitor $dest_mon"
            if hyprctl dispatch movetomonitor "$dest_mon,address:$addr" 2>/dev/null; then
                moved=$((moved + 1))
            else
                echo "Warning: Failed to move client $addr" >&2
            fi
        fi
    done <<< "$clients"

    echo "Moved $moved client(s) from $source_mon to $dest_mon"
}

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

current_config=$(detect_current_config)
echo "Current configuration detected: $current_config"

case "$1" in
    triple)
        echo "Switching to triple monitor configuration..."
        if [[ ! -f "$TRIPLE_CONF" ]]; then
            echo "Error: Source file $TRIPLE_CONF not found." >&2
            exit 1
        fi

        # If currently on bigscreen, apply intermediate 'all' configuration first
        if [[ "$current_config" == "bigscreen" ]]; then
            echo "Currently on bigscreen, applying intermediate 'all' configuration..."
            if [[ ! -f "$ALL_CONF" ]]; then
                echo "Error: Intermediate configuration file $ALL_CONF not found." >&2
                exit 1
            fi
            cp -f "$ALL_CONF" "$MONITORS_CONF"
            hyprctl reload
            sleep 2
            echo "Waiting for DP-1 monitor to become available..."
            wait_for_monitor "DP-1" || true
            echo "Moving clients from HDMI-A-1 to DP-1..."
            move_clients_between_monitors "HDMI-A-1" "DP-1" || true
        fi

        cp -f "$TRIPLE_CONF" "$MONITORS_CONF"
        ;;
    bigscreen)
        echo "Switching to bigscreen monitor configuration..."
        if [[ ! -f "$BIGSCREEN_CONF" ]]; then
            echo "Error: Source file $BIGSCREEN_CONF not found." >&2
            exit 1
        fi

        # If currently on triple, apply intermediate 'all' configuration first
        if [[ "$current_config" == "triple" ]]; then
            echo "Currently on triple, applying intermediate 'all' configuration..."
            if [[ ! -f "$ALL_CONF" ]]; then
                echo "Error: Intermediate configuration file $ALL_CONF not found." >&2
                exit 1
            fi
            cp -f "$ALL_CONF" "$MONITORS_CONF"
            hyprctl reload
            sleep 2
            echo "Waiting for HDMI-A-1 monitor to become available..."
            wait_for_monitor "HDMI-A-1" || true
            echo "Moving clients from DP monitors to HDMI-A-1..."
            for dp in "DP-1" "DP-2" "DP-3"; do
                move_clients_between_monitors "$dp" "HDMI-A-1" || true
            done
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
