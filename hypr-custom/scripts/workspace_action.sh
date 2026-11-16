#!/usr/bin/env bash
# workspace_action.sh <movetoworkspace|movetoworkspacesilent|workspace> <target>
#
# Hyprland >= 0.57 (Lua-config era): `hyprctl dispatch <name> <arg>` no longer
# accepts legacy dispatcher-name strings — the argument is spliced into Lua as
# `return hl.dispatch(<arg>)`, so we emit hl.dsp.* dispatcher expressions.
# This is the canonical copy; dotbot links it over the framework file at
# ~/.config/hypr/hyprland/scripts/workspace_action.sh (re-link after a
# framework re-sync with `./install`, or it just works since relink: true).

set -u

if (( $# < 2 )) || [[ "${1}" == "-h" || "${1}" == "--help" ]]; then
  echo "Usage: $0 <movetoworkspace|movetoworkspacesilent|workspace> <target>"
  exit 1
fi

action="$1"
shift

case "${action}" in
  movetoworkspacesilent) expr='hl.dsp.window.move({workspace=%S, follow=false})' ;;
  movetoworkspace)       expr='hl.dsp.window.move({workspace=%S})' ;;
  workspace)             expr='hl.dsp.focus({workspace=%S})' ;;
  *)
    echo "workspace_action.sh: unknown dispatcher '${action}'" >&2
    exit 1
    ;;
esac

target="$1"

# Plain numbers get the monitor-group treatment: workspace N within the group
# of ten owning the active workspace (1-10, 11-20, ...).
if [[ "${target}" =~ ^[0-9]+$ ]]; then
  curr_workspace="$(hyprctl activeworkspace -j | jq -r '.id')"
  if ! [[ "${curr_workspace}" =~ ^[0-9]+$ ]]; then
    echo "workspace_action.sh: could not read active workspace" >&2
    exit 1
  fi
  lua_target=$((((curr_workspace - 1) / 10) * 10 + target))
else
  # r+1 / +1 / -1 / special:name etc. — pass through as a Lua string literal.
  lua_target="'${target}'"
fi

out="$(hyprctl dispatch "${expr/\%S/${lua_target}}" 2>&1)"
rc=$?
if (( rc != 0 )); then
  echo "workspace_action.sh: hyprctl dispatch failed (rc=${rc}): ${out}" >&2
fi
exit $rc
