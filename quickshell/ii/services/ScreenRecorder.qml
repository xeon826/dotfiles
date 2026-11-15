pragma Singleton
pragma ComponentBehavior: Bound
import qs.modules.common
import QtQuick
import Quickshell
import Quickshell.Io

/**
 * Screen recording state (wf-recorder), polled via pidof.
 */
Singleton {
    id: root

    property bool recording: false

    Component.onCompleted: checkProc.running = true

    Timer {
        interval: 1500
        repeat: true
        running: true
        onTriggered: checkProc.running = true
    }

    Process {
        id: checkProc
        command: ["pidof", "wf-recorder"]
        onExited: (exitCode, exitStatus) => root.recording = (exitCode === 0)
    }

    function stop(): void {
        // Bare invocation: record.sh's pgrep branch stops the recording.
        Quickshell.execDetached([Directories.recordScriptPath]);
    }
}
