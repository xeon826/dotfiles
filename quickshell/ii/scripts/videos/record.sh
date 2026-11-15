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
    # sources expands into extra argv tokens and wf-recorder exits instantly.
    echo "$(pactl get-default-sink).monitor"
}
getactivemonitor() {
    hyprctl monitors -j | jq -r '.[] | select(.focused == true) | .name'
}
getregionmonitor() {
    # wf-recorder 0.6.x prompts interactively for an output on multi-monitor
    # setups unless -o is given; detached runs have no stdin and die instantly.
    # Pick the monitor containing the region origin. Region is "X,Y WxH" in
    # global logical coords; hyprctl width/height are physical px, so /scale.
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

if pgrep wf-recorder > /dev/null; then
    rm -f "$STATE_FILE"
    notify-send "Recording Stopped" "Stopped" -a 'Recorder' &
    pkill wf-recorder &
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
            wf-recorder -o "$fullscreenMonitor" --pixel-format yuv420p -f './recording_'"$(getdate)"'.mp4' --audio="$(getaudiooutput)"
        else
            wf-recorder -o "$fullscreenMonitor" --pixel-format yuv420p -f './recording_'"$(getdate)"'.mp4'
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
        if [[ $SOUND_FLAG -eq 1 ]]; then
            wf-recorder -o "$regionMonitor" --pixel-format yuv420p -f './recording_'"$(getdate)"'.mp4' --geometry "$region" --audio="$(getaudiooutput)"
        else
            wf-recorder -o "$regionMonitor" --pixel-format yuv420p -f './recording_'"$(getdate)"'.mp4' --geometry "$region"
        fi
    fi
fi
