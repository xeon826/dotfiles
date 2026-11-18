-- Custom env vars (converted from custom/env.conf)
hl.env("QS_WALLPAPER_FOLDER", "/home/dan/Pictures/papes")
hl.env("PROTON_ENABLE_WAYLAND", "1")
-- NOTE: do NOT put aquamarine vars (AQ_*) here — the DRM backend initializes
-- before config parsing, so hl.env is too late for them (verified 2026-11-18:
-- AQ_NO_MODIFIERS set here never reached capture buffer allocation). Set
-- compositor-level env vars in the launch environment instead.
