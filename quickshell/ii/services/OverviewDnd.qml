pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Cross-monitor drag & drop coordination for the workspace overview.
 *
 * QML Drag/DropArea is scene-local: a window pill dragged inside monitor A's
 * overview panel can never trigger DropAreas in monitor B's separate panel
 * window. While a drag is active, this singleton polls the global cursor
 * position (`hyprctl cursorpos -j`, logical layout coords); every monitor's
 * OverviewWidget checks the cursor against its own screen and — when the drag
 * did not originate on its own panel — publishes the hovered workspace cell
 * here. On release, the origin widget reads hoveredTarget to dispatch a
 * cross-monitor move:
 *   hl.dsp.window.move({window="address:..", workspace=N, monitor="DP-X", follow=false})
 * (monitor + workspace combination verified against Hyprland 0.57).
 */
Singleton {
    id: root

    property bool dragActive: false
    property string dragAddress: ""
    property int dragFromWorkspace: -1
    /** Name of the monitor whose overview panel the drag started in. */
    property string dragOriginMonitor: ""

    /** Global logical cursor position ({x, y}) while dragActive, else null. */
    property var pointer: null

    /**
     * Published by the OverviewWidget whose screen is under the cursor
     * (skipping the origin panel, whose DropAreas handle that case):
     * { monitor: "DP-3", workspace: 15, pctX: 40, pctY: 60 } or null.
     * pctX/pctY are the cursor position within the target cell (0-100),
     * used to place floating windows exactly where dropped.
     */
    property var hoveredTarget: null

    function startDrag(address, fromWorkspace, originMonitor) {
        root.dragAddress = address;
        root.dragFromWorkspace = fromWorkspace ?? -1;
        root.dragOriginMonitor = originMonitor ?? "";
        root.pointer = null;
        root.hoveredTarget = null;
        root.dragActive = true;
    }

    function endDrag() {
        root.dragActive = false;
        root.pointer = null;
        root.hoveredTarget = null;
    }

    onDragActiveChanged: pollTimer.running = root.dragActive

    Timer {
        id: pollTimer
        interval: 25
        repeat: true
        running: false
        triggeredOnStart: true
        onTriggered: cursorProc.running = true
    }

    Process {
        id: cursorProc
        command: ["hyprctl", "cursorpos", "-j"]
        stdout: StdioCollector {
            id: cursorCollector
            onStreamFinished: {
                if (!root.dragActive) return;
                try {
                    const pos = JSON.parse(cursorCollector.text);
                    root.pointer = { x: pos.x, y: pos.y };
                } catch (e) {
                    // Transient failure (hyprctl busy?) — keep last known position.
                }
            }
        }
    }
}
