# hypr-custom

`~/.config/hypr/custom` → this directory. Loaded by `~/.config/hypr/hyprland.lua`
(symlinked from `~/dotfiles/hyprland.lua`) AFTER the framework files in
`~/.config/hypr/hyprland/`, so overrides here win.

## Hyprland 0.57 Lua era (important)

- 0.57 removed hyprlang: **`hyprland.conf` / `monitors.conf` are NOT read by
  Hyprland anymore.** The live monitor config is `~/.config/hypr/monitors.lua`
  (dofile'd from hyprland.lua); `monitors.conf` remains only as
  `switch-monitors.sh` state + nwg-displays compatibility.
- `hyprctl dispatch <expr>` splices the argument into Lua
  (`hl.dsp.*` expressions), and is **async** — it returns before the effect
  lands; scripts must not re-read compositor state immediately after.
- `hyprctl workspacerules` and `hyprctl configerrors -j` are the verification
  tools for rules/config; `hyprctl monitors all -j` includes disabled outputs.

## Decade workspace scheme

Workspaces are pinned per monitor in decades by `decades.lua` (dofile'd from
hyprland.lua). `scripts/workspace_action.sh` computes `((curr-1)/10)*10 + n`
for plain-number targets — it only behaves correctly when the decade rules
exist. Per mode:

| Mode | Decades |
|---|---|
| triple | DP-2 (left): 1–10 · DP-3 (center): 11–20 · DP-1 (portrait): 21–30 |
| all | same + HDMI-A-1 (TV): 31–40 |
| bigscreen | HDMI-A-1: 1–10 |

- Never hand-edit `decades.lua` — it is overwritten by `switch-monitors.sh`.
  Edit the per-mode templates in `scripts/switch-monitors/*.decades.lua`.
- To change the live decades without switching modes: copy the template over
  `decades.lua` then `hyprctl reload`.

## switch-monitors.sh (triple/bigscreen/all)

Canonical copy lives here (symlinked from `~/.local/bin/switch-monitors.sh`);
CONFIG_DIR resolves through the symlink, so all paths below work.

- Since 0.57 it writes BOTH `monitors.conf` (state/nwg-displays) and
  `monitors.lua` (live), converting via `scripts/switch-monitors/conf_to_lua.py`
  (keep one source of truth: edit the `*.monitors.conf` templates, never the
  generated `.lua`).
- Sets the matching decade template per mode (see above) before the reload.
- Templates were synced to the live layout on 2026-11-16 (DP-2 had been
  rotated portrait @100Hz in the stale versions). After real monitor changes,
  regenerate with nwg-displays and re-sync the templates, or the next switch
  will restore a stale layout.
- Bigscreen↔triple goes through an intermediate `all` step (client relocation
  via `hl.dsp.window.move`).
- Do not live-test mode switching casually: it reloads monitors and moves
  every window. Verify with `bash -n` + converting templates to /tmp instead.

## Other 3-monitor conventions

- Fullscreen screenshot binds (PRINT / CTRL+PRINT in `keybinds.lua`) capture
  the **focused monitor only** (`grim -o "$(hyprctl monitors -j | jq -r
  '.[] | select(.focused) | .name')"`) — plain `grim` stitches all monitors.
- `execs.lua` starts `wayvnc -o DP-3` — wayvnc grabs one output; pin it.
  Switch at runtime with `wayvncctl`.
- `hyprlock.conf` renders the lock screen on every monitor but pins the
  input field to `monitor = DP-3`.
- Quickshell hot corners (`sidebar.cornerOpen.screenList`) are limited to
  DP-3 — configured on the quickshell side (see `quickshell/ii/AGENTS.md`).
