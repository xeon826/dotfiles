# Screen capture handoff — Hyprland 0.57.0 + NVIDIA (Nov 2026)

Status summary of the recording-tool saga on this box: two compositor CPU
wedges, one migration (wf-recorder → wl-screenrec), one NVIDIA format
blocker, one pending compositor restart that everything hinges on.

Machine: Arch, Hyprland 0.57.0-1 (Lua config era), nvidia-open 615.78.08,
RTX 4070 Ti, 3× DP monitors (DP-1 rotated 270°, DP-3 scale 1.25). Recording
UI lives in `quickshell/ii` (Super+G → region selector → `record.sh`).

## Current state (TL;DR)

- Hyprland was restarted Nov 18 (~03:12) — the wf-recorder timer wedge is
  cleared (utime 0/s). Don't launch wf-recorder or OBS portal shares; both
  re-enter the buggy `CScreenshareManager`.
- `record.sh` + the quickshell indicator now use **gpu-screen-recorder**
  (official `extra` repo, 6.1.7) — KMS/DRM capture that bypasses the
  compositor entirely, encoding NVENC h264. Verified working: monitor
  capture, region capture, clean SIGINT stop, and compositor independence
  (Hyprland utime ~0 while recording).
- `pidof` name `gpu-screen-recorder` lives in three places:
  `scripts/videos/record.sh`, `services/ScreenRecorder.qml`,
  `modules/ii/regionSelector/RegionSelection.qml` — keep in sync.
- wl-screenrec remains installed but **unusable on this NVIDIA box**
  (dmabuf format blocker) — and `hl.env("AQ_NO_MODIFIERS")` was removed:
  it never reaches aquamarine (DRM backend inits before config parsing).
  Reviving it requires setting the var pre-launch (environment.d / shell
  profile) and accepting compositor-wide linear buffers.
- History of this saga: wf-recorder → wl-screenrec → gpu-screen-recorder.
  Full details below.

## Wedge 1 — OBS portal share, render-loop spin (Nov 14)

Trigger: OBS used a xdg-desktop-portal-hyprland region screencast on DP-3
and OBS exited while still streaming. Symptom: main thread pinned ~97%
utime, indefinitely. Restarting portals/pipewire and cycling monitors did
NOT clear it — a stale compositor-side pending frame kept a copy-FB pass
running on every commit, bypassing monitor frame pacing (unthrottled
render loop, fence/fd churn).

- Code path: `CScreenshareManager::outputCopyFBState()` — a frame that is
  `m_shared && !done()` gets copied on every `onOutputCommit` forever.
- Only known cure: restart the Hyprland session.
- gdb injection was attempted once and **corrupted the process** (stripped
  binary, no DWARF) — never again; read-only eu-stack/strace (sudo) is fine.
- Not fixed upstream as of 0.57.0; portal path goes through the same
  `CScreenshareManager`, so OBS is not a safe alternative either.

## Wedge 2 — wf-recorder launch, event-loop timerfd spin (Nov 18)

Trigger: launching wf-recorder (any wlr-screencopy client). CPU jumped to
~100% single-core within a minute and persists after the client exits.
Live-captured stack:

```
CEventLoopTimer::leftUs() ← CEventLoopManager::nudgeTimers()
  ← wl_event_loop_dispatch_idle ← wl_display_run ← enterLoop()
```

Root cause (verified against v0.57.0 source): an expired
`CEventLoopTimer` stranded at exactly 2 strong refs is never fired
(guard `>2`) and never erased (guard `<=1`) in `onTimerFire`, so
`nudgeTimers()` keeps re-arming the shared timerfd at +1µs → endless
timerfd/idle loop. Prime suspect: the screencopy session stop-timer
(`m_shareStopTimer`), which `CScreenshareSession::stop()` never cancels.

- Refs: `EventLoopTimer.cpp:46-51` (negative `leftUs`, no clamp),
  `EventLoopManager.cpp:145/195/197-204` (fire/erase gap + 1µs clamp),
  `ScreenshareSession.cpp:86-122`, `ScreenshareFrame.cpp:194`.
- Upstream: no report exists (Hyprland issues redirect to Discussions);
  no fix in 0.57.1/0.57.2. Partial mitigation `1bf62857f` (PR #16983)
  sits on main only, not backported. Filing a Discussion with the stack
  is still worthwhile.

Both wedges share the family: Hyprland 0.57's `CScreenshareManager` (the
wlr-screencopy implementation) leaks/pend-wedges on client lifecycle
edges. 0.57 rewrote the capture pipeline and deprecated wlr-screencopy.

## Tool-by-tool

### wf-recorder 0.6.0 — works, but poisons the compositor

