pragma Singleton
pragma ComponentBehavior: Bound

import qs
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

/**
 * Kitty remote-control tab data for the Super+Tab window list sidebar.
 *
 * `listen_on unix:@mykitty` has no {kitty_pid} placeholder, so each kitty
 * process listens on `unix:@mykitty-<pid>`. While the sidebar is open this
 * service enumerates `pidof kitty`, queries every socket with
 * `kitten @ ls`, and exposes:
 *
 *   instances: [{
 *     pid, socket,
 *     osWindows: [{
 *       id, title, titleCandidates, focused,
 *       tabs: [{ id, title, active, focused, needsAttention }]
 *     }]
 *   }]
 *
 * A kitty OS window's Wayland title (= Hyprland client title) equals the tab
 * it last focused; on unfocused windows that can drift behind is_active, so
 * matching uses titleCandidates (focused ∪ active tab titles). Mismatches
 * just show no tabs — display-only; focusing stays exact via kitty ids.
 * Instances whose socket fails (dead pid, remote control off) are skipped.
 */
Singleton {
    id: root

    property var instances: []

    // Refresh cycle internals
    property var _pendingPids: []
    property var _osWindowsBuf: []
    property bool _busy: false
    property string _lastSerialized: ""

    // Kitty command queue internals (focus/close actions)
    property var _cmdQueue: []
    property int _cmdPid: 0
    property int _cmdOswId: 0
    property int _cmdTabId: 0
    property bool _cmdFailed: false
    property bool _cmdIsFocus: false

    function refresh() {
        if (root._busy)
            return; // a cycle is already in flight; the timer re-triggers soon
        root._busy = true;
        root._pendingPids = [];
        root._osWindowsBuf = [];
        pidProc.running = true;
    }

    /**
     * Focus a specific tab: kitty focus-tab (switch tab inside the OS window)
     * then focus-window (raise the OS window via xdg-activation; Hyprland
     * honors it). If a kitty command exits non-zero, fall back to scanning
     * Hyprland's client list for the client whose title equals the tab's
     * title and dispatching a direct focus on it.
     */
    function focusTab(pid, oswId, tabId) {
        const inst = root._instanceForPid(pid);
        root._cmdPid = pid;
        root._cmdOswId = oswId;
        root._cmdTabId = tabId;
        root._cmdFailed = !inst;
        root._cmdIsFocus = true;
        let queue = [];
        if (inst) {
            queue = [["kitten", "@", "--to", inst.socket, "focus-tab", "--match", `id:${tabId}`]];
            // focus-window's id:<N> matches PANES (window ids), not OS-window
            // ids — focus any pane of the target tab so kitty raises the OS
            // window via xdg-activation.
            const paneId = inst.osWindows.find(o => o.id === oswId)
                ?.tabs.find(t => t.id === tabId)?.paneIds[0];
            if (paneId !== undefined)
                queue.push(["kitten", "@", "--to", inst.socket, "focus-window", "--match", `id:${paneId}`]);
        }
        root._cmdQueue = queue;
        root._runNextCmd();
    }

    /** Close a tab by kitty id. */
    function closeTab(pid, tabId) {
        const inst = root._instanceForPid(pid);
        if (!inst)
            return;
        root._cmdPid = pid;
        root._cmdOswId = 0;
        root._cmdTabId = tabId;
        root._cmdFailed = false;
        root._cmdIsFocus = false;
        root._cmdQueue = [["kitten", "@", "--to", inst.socket, "close-tab", "--match", `id:${tabId}`]];
        root._runNextCmd();
    }

    // Internals

    function _instanceForPid(pid) {
        return root.instances.find(i => i.pid === pid) ?? null;
    }

    function _tabTitleFor(pid, oswId, tabId) {
        const osw = root._instanceForPid(pid)?.osWindows.find(o => o.id === oswId);
        return osw?.tabs.find(t => t.id === tabId)?.title;
    }

    function _runNextCmd() {
        if (root._cmdQueue.length === 0) {
            if (root._cmdFailed && root._cmdIsFocus)
                fallbackTimer.restart();
            return;
        }
        kittyCmdProc.command = root._cmdQueue.shift();
        kittyCmdProc.running = true;
    }

    function _advanceRefreshCycle() {
        if (root._pendingPids.length === 0) {
            root._busy = false;
            // Reassigning instances rebuilds every consuming binding (and
            // recreates tab-row delegates); skip when data is unchanged.
            const serialized = JSON.stringify(root._osWindowsBuf);
            if (serialized !== root._lastSerialized) {
                root._lastSerialized = serialized;
                root.instances = root._osWindowsBuf;
            }
            return;
        }
        const pid = parseInt(root._pendingPids.shift());
        const socket = `unix:@mykitty-${pid}`;
        lsProc.currentPid = pid;
        lsProc.currentSocket = socket;
        lsProc.command = ["kitten", "@", "--to", socket, "ls"];
        lsProc.running = true;
    }

    function _mapOsWindow(osw) {
        const tabs = (osw.tabs ?? []).map(tab => ({
            id: tab.id,
            title: tab.title ?? "",
            active: tab.is_active === true,
            focused: tab.is_focused === true,
            needsAttention: (tab.windows ?? []).some(pane => pane.needs_attention === true),
            paneIds: (tab.windows ?? []).map(pane => pane.id),
        }));
        // The Hyprland client title tracks the tab the OS window last focused;
        // for unfocused windows it can drift behind is_active (verified live),
        // so match against both candidates.
        const focusedTab = tabs.find(t => t.focused);
        const activeTab = tabs.find(t => t.active);
        const candidates = [...new Set([focusedTab?.title, activeTab?.title].filter(t => t))];
        return {
            id: osw.id,
            title: (focusedTab ?? activeTab ?? tabs[0])?.title ?? "",
            titleCandidates: candidates,
            focused: osw.is_focused === true,
            tabs,
        };
    }

    function _hyprlandFallbackFocus() {
        // Client titles update async after focus-tab, hence the ~200ms wait
        // before this scan (caller's Timer).
        const title = root._tabTitleFor(root._cmdPid, root._cmdOswId, root._cmdTabId);
        if (title === undefined || title === null)
            return;
        HyprlandData.updateWindowList();
        const clients = HyprlandData.windowList.filter(c =>
            (c.class ?? "") === "kitty" && c.pid === root._cmdPid && (c.title ?? "") === title);
        if (clients.length === 0)
            return;
        // Tie-break: a client on the focused monitor's active workspace first.
        const focusedMonitor = HyprlandData.monitors.find(m => m.focused === true);
        const activeWsId = focusedMonitor?.activeWorkspace?.id;
        const pick = (typeof activeWsId === "number"
            ? clients.find(c => c.workspace?.id === activeWsId)
            : null) ?? clients[0];
        Hyprland.dispatch(`hl.dsp.focus({window="address:${pick.address}"})`);
    }

    // Refresh triggers: on open + every second while open.
    Connections {
        target: GlobalStates

        function onWindowListOpenChanged() {
            if (GlobalStates.windowListOpen)
                root.refresh();
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: GlobalStates.windowListOpen
        triggeredOnStart: true
        onTriggered: root.refresh()
    }

    Process { // 1. Enumerate kitty processes
        id: pidProc
        command: ["pidof", "kitty"]
        stdout: StdioCollector {
            onStreamFinished: {
                root._pendingPids = text.trim().split(/\s+/).filter(s => s.length > 0);
                root._advanceRefreshCycle();
            }
        }
    }

    Process { // 2. `kitten @ ls` per pid, sequentially
        id: lsProc
        property int currentPid: 0
        property string currentSocket: ""
        command: []
        stdout: StdioCollector {
            onStreamFinished: {
                if (root._busy) {
                    try {
                        const data = JSON.parse(text);
                        if (Array.isArray(data)) {
                            root._osWindowsBuf.push({
                                pid: lsProc.currentPid,
                                socket: lsProc.currentSocket,
                                osWindows: data.map(root._mapOsWindow),
                            });
                        }
                    } catch (e) {
                        // Non-zero exit / bad JSON → skip this instance silently.
                    }
                }
                root._advanceRefreshCycle();
            }
        }
    }

    Process { // focus-tab / focus-window / close-tab runner
        id: kittyCmdProc
        command: []
        onExited: (exitCode, exitStatus) => {
            if (exitCode !== 0)
                root._cmdFailed = true;
            root._runNextCmd();
        }
    }

    Timer { // fallback delay: client titles settle async after focus-tab
        id: fallbackTimer
        interval: 200
        onTriggered: root._hyprlandFallbackFocus()
    }
}
