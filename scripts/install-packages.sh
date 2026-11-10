#!/usr/bin/env bash
# Install native + AUR packages from the committed package lists.
# Native: pacman -T diff -> only missing packages get installed.
# AUR:    requires paru (or yay); installs everything listed (no -T diff for AUR).
set -euo pipefail
cd "$(dirname "$0")/.."

step() { printf '\n==> %s\n' "$*"; }

step "Native packages (packages.txt)"
if command -v pacman >/dev/null; then
    missing=$(comm -23 <(sort packages.txt) <(pacman -Qq | sort))
    if [ -n "$missing" ]; then
        # shellcheck disable=SC2086
        sudo pacman -S --needed $missing
    else
        echo "All native packages already installed."
    fi
else
    echo "pacman not found; skipping native package install."
    exit 0
fi

step "AUR packages (packages-alt.txt)"
aur_helper=""
for h in paru yay; do
    command -v "$h" >/dev/null && { aur_helper="$h"; break; }
done
if [ -z "$aur_helper" ]; then
    echo "No AUR helper (paru/yay) found. Install one first, or run manually:"
    echo "  paru -S --needed - < packages-alt.txt"
    exit 0
fi
missing_aur=$(comm -23 <(sort packages-alt.txt) <(pacman -Qq | sort))
if [ -n "$missing_aur" ]; then
    # shellcheck disable=SC2086
    "$aur_helper" -S --needed $missing_aur
else
    echo "All AUR packages already installed."
fi

echo "Package install complete."
