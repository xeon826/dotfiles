# quickshell/ii

Symlinked from `~/.config/quickshell`. This is the end-4 style Quickshell shell.

## Icon installs

User icons go in `~/.local/share/icons/hicolor/scalable/apps/`. **Delete
`~/.local/share/icons/hicolor/icon-theme.cache` after adding files** — that
dir has no `index.theme`, so the cache can never be regenerated and GTK/Qt
serve the stale file list from it indefinitely (new icons silently don't
resolve). Verify with a fresh `python3` + `Gtk.IconTheme` lookup, and restart
quickshell to clear its in-memory icon caches. The bar's window list resolves
icons via `AppSearch.guessIcon` (desktop entry by window class → its icon
name), whose own `find` searches `$HOME/.local/share/icons/hicolor` first.

## Hot corners

`modules/ii/screenCorners/ScreenCorners.qml` filters its per-monitor corner
windows by `Config.options.sidebar.cornerOpen.screenList` (empty = all
screens; currently `["DP-3"]` in `~/.config/illogical-impulse/config.json`).
Corner windows also hide while that monitor's active workspace has a
fullscreen window — don't mistake that for the filter misbehaving.

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

## Window list sidebar (`modules/ii/windowList/`)

Super+Tab (or Super+Shift+Tab) toggles a left-docked list of windows grouped
by workspace (`quickshell:windowListToggle`; rows are drag-and-droppable
between sections). Super+Tab previously opened the overview grid — it is
rebound in `custom/keybinds.lua` via `hl.unbind("SUPER + TAB")` + rebind;
Super+R still opens the grid overview.

- **Hyprland 0.57 special workspaces have NO `workspace.id`** in
  `hyprctl clients -j` / `hyprctl workspaces -j` — only
  `address` (`special:browser`) + `name`. Old code assuming negative ids
  silently breaks. `WindowListContent.wsKeyFor()` keys sections by numeric id
  or address accordingly; moves/focuses for specials use
  `workspace="special:browser"` / `{workspace="name:special:browser"}` (verified
  dispatch syntax).
- `StyledToolTip.extraVisibleCondition` defaults to `true` — a tooltip child of
  a plain MouseArea (no `hovered` property) is ALWAYS visible. Always pass
  `extraVisibleCondition: false` when using `alternativeVisibleCondition`.
- The panel window has no fixed `screen`: it opens on the focused monitor.


## Super-hold workspace deck (`modules/ii/bar/WorkspaceDeck.qml`)

While Super is held (`GlobalStates.superDown` → `Workspaces.showNumbers`),
each workspace button's main icon fades and a per-monitor overlay window
(`quickshell:workspaceDeck`) stacks the workspace's windows straight downward
under the bar flush against it — fully opaque icons, edge-to-edge (no overlap
or jitter; user preference), biggest window first, cap 5. Layout facts:

- A PanelWindow CAN be declared nested inside the bar's widget tree
  (`Workspaces.qml` instantiates it via a Loader) — it maps as an independent
  layer surface per monitor. `mask: Region {}` = fully click-through
  (mandatory: Super is held for keybinds), `exclusiveZone: -1`.
- Horizontal alignment comes from `Workspaces.deckGlobalX`
  (`mapToItem(null, 0, 0)` — scene coords == screen coords because the bar
  window spans from screen origin). Snapshot on superDown/showNumbers, not a
  live binding (mapToItem is not reactive).
- The window stays mapped 220ms past hide (`collapseDelay`) so cards animate
  out; cards reveal top→bottom via `Workspaces.revealedCount` ticking.
- **Binding-loop trap:** `AppSearch.windowIconSource()` must never mutate
  `_findQueue` during binding evaluation (read+write of the same property in
  one eval → QML loop detector permanently disables the binding). The
  service defers queueing via `Qt.callLater`; call sites keep per-item
  bindings (one call per button/card). Never call it inside an aggregate
  binding that resolves many windows (that froze `Workspaces.deckCards`
  once) — aggregate bindings there carry window objects only, and each card
  resolves its own icon.
