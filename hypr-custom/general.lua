-- Custom general config (converted from custom/general.conf)
-- Loaded after hyprland/general.lua, so these values win.

hl.config({
    -- Border configuration - animated gradient on focus
    general = {
        border_size = 4,
        col = {
            active_border   = { colors = { "rgba(7FFFD4FF)", "rgba(00BFFFFF)", "rgba(1E90FFFF)" }, angle = 45 },
            inactive_border = "rgba(333333FF)",
        },
    },

    animations = {
        enabled = true,
    },

    dwindle = {
        preserve_split = false,
        smart_split = false,
        smart_resizing = false,
    },

    -- Disable automatic config reloading - use hyprctl reload instead
    misc = {
        disable_autoreload = true,
        vrr = 0,
        on_focus_under_fullscreen = 0,
    },

    debug = {
        vfr = 0, -- Variable frame rate off - reduces CPU when idle... (kept as in .conf: vfr = 0)
    },

    decoration = {
        rounding = 10,
        active_opacity = 1.00,
        inactive_opacity = 0.92,

        blur = {
            enabled = true,
            size = 3,
            passes = 1,
            vibrancy = 0.17, -- keeps dark themes from looking washed out
        },

        shadow = {
            enabled = false, -- Disable shadows to reduce CPU usage
        },
    },
})

hl.curve("borderTransition", { type = "bezier", points = { { 0.4, 0 }, { 0.2, 1 } } })
hl.animation({ leaf = "border",      enabled = true, speed = 6,   bezier = "borderTransition" })
hl.animation({ leaf = "borderangle", enabled = true, speed = 100, bezier = "default", style = "loop" }) -- clamped from 180 (0.57 max is 100)

hl.device({
    name = "dualsense-wireless-controller-touchpad",
    enabled = false,
})
