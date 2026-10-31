-- Custom keybinds (converted from custom/keybinds.conf)
-- Loaded after hyprland/keybinds.lua; unbinds below must match the key strings
-- used there exactly (hl.unbind is case-sensitive).

local dsp = hl.dsp

hl.bind("CTRL + SUPER + SLASH", dsp.exec_cmd("xdg-open ~/.config/illogical-impulse/config.json"),
    { description = "Edit shell config" })
hl.bind("CTRL + SUPER + ALT + SLASH", dsp.exec_cmd("xdg-open ~/.config/hypr/custom/keybinds.conf"),
    { description = "Edit extra keybinds" })

-- Add stuff here
-- Use a `description` flag to add an entry on the cheatsheet

hl.unbind("SUPER + SHIFT + L") -- unbind suspend system

hl.unbind("SUPER + O")
hl.unbind("SUPER + CTRL + O")
hl.bind("SUPER + CTRL + O", dsp.window.move({ monitor = "+1" })) -- Send focused window to next monitor
hl.bind("SUPER + O", dsp.window.move({ monitor = "-1" }))        -- Send focused window to previous monitor
hl.bind("SUPER + CTRL + J", dsp.focus({ monitor = "+1" })) -- Focus next monitor
hl.bind("SUPER + CTRL + K", dsp.focus({ monitor = "-1" })) -- Focus previous monitor

hl.unbind("SUPER + L") -- unbind lock screen

hl.unbind("SUPER + H")
hl.unbind("SUPER + L")
hl.unbind("SUPER + K")
hl.unbind("SUPER + J")

hl.bind("SUPER + H", dsp.focus({ direction = "left" }))
hl.bind("SUPER + L", dsp.focus({ direction = "right" }))
hl.bind("SUPER + K", dsp.focus({ direction = "up" }))
hl.bind("SUPER + J", dsp.focus({ direction = "down" }))

hl.unbind("SUPER + LEFT")
hl.unbind("SUPER + RIGHT")
hl.unbind("SUPER + UP")
hl.unbind("SUPER + DOWN")

hl.unbind("SUPER + LEFT")
hl.unbind("SUPER + RIGHT")
hl.unbind("SUPER + UP")
hl.unbind("SUPER + DOWN")

hl.bind("SUPER + RIGHT", dsp.focus({ workspace = "r+1" }))
hl.bind("SUPER + LEFT",  dsp.focus({ workspace = "r-1" }))
hl.bind("SUPER + CTRL + D", dsp.focus({ workspace = "r+1" }))
hl.bind("SUPER + CTRL + A", dsp.focus({ workspace = "r-1" }))
hl.bind("SUPER + BRACKETRIGHT", dsp.focus({ workspace = "r+1" }))
hl.bind("SUPER + BRACKETLEFT",  dsp.focus({ workspace = "r-1" }))

hl.bind("SUPER + ALT + J", dsp.global("quickshell:barToggle"),
    { description = "Toggle bar" })

hl.unbind("CTRL + ALT + T")

hl.unbind("SUPER + SHIFT + C")
hl.bind("SUPER + SHIFT + G", dsp.exec_cmd("hyprpicker -a"),
    { description = "Color picker" }) -- Pick color (Hex) >> clipboard

hl.bind("SUPER + SHIFT + C", dsp.window.close()) -- Close

hl.bind("CTRL + ALT + I", dsp.exec_cmd("kitty ncmpcpp")) -- Open ncmpcpp in kitty terminal

-- unbind framework workspace-send binds on raw keycodes, then rebind via the script
for i = 1, 10 do
    hl.unbind("SUPER + ALT + code:" .. (9 + i))
end
for _, k in ipairs({ "code:87", "code:88", "code:89", "code:83", "code:84", "code:85", "code:79", "code:80", "code:81", "code:90" }) do
    hl.unbind("SUPER + ALT + " .. k)
end

for i = 1, 10 do
    hl.bind("SUPER + SHIFT + code:" .. (9 + i),
        dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent " .. i))
end
for i, k in ipairs({ "code:87", "code:88", "code:89", "code:83", "code:84", "code:85", "code:79", "code:80", "code:81", "code:90" }) do
    hl.bind("SUPER + SHIFT + " .. k,
        dsp.exec_cmd("~/.config/hypr/hyprland/scripts/workspace_action.sh movetoworkspacesilent " .. i))
end

hl.unbind("SUPER + ALT + S")
hl.unbind("SUPER + SHIFT + S")
hl.bind("SUPER + SHIFT + S", dsp.window.move({ workspace = "special:special", follow = false })) -- Send to scratchpad
hl.unbind("SUPER + SHIFT + Z")
hl.bind("SUPER + SHIFT + Z", dsp.window.move({ workspace = "special:browser", follow = false })) -- Send to scratchpad

hl.bind("SUPER + ALT + S", dsp.global("quickshell:regionScreenshot")) -- Screen snip
hl.bind("SUPER + ALT + S", dsp.exec_cmd("qs -p " .. QS_PATH .. " ipc call TEST_ALIVE || pidof slurp || hyprshot --freeze --clipboard-only --mode region --silent")) -- [hidden] Screen snip (fallback)

-- Switch between clients (next/previous)
hl.bind("SUPER + SHIFT + H", dsp.window.swap({ direction = "left" }))
hl.bind("SUPER + SHIFT + L", dsp.window.swap({ direction = "right" }))
hl.bind("SUPER + SHIFT + K", dsp.window.swap({ direction = "up" }))
hl.bind("SUPER + SHIFT + J", dsp.window.swap({ direction = "down" }))

hl.unbind("SUPER + C")
hl.bind("SUPER + C", dsp.workspace.toggle_special("opencode"))

hl.bind("SUPER + Z", dsp.workspace.toggle_special("browser"))

hl.bind("SUPER + R", dsp.global("quickshell:overviewWorkspacesToggle")) -- Toggle overview

hl.bind("SUPER + ALT + L", dsp.exec_cmd("loginctl lock-session"), { description = "Lock" })

hl.bind("SUPER + P", dsp.exec_cmd("hyprfreeze -a --debug &>> ~/Documents/hyprfreeze_output"))

hl.unbind("SUPER + RETURN")

hl.bind("SUPER + RETURN", dsp.exec_cmd("~/.config/hypr/custom/scripts/launch_first_available.sh \"${TERMINAL}\" \"kitty -1\" \"foot\" \"alacritty\" \"wezterm\" \"konsole\" \"kgx\" \"uxterm\" \"xterm\"")) -- Terminal

hl.bind("SUPER + ALT + T", dsp.exec_cmd("~/.local/bin/switch-monitors.sh triple"))
hl.bind("SUPER + ALT + B", dsp.exec_cmd("~/.local/bin/switch-monitors.sh bigscreen"))

hl.bind("SUPER + PERIOD", dsp.focus({ workspace = "r+1" }), { locked = true })
hl.bind("SUPER + COMMA",  dsp.focus({ workspace = "r-1" }), { locked = true })