- Multi-file edits race quickshell's hot reload (it reloads per file save;
  intermediate states fail with "Type X unavailable"). After a batch edit,
  `touch` one file and check `qs -p … log` for a clean reload line.

## Overview grid (`modules/ii/overview/`)

Super+R (`quickshell:overviewWorkspacesToggle`) opens one panel per monitor
(`Variants` over `Quickshell.screens` in `Overview.qml`; instance registry on
the Scope for IPC-driven search text). Each panel shows its own workspace
group and only its own windows — the model filter checks `win.monitor ===
monitor.id`; special workspaces (no `workspace.id` in 0.57) stay excluded.
The runner (`SearchWidget`) is instantiated only on the focused monitor's
panel: a `Loader` in `Overview.qml` gated on `Hyprland.focusedMonitor` (perf:
one results rebuild per keystroke instead of one per monitor; keep `active`
independent of `overviewOpen` so IPC clipboard/emoji toggles can prefill a
prefix before the overview opens). On focus change mid-query the runner
migrates — text survives via the shared `LauncherSearch.query` binding,
results reseed in `Component.onCompleted`, and the panel's `searchingText`
resets on loader deactivation so stale text can't keep the layout view
hidden. On open the focus grab may park keyboard on a runner-less panel, so
`Overview.qml` starts `focusRetryTimer`: every 120ms (max ~20 ticks) it pulls
keyboard to the focused panel's runner (`panel.focusRunner()`) until done —
don't drop that or the input sometimes starts unfocused. Note
`GlobalFocusGrab.hasActive()` has been observed returning false even when
focus IS inside the panel, so the timer reliably exhausts its attempts
(harmless no-ops). Gotcha: inside a Loader
`sourceComponent`, a `property alias` referencing the enclosing panel's id
fails to compile (`Invalid alias reference. Unable to find id`) — mirror
panel state with plain bindings declared on the panel instead. Also:
`WlrKeyboardFocus.Exclusive` on the overview panels clears the
HyprlandFocusGrab (`onCleared` → dismiss) — the overview self-closes; keep
keyboard focus `OnDemand`.

Cross-monitor drag & drop: QML DropAreas are scene-local, so
`services/OverviewDnd.qml` polls `hyprctl cursorpos -j` (25ms) while a pill
is dragged; non-origin monitors hit-test their cells and publish
`hoveredTarget {monitor, workspace, pctX, pctY}`; on release the origin
dispatches `hl.dsp.window.move({window=..., workspace=N, monitor="DP-X",
follow=false})` (workspace+monitor combo verified on 0.57), then a second
`{window=..., x=, y=}` dispatch for floating windows — the Lua dsp does NOT
accept x/y together with workspace/monitor. Gotchas: `hyprctl monitors -j`
width/height are physical pixels (logical = /scale), but window `at[]` and
`cursorpos` are already logical; cells register themselves with the widget
root for cursor hit-testing (`Component.onDestruction`, not `onDestroyed`).

Window icons (`OverviewWindow.iconPath`, `Workspaces.mainAppIconSource`) go
through `AppSearch.windowIconSource()`: guessIcon for the name, then a cached
filesystem lookup (`find` over hicolor/Adwaita/pixmaps, svg preferred) served
as a `file://` URL — **never route them through `Quickshell.iconPath`/QIcon**.
On this build (quickshell 0.3.2.r11.g9b0f339 + Qt 6.12.0-3), `QIcon::fromTheme`
goes per-name flaky after every engine reload: the first engine of a fresh
process resolves fine, later engines miss even stock hicolor icons (kitty,
application-x-executable, image-missing) while others (thunderbird) survive —
the 2026-11-16 red-cross saga. Rebuilding the binary does not fix it; the
file:// resolver does. Misses return "" (icon hidden; bar shows dot/number) —
never pass "image-missing" as a fallback there. `DesktopEntries.byId()` is
non-reactive and null until the async scan completes, so `AppSearch.
entriesGeneration` (8×1s bumps after each reload) re-runs icon bindings while
guesses improve.


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
- Encoding uses `-c h264_nvenc -r 60` (GPU NVENC, constant 60 fps) on all four
  wf-recorder invocations — ffmpeg on this box has h264_nvenc.
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
