#!/usr/bin/env bash
# Wrapper for the raw Helium (Chromium fork) binary at /usr/local/bin/helium.
# Upstream Helium reads no flags file (imputnet/helium-linux#152), so
# compatibility flags are pinned here. Dotbot links this to
# ~/.local/bin/helium, which shadows /usr/local/bin/helium because
# ~/.local/bin precedes /usr/local/bin in PATH.
#
# --disable-features=OzoneBubblesUsePlatformWidgets:
#   Browser bubbles (dropdowns, permission prompts) render as separate
#   subsurfaces that don't receive pointer input on Hyprland/Wayland
#   (imputnet/helium-linux#359).
#
# Related Hyprland cursor-shape bugs (not flag-fixable):
#   hyprwm/Hyprland#5836, hyprwm/Hyprland discussions #13328
exec /usr/local/bin/helium --ozone-platform-hint=auto \
  --disable-features=OzoneBubblesUsePlatformWidgets "$@"
