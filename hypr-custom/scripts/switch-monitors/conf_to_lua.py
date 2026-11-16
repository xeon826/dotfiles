#!/usr/bin/env python3
"""Convert a nwg-displays monitors.conf into Hyprland 0.57 Lua form (monitors.lua).

hyprlang (.conf) is gone in 0.57; the live config is hyprland.lua, which
dofiles ~/.config/hypr/monitors.lua. Same-output hl.monitor calls merge
(later calls keep earlier keys and overwrite the ones they pass), so
flag-style lines (`NAME,transform,N`, `NAME,disable`) become extra calls
on top of the base rule — same net effect as the legacy replace semantics.
"""
import sys

STR_KEYS = {"mirror", "cm", "icc", "sdr_eotf", "sdrbrightness", "sdrsaturation"}
INT_KEYS = {"transform", "vrr", "bitdepth"}


def lua_str(s: str) -> str:
    return '"' + s.replace("\\", "\\\\").replace('"', '\\"') + '"'


def emit_call(out, name, fields):
    parts = [f"output = {lua_str(name)}"]
    parts += [f"{k} = {v}" for k, v in fields]
    out.append("hl.monitor({ " + ", ".join(parts) + " })")


def convert(text: str) -> str:
    out = [
        "-- Generated from the matching *.monitors.conf by conf_to_lua.py",
        "-- (invoked by switch-monitors.sh). Do not edit by hand — edit the",
        "-- template and re-run switch-monitors.sh, or regenerate with nwg-displays.",
    ]
    for raw in text.splitlines():
        line = raw.strip()
        if not line:
            out.append("")
            continue
        if line.startswith("#"):
            out.append("-- " + line.lstrip("# ").strip())
            continue
        if not line.startswith("monitor="):
            continue
        tokens = [t.strip() for t in line[len("monitor="):].split(",") if t.strip()]
        if len(tokens) < 2:
            continue
        name, rest = tokens[0], tokens[1:]
        if rest[0] in ("disable", "disabled"):
            emit_call(out, name, [("disabled", "true")])
            continue
        if len(rest) == 2 and rest[0] in INT_KEYS | STR_KEYS:
            key, val = rest
            if key in INT_KEYS:
                val = str(int(float(val)))
            else:
                val = lua_str(val)
            emit_call(out, name, [(key, val)])
            continue
        # Base line: NAME,MODE,POS,SCALE[,key,val]...
        fields = [
            ("mode", lua_str(rest[0])),
            ("position", lua_str(rest[1])),
            ("scale", rest[2]),
        ]
        pairs = rest[3:]
        for j in range(0, len(pairs) - 1, 2):
            key, val = pairs[j], pairs[j + 1]
            if key in INT_KEYS:
                val = str(int(float(val)))
            elif key in STR_KEYS:
                val = lua_str(val)
            fields.append((key, val))
        emit_call(out, name, fields)
    return "\n".join(out) + "\n"


if __name__ == "__main__":
    if len(sys.argv) != 2:
        print(f"Usage: {sys.argv[0]} <monitors.conf>", file=sys.stderr)
        sys.exit(1)
    with open(sys.argv[1]) as f:
        sys.stdout.write(convert(f.read()))
