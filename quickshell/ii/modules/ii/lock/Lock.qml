pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.functions
import qs.modules.common.panels.lock
import QtQuick
import Quickshell
import Quickshell.Hyprland

LockScreen {
    id: root

    // Monitor name -> workspace id to restore on unlock (set when locking)
    property var savedWorkspaces: ({})

    // Retries until every monitor stranded on a lock temp workspace is healed.
    // A single fire-and-forget batch races DPMS wake / unlock and silently
    // strands monitors on the huge-ID temp workspaces (2147483647 - ws).
    Timer {
        id: restoreTimer
        interval: 250
        repeat: true

        property int attempts: 0

        function startRestore() {
            attempts = 0;
            restart();
        }

        onTriggered: {
            attempts++;
            var batch = "";
            var allRestored = true;
            for (var j = 0; j < Quickshell.screens.length; ++j) {
                var monName = Quickshell.screens[j].name;
                var mData = HyprlandData.monitors.find(m => m.name === monName);
                var current = mData?.activeWorkspace?.id ?? -1;
                if (current <= 1000000) {
                    continue; // not stranded on a temp workspace
                }
                allRestored = false;
                // Prefer the workspace saved at lock time; if that state was
                // lost (shell restarted while locked), fall back to the lowest
                // workspace still assigned to this monitor.
                var wsId = root.savedWorkspaces[monName];
                if (wsId === undefined || wsId <= 0) {
                    wsId = HyprlandData.workspaces.find(ws => ws.monitorID === mData?.id)?.id;
                }
                if (wsId !== undefined && wsId > 0) {
                    batch += "dispatch focusmonitor " + monName + "; dispatch workspace " + wsId + "; ";
                }
            }
            if (batch.length > 0) {
                Quickshell.execDetached(["hyprctl", "--batch", batch + "reload"])
            }
            // Give up after ~5s so an unreachable monitor can't loop forever
            if (allRestored || attempts >= 20) {
                restoreTimer.stop();
            }
        }
    }

    lockSurface: LockSurface {
        context: root.context
    }

    // Single batch for lock and unlock so we don't race multiple hyprctl calls
    Connections {
        target: GlobalStates
        function onScreenLockedChanged() {
            if (GlobalStates.screenLocked) {
                // Lock: save workspace per monitor and move all to temp workspace in one batch
                var next = {}
                var batch = "keyword animation workspaces,1,7,menu_decel,slidevert; "
                for (var i = 0; i < Quickshell.screens.length; ++i) {
                    var mon = Quickshell.screens[i].name
                    var mData = HyprlandData.monitors.find(m => m.name === mon)
                    if (mData?.activeWorkspace == undefined) {
                        continue; // skip this monitor instead of aborting the whole save
                    }
                    var ws = (mData?.activeWorkspace?.id ?? 1)
                    if (ws > 1000000) {
                        continue; // already stranded on a temp workspace; don't save or re-park it
                    }
                    next[mon] = ws
                    batch += "dispatch focusmonitor " + mon + "; dispatch workspace " + (2147483647 - ws) + "; "
                }
                root.savedWorkspaces = next
                restoreTimer.stop()
                Quickshell.execDetached(["hyprctl", "--batch", batch + "reload"])
            } else {
                restoreTimer.startRestore()
            }
        }
    }

    // Push everything down (visual only; workspace switch is in Connections above)
    Variants {
        model: Quickshell.screens
        delegate: Scope {
            required property ShellScreen modelData
            property bool shouldPush: GlobalStates.screenLocked
            property string targetMonitorName: modelData.name
            property int verticalMovementDistance: modelData.height
            property int horizontalSqueeze: modelData.width * 0.2
        }
    }
}
