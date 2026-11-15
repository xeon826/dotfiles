pragma Singleton
pragma ComponentBehavior: Bound
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Screen recording state (wf-recorder), polled via pidof. The recording
 * region/monitor is published by record.sh as a JSON state file so every
 * start path (selector, keybinds, CLI) reports the same info.
 */
Singleton {
    id: root

    property bool recording: false
    /// {monitor, x, y, w, h} in global logical coords, or null
    property var region: null

    readonly property string statePath: `${Quickshell.env("XDG_RUNTIME_DIR") ?? "/tmp"}/quickshell-recorder-state.json`

    Component.onCompleted: {
        checkProc.running = true;
        stateProc.running = true;
    }

    Timer {
        interval: 1500
        repeat: true
        running: true
        onTriggered: {
            checkProc.running = true;
            stateProc.running = true;
        }
    }

    Process {
        id: checkProc
        command: ["pidof", "wf-recorder"]
        onExited: (exitCode, exitStatus) => root.recording = (exitCode === 0)
    }

    Process {
        id: stateProc
        command: ["cat", root.statePath]
        stdout: StdioCollector {
            id: stateCollector
            onStreamFinished: {
                try {
                    root.region = JSON.parse(stateCollector.text);
                } catch (e) {
                    root.region = null;
                }
            }
        }
    }

    function stop(): void {
        // Bare invocation: record.sh's pgrep branch stops the recording.
        Quickshell.execDetached([Directories.recordScriptPath]);
    }
}
