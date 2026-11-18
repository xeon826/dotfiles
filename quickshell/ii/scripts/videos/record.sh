#!/usr/bin/env bash

CONFIG_FILE="$HOME/.config/illogical-impulse/config.json"
JSON_PATH=".screenRecord.savePath"
STATE_FILE="${XDG_RUNTIME_DIR:-/tmp}/quickshell-recorder-state.json"

CUSTOM_PATH=$(jq -r "$JSON_PATH" "$CONFIG_FILE" 2>/dev/null)

RECORDING_DIR=""

if [[ -n "$CUSTOM_PATH" ]]; then
    RECORDING_DIR="$CUSTOM_PATH"
else
    RECORDING_DIR="$HOME/Videos" # Use default path
fi

getdate() {
    date '+%Y-%m-%d_%H.%M.%S'
}
getaudiooutput() {
    # Exactly one source: the default sink's monitor. Enumerating all monitor
    # sources would feed gsr extra/invalid -a audio inputs.
    echo "$(pactl get-default-sink).monitor"
}
getactivemonitor() {
    hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name'
}
getregionmonitor() {
    # Only used to publish the indicator state file — the recorder itself gets
    # the region via -g (slurp-compatible, global logical) and needs no output.
    # Region is "X,Y WxH" in global logical coords; hyprctl width/height are
    # physical px, so /scale.
    local rx ry monitor
    rx="${1%%,*}"
    ry="${1#*,}"
    ry="${ry%% *}"
    monitor="$(hyprctl monitors -j | jq -r --argjson rx "$rx" --argjson ry "$ry" \
        '[.[] | select(($rx >= .x) and ($rx < .x + (.width / .scale)) and ($ry >= .y) and ($ry < .y + (.height / .scale)))][0].name // empty' 2>/dev/null)"
    echo "${monitor:-$(getactivemonitor)}"
}
write_state() {
    # Publish {monitor,x,y,w,h} (global logical coords) for the shell's
    # recording indicator; the ScreenRecorder service polls this file.
    jq -n --arg m "$1" --argjson x "$2" --argjson y "$3" --argjson w "$4" --argjson h "$5" \
        '{monitor:$m,x:$x,y:$y,w:$w,h:$h}' > "$STATE_FILE" 2>/dev/null
}

start_recorder() {
    # The recorder dies fast on capture errors (gsr exits 51 when a region
    # doesn't lie within one monitor). Detect that, clean up the indicator
    # state and say so instead of a silent no-op.
    local t0=$SECONDS
    "$@"
    if (( SECONDS - t0 < 2 )); then
        rm -f "$STATE_FILE"
        notify-send "Recording failed" "Recorder exited immediately (bad region or capture setup)" -a 'Recorder' & disown
    fi
}

mkdir -p "$RECORDING_DIR"
cd "$RECORDING_DIR" || exit

# parse --region <value> without modifying $@ so other flags like --fullscreen still work
ARGS=("$@")
MANUAL_REGION=""
SOUND_FLAG=0
STOP_FLAG=0
FULLSCREEN_FLAG=0
SCREEN_FLAG=""
for ((i=0;i<${#ARGS[@]};i++)); do
    if [[ "${ARGS[i]}" == "--region" ]]; then
        if (( i+1 < ${#ARGS[@]} )); then
            MANUAL_REGION="${ARGS[i+1]}"
        else
            notify-send "Recording cancelled" "No region specified for --region" -a 'Recorder' & disown
            exit 1
        fi
    elif [[ "${ARGS[i]}" == "--sound" ]]; then
        SOUND_FLAG=1
    elif [[ "${ARGS[i]}" == "--stop" ]]; then
        STOP_FLAG=1
    elif [[ "${ARGS[i]}" == "--fullscreen" ]]; then
        FULLSCREEN_FLAG=1
    elif [[ "${ARGS[i]}" == "--screen" ]]; then
        if (( i+1 < ${#ARGS[@]} )); then
            SCREEN_FLAG="${ARGS[i+1]}"
            i=$((i+1))
        fi
    fi
done

if pgrep -f '^gpu-screen-recorder' > /dev/null; then
    rm -f "$STATE_FILE"
    notify-send "Recording Stopped" "Stopped" -a 'Recorder' &
    pkill -INT -f '^gpu-screen-recorder' &
elif [[ $STOP_FLAG -eq 1 ]]; then
    rm -f "$STATE_FILE"
    notify-send "Recorder" "No recording in progress" -a 'Recorder' & disown
    exit 0
else
    if [[ $FULLSCREEN_FLAG -eq 1 ]]; then
        fullscreenMonitor="$(getactivemonitor)"
        # Publish whole-monitor rect (global logical) for the indicator
        rect="$(hyprctl monitors -j | jq -r --arg n "$fullscreenMonitor" \
            '.[] | select(.name == $n) | "\(floor(.x)) \(floor(.y)) \(floor(.width / .scale)) \(floor(.height / .scale))"')"
        read -r fx fy fw fh <<< "$rect"
        write_state "$fullscreenMonitor" "$fx" "$fy" "$fw" "$fh"
        notify-send "Starting recording" 'recording_'"$(getdate)"'.mp4' -a 'Recorder' & disown
        if [[ $SOUND_FLAG -eq 1 ]]; then
            start_recorder gpu-screen-recorder -w "$fullscreenMonitor" -f 60 -o './recording_'"$(getdate)"'.mp4' -a "$(getaudiooutput)"
        else
            start_recorder gpu-screen-recorder -w "$fullscreenMonitor" -f 60 -o './recording_'"$(getdate)"'.mp4'
        fi
    else
        # If a manual region was provided via --region, use it; otherwise run slurp as before.
        if [[ -n "$MANUAL_REGION" ]]; then
            region="$MANUAL_REGION"
        else
            if ! region="$(slurp 2>&1)"; then
                notify-send "Recording cancelled" "Selection was cancelled" -a 'Recorder' & disown
                exit 1
            fi
        fi

        notify-send "Starting recording" 'recording_'"$(getdate)"'.mp4' -a 'Recorder' & disown
        if [[ -n "$SCREEN_FLAG" ]]; then
            # Region came from the quickshell selector: already global logical
            # coords, and the screen is known.
            regionMonitor="$SCREEN_FLAG"
        else
            # Region came from slurp (global logical coords): find its monitor.
            regionMonitor="$(getregionmonitor "$region")"
        fi
        # Publish region state (global logical coords) for the indicator
        regionXY="${region%% *}"; wh="${region##* }"
        rx="${regionXY%%,*}"; ry="${regionXY#*,}"
        rw="${wh%%x*}"; rh="${wh#*x}"
        write_state "$regionMonitor" "$rx" "$ry" "$rw" "$rh"
        # gsr wants X11-style geometry WxH+X+Y (global logical, same coords as
        # slurp); must lie within one monitor — cross-monitor regions exit 51
        # and get caught by start_recorder.
        gsrRegion="${wh}+${regionXY/,/+}"
        if [[ $SOUND_FLAG -eq 1 ]]; then
            start_recorder gpu-screen-recorder -w region -region "$gsrRegion" -f 60 -o './recording_'"$(getdate)"'.mp4' -a "$(getaudiooutput)"
        else
            start_recorder gpu-screen-recorder -w region -region "$gsrRegion" -f 60 -o './recording_'"$(getdate)"'.mp4'
        fi
    fi
fi
