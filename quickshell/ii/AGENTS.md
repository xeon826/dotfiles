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

## Screen recording (`scripts/videos/record.sh`)

wf-recorder 0.6.x on this 3-monitor setup (DP-1 rotated 270°, DP-3 scale 1.25):

- `-o` is always required; without it wf-recorder prompts interactively and
  detached runs (no stdin) die instantly, producing no file.
- `-g/--geometry <x,y WxH>` expects **global logical** coords (slurp-style): it
  validates the region against the output's global rect and fails silently to
  full-output capture on mismatch. Monitor-local or scaled coords will not crop.
- The quickshell region selector therefore sends global logical coords
  (`RegionSelection.qml` offsets by `monitorOffset`) plus `--screen <name>`;
  record.sh uses `--screen` for `-o` directly, and `getregionmonitor` only for
  the slurp/CLI path. Screenshot crops keep monitor-local scaled coords.
- Audio must be exactly one source: `pactl get-default-sink.monitor` — never
  enumerate all monitor sources (AudioRelay/pw-loopback add several).
- Recordings of transformed (rotated) monitors come out transposed with no
  rotation metadata (DP-1 → e.g. 400x500 for a 500x400 region). wf-recorder
  0.6.0's `-F transpose=…` is unreliable here (transpose=2 produced
  byte-identical output). Unfixed; would need post-encode rotation metadata.
- `snip()` dismisses the selector on every monitor for all actions. The
  dashed-border indicator is `RecordingIndicator.qml` (per-screen, click-through),
  driven by `services/ScreenRecorder.qml`, which polls `pidof wf-recorder` and
  `$XDG_RUNTIME_DIR/quickshell-recorder-state.json` — the state file that
  record.sh writes on start (`write_state`: monitor + global logical region,
  whole monitor rect for fullscreen) and removes on stop. wf-recorder is
  stopped by re-running record.sh bare (pgrep branch) — overlay Stop button,
  Super+Shift+Ctrl+R (`record.sh --stop`), or any record trigger while live.
