# quickshell/ii

Symlinked from `~/.config/quickshell`. This is the end-4 style Quickshell shell.

## Lock screen temp workspaces (important)

`modules/ii/lock/Lock.qml` parks every monitor on a temporary workspace with a
huge ID (`2147483647 - <saved workspace>`) when locking, and restores each
monitor on unlock. If you touch this logic:

- Restore must be verify-and-retry (read back actual state via
  `HyprlandData.monitors`), never fire-and-forget — a single early batch races
  DPMS wake/unlock and permanently strands monitors on huge-ID workspaces
  (the "absurd workspace number" bug).
- Never save or re-park a workspace whose ID is > 1000000 — that is a temp.
- `services/HyprlandData.qml` deliberately filters workspace IDs to 1..100 to
  hide these temps from the bar; keep that filter in sync.

Hyprland 0.56.x has no `deleteworkspace` dispatcher; leftover empty temp
workspaces can only be cleared by restarting Hyprland.