Feature-wise it was fine here (NVENC via ffmpeg's CPU→CUDA upload — no
VA-API needed; `-g` global-logical geometry; `--audio=<sink>.monitor`).
But its wlr-screencopy path triggers wedge 2, and any other
wlr-screencopy client can too. Its ext-image-copy-capture port is
unmerged (wf-recorder #273, PR #347). Verdict: unusable until Hyprland
fixes the timer bug or wf-recorder ships the new protocol.

### wl-screenrec 0.3.2 (AUR) — protocol-safe, hard-blocked on NVIDIA

Right idea: defaults to ext-image-copy-capture, bypassing
`CScreenshareManager` entirely; near-free capture (damage-driven, ~2.5%
CPU vs wf-recorder's ~500%); graceful stop. But on this NVIDIA-only box
it is **unusable, even after the restart**:

- Its hardware path is VA-API (+ experimental Vulkan) — **no NVENC, ever**.
- It is **dmabuf-only** (no wl_shm support) and its negotiation requires
  LINEAR modifiers + XRGB-family fourccs. Hyprland/NVIDIA GBM offers
  capture dmabufs only with NVIDIA_BLOCK_LINEAR modifiers → instant
  `Failed to negotiate format` on every capture backend (upstream #149,
  open). The Vulkan path is rejected by the driver too (its own modifiers
  fail `vkGetPhysicalDeviceImageFormatProperties2`).
- `hl.env("AQ_NO_MODIFIERS", "1")` in the Lua config does **not** work:
  aquamarine's DRM backend initializes before config parsing, so the var
  never reaches buffer allocation (verified empirically post-restart —
  capture dmabufs still block-linear only). It was removed from
  `hypr-custom/env.lua`. Reviving wl-screenrec needs the var in the
  pre-launch session environment (e.g. `~/.config/environment.d/`), at
  the cost of compositor-wide linear DRM buffers.

### gpu-screen-recorder 6.1.7 — the chosen tool (official `extra` repo)

KMS/DRM capture via the setcap'd `gsr-kms-server` helper (`cap_sys_admin`,
no password prompts) — **bypasses the compositor entirely**; the author:
"it bypasses the wayland compositor with root access." Structurally immune
to both wedge families and to any future compositor capture regression.

- NVENC h264 by default (also HEVC/AV1, Vulkan-encode variants), replay
  buffer, streaming. First install wants one reboot for `gsr-nvidia.conf`
  (CUDA suspend fix).
- Verified here: `-w DP-3` monitor capture (2560x1440@60), `-w region
  -region WxH+X+Y` region capture (coords global logical, must lie within
  ONE monitor; output is the physical-px crop — 500x400 logical at scale
  1.25 → 626x500), `pkill -SIGINT` clean stop, exit 0.
- Compositor independence verified: Hyprland utime ~0 during recording.
- Trade-offs: whole-monitor KMS capture per output (no Wayland window
  capture), a root-capable framebuffer helper on the system, no region
  capture across monitor boundaries. `gpu-screen-recorder-ui` (not
  installed) adds ShadowPlay-style overlay/hotkeys/replay.

### OBS / portal (xdg-desktop-portal-hyprland) — not safe

Portal screencast routes through the same `CScreenshareManager` — it
caused wedge 1. Live recording might be fine, exit-during-stream is the
killer; not a recommended alternative.

### gpu-screen-recorder — see previous section (chosen tool)

~~untested fallback~~ — tested and adopted Nov 18; see above.

## record.sh mechanics (post-migration)

- Start paths: fullscreen `-w <monitor> -f 60`; region `-w region -region
  WxH+X+Y` (record.sh converts slurp-format `X,Y WxH` into `$gsrRegion`).
  Audio adds `-a "$(pactl get-default-sink).monitor"` (exactly one source;
  never enumerate all monitor sources).
- `start_recorder()` wrapper: recorder exits <2s → state file removed +
  "Recording failed" notification (catches gsr's exit-51 bad-region case
  and any other instant death).
- The region's monitor (`--screen` from the selector, or `getregionmonitor`
  for the slurp/CLI path) is only used for the indicator state file —
  gsr derives the monitor from the region itself.
- Stop = re-run record.sh bare (pgrep branch → `pkill -INT -f
  '^gpu-screen-recorder'`; SIGINT is gsr's documented clean stop, exit 0,
  MP4 finalized). Also overlay Stop button or Super+Shift+Ctrl+R.
- The `pidof` name `gpu-screen-recorder` lives in three places — record.sh,
  `services/ScreenRecorder.qml`, `RegionSelection.qml`
  (`checkRecordingProc`) — keep in sync.
- Unverified: recordings of rotated DP-1 with gsr (KMS grabs scanout
  directly so it should be rotation-correct, but check the first DP-1
  recording; wf-recorder used to produce transposed output).

## Next steps

1. Test Super+G region recording end-to-end via the selector UI (the CLI
   path is verified); check the file lands in ~/Videos and is playable;
   then test a DP-1 (rotated) capture.
2. Optional: install `gpu-screen-recorder-ui` for ShadowPlay-style
   overlay/hotkeys/instant replay.
3. Optional upstream filing: Hyprland Discussion for wedge 2 (stack +
   code refs are in the home brain guide at `/home/dan/.operator/guides/
   hyprland-0.57-screencopy-wedge.md`); a comment on wl-screenrec #149.
4. Consider uninstalling wf-recorder to prevent accidental wedge
   re-trigger, or at least don't bind it anywhere.
5. If wl-screenrec is ever wanted again: set `AQ_NO_MODIFIERS=1` in the
   pre-launch session environment (environment.d / shell profile), accept
   compositor-wide linear buffers, and re-test — see the wl-screenrec
   section above.

## References

- Hyprland Discussions/issues: #15697 (wf-recorder CPU, closed non-repro),
  #16707/#16802 (0.57 screencopy transform regressions), #16801 (RT-spin
  confounder, fixed in 0.57.2), PRs #16333/#16361 (pre-release screencopy
  block fixes), #16983 + `1bf62857f` (event-loop partial mitigation, main only).
- wl-screenrec: #149 (format negotiation, open), #95 (Vulkan video, open),
  #273/PR#347 (wf-recorder ext-copy port).
- xdph: PR #424 (portal buffer-freeze fix), issues #403/#434/#147.
- Deeper diagnostics: `.operator/guides/hyprland-0.57-screencopy-wedge.md`
  in the home project brain (`/home/dan/.operator/`), incl. the gdb
  pitfalls and evidence-collection methods (eu-stack/strace/utime).
