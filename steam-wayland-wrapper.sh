#!/bin/bash
if [ "$XDG_SESSION_TYPE" = "wayland" ] || [ -n "$WAYLAND_DISPLAY" ]; then
#    gamescope -r 180 --mangoapp --backend sdl --adaptive-sync -f -W 2048 -H 1152 -- "$@"
    # Detect monitor with highest width
    if command -v xrandr >/dev/null 2>&1; then
        read -r W H < <(xrandr --listmonitors | awk '
        NR>1 {
            geom = $3
            split(geom, a, "/")
            width = a[1]
            split(a[2], b, "x")
            split(b[2], c, "/")
            height = c[1]
            if (width > max) {
                max = width
                h = height
            }
        }
        END {
            if (max) print max " " h
        }')
        if [ -z "$W" ] || [ -z "$H" ]; then
            echo "Warning: Failed to detect monitor dimensions, using default 3840x2160"
            W=3840
            H=2160
        fi
    else
        echo "Warning: xrandr not found, using default 3840x2160"
        W=3840
        H=2160
    fi
    SDL_VIDEODRIVER=x11 gamescope -r 180 --mangoapp --backend sdl --adaptive-sync -f -W "$W" -H "$H" -- "$@"
else
    exec "$@"
fi
