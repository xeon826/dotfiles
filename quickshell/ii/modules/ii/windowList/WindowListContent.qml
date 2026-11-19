pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

Item {
    id: root
    required property var scopeRoot
    required property var panelWindow

    property string draggingTargetKey: ""
    property string draggingAddress: ""

    // Monitor-drop (feature D): global logical cursor while a row drag is active
    property bool rowDragActive: false
    property var cursorPos: null
    property string monitorDropTarget: ""

    // Kitty tab collapse state (feature B), keyed by kitty OS-window id.
    // Absent = expanded (tabs are expanded by default); lives while the panel is open.
    property var expandedTabs: ({})

    function wsKeyFor(win) {
        // Hyprland 0.57: normal workspaces have numeric id; special workspaces have address like "special:browser"
        const ws = win?.workspace;
        return (ws && typeof ws.id === "number") ? `${ws.id}` : (ws?.address ?? "?");
    }

    readonly property var workspaceSections: {
        const byKey = new Map();
        // Seed with existing (possibly empty) numbered workspaces so they act as drop targets
        for (const ws of HyprlandData.workspaces) {
            if (typeof ws.id === "number" && ws.id >= 1 && ws.id <= 100)
                byKey.set(`${ws.id}`, { key: `${ws.id}`, id: ws.id, name: ws.name, monitor: ws.monitor ?? "", special: false, windows: [] });
        }
        const windows = HyprlandData.windowList.filter(w => {
            const ws = w?.workspace;
            return ws && (typeof ws.id !== "number" || ws.id <= 100); // lock-screen temp guard (AGENTS.md)
        });
        for (const win of windows) {
            const key = root.wsKeyFor(win);
            if (!byKey.has(key)) {
                const ws = win.workspace;
                const special = typeof ws.id !== "number";
                const monitorName = special ? "" : (HyprlandData.monitors.find(m => m.id === win.monitor)?.name ?? "");
                byKey.set(key, { key, id: special ? null : ws.id, name: ws.name, monitor: monitorName, special, windows: [] });
            }
            byKey.get(key).windows.push(win);
        }
        const numbered = [...byKey.values()].filter(s => !s.special);
        const specials = [...byKey.values()].filter(s => s.special);

        // Group numbered workspaces by monitor, ordered by monitor position in
        // HyprlandData.monitors; ascending workspace ids within each group.
        // Monitors unknown to hyprctl (shouldn't happen) rank last, alphabetical.
        const groupRank = {};
        // Mirror the physical layout: sort monitors by logical x (ties by y
        // for vertical stacks) so the sidebar's top-to-bottom group order
        // matches the monitors' left-to-right arrangement.
        [...HyprlandData.monitors].sort((a, b) => (a.x - b.x) || (a.y - b.y))
            .forEach((m, i) => {
                groupRank[m.name] = i;
            });
        const unknownMonitors = [...new Set(numbered.map(s => s.monitor).filter(n => !(n in groupRank)))].sort();
        unknownMonitors.forEach((n, i) => {
            groupRank[n] = HyprlandData.monitors.length + i;
        });
        numbered.sort((a, b) => (groupRank[a.monitor] - groupRank[b.monitor]) || (a.id - b.id));
        specials.sort((a, b) => (a.name ?? "").localeCompare(b.name ?? ""));

        const sections = [...numbered, ...specials]; // specials stay last, ungrouped
        for (const section of sections) {
            section.windows.sort((a, b) => (a.at[1] - b.at[1]) || (a.at[0] - b.at[0]));
        }
        return sections;
    }

    /**
     * Hyprland client address → kitty OS window match (feature B).
     * Clients and OS windows are matched by TITLE equality, greedy 1:1 within
     * one kitty process pid (a process' OS windows are separate Hyprland
     * clients sharing its pid). Leftover clients get no tab rows; focusing a
     * tab stays exact because it goes through kitty ids, not the client match.
     */
    readonly property var kittyTabByAddress: {
        const map = {};
        for (const inst of KittyTabs.instances) {
            const clients = HyprlandData.windowList
                .filter(w => (w.class ?? "") === "kitty" && w.pid === inst.pid)
                .sort((a, b) => (a.address < b.address ? -1 : a.address > b.address ? 1 : 0));
            const used = new Set();
            for (const c of clients) {
                const osw = inst.osWindows.find(o => !used.has(o.id) && o.titleCandidates.includes(c.title ?? ""));
                if (!osw)
                    continue;
                used.add(osw.id);
                map[c.address] = { pid: inst.pid, socket: inst.socket, osWindow: osw };
            }
        }
        return map;
    }

    function tabsExpanded(oswId) {
        return root.expandedTabs[oswId] !== false;
    }

    function toggleTabsExpanded(oswId) {
        const next = Object.assign({}, root.expandedTabs);
        next[oswId] = !root.tabsExpanded(oswId);
        root.expandedTabs = next;
    }

    function resetDragging() {
        root.draggingTargetKey = "";
        root.draggingAddress = "";
    }

    // Feature D: monitor-drop mode

    function startRowDrag() {
        root.rowDragActive = true;
    }

    function stopRowDrag() {
        root.rowDragActive = false;
        root.cursorPos = null;
        root.monitorDropTarget = "";
    }

    function updateMonitorDropTarget() {
        if (!root.rowDragActive || !root.cursorPos) {
            root.monitorDropTarget = "";
            return;
        }
        const p = root.cursorPos;
        const origin = root.mapToGlobal(0, 0);
        const insideSidebar = p.x >= origin.x && p.x <= origin.x + root.width
            && p.y >= origin.y && p.y <= origin.y + root.height;
        if (insideSidebar) {
            root.monitorDropTarget = ""; // in-sidebar: workspace DropAreas own the drop
            return;
        }
        // Monitor rects: hyprctl monitor width/height are physical px, cursorpos is logical
        const mon = HyprlandData.monitors.find(m => {
            const mw = m.width / m.scale, mh = m.height / m.scale;
            return p.x >= m.x && p.x < m.x + mw && p.y >= m.y && p.y < m.y + mh;
        });
        root.monitorDropTarget = mon?.name ?? "";
    }

    /** Move a client to a monitor's ACTIVE workspace; floaters get repositioned onto the target. */
    function moveWindowToMonitor(address, client, monName) {
        const mon = HyprlandData.monitors.find(m => m.name === monName);
        const wsId = mon?.activeWorkspace?.id;
        if (typeof wsId !== "number")
            return;
        if (client?.workspace?.id === wsId && client?.monitor === mon.id)
            return; // already on this monitor's active workspace
        Hyprland.dispatch(`hl.dsp.window.move({window="address:${address}",workspace=${wsId},monitor="${monName}",follow=false})`);
        if (client?.floating === true) {
            // Lua dsp rejects x/y together with workspace/monitor — follow-up dispatch, logical coords
            const inset = 80;
            Hyprland.dispatch(`hl.dsp.window.move({window="address:${address}",x=${Math.round(mon.x + inset)},y=${Math.round(mon.y + inset)}})`);
        }
    }

    // Clear tab collapse state — it lives only while the panel is open.
    Connections {
        target: GlobalStates

        function onWindowListOpenChanged() {
            if (!GlobalStates.windowListOpen)
                root.expandedTabs = ({});
        }
    }

    Timer {
        id: cursorPollTimer
        interval: 25
        repeat: true
        running: root.rowDragActive
        triggeredOnStart: true
        onTriggered: cursorProc.running = true
    }

    Process {
        id: cursorProc
        command: ["hyprctl", "cursorpos", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!root.rowDragActive)
                    return;
                try {
                    const pos = JSON.parse(text);
                    root.cursorPos = { x: pos.x, y: pos.y };
                    root.updateMonitorDropTarget();
                } catch (e) {
                    // Transient failure (hyprctl busy?) — keep last known position.
                }
            }
        }
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: sectionColumn.implicitHeight
        clip: true
        interactive: !root.draggingAddress

        // Mouse-wheel scrolling — Flickable ignores the wheel by default and
        // the rows' MouseAreas consume drag gestures for workspace DnD, so
        // without this the list is only reachable by flicking empty areas.
        WheelHandler {
            target: null
            onWheel: (event) => {
                const maxY = Math.max(0, flick.contentHeight - flick.height);
                flick.contentY = Math.min(maxY, Math.max(0, flick.contentY - event.angleDelta.y / 2));
            }
        }

        Column {
            id: sectionColumn
            width: flick.width
            spacing: 0

            Repeater {
                model: root.workspaceSections

                delegate: Rectangle {
                    id: section
                    required property var modelData
                    required property int index
                    readonly property bool isTarget: root.draggingTargetKey === modelData.key
                    readonly property color sectionColor: Appearance.colors.colBackgroundSurfaceContainer
                    readonly property color targetColor: ColorUtils.mix(sectionColor, Appearance.colors.colLayer1Hover, 0.5)
                    readonly property string sectionLabel: modelData.special ? (modelData.name ?? "").replace(/^special:/, "") : `${modelData.id}`
                    readonly property real rowHeight: Appearance.sizes.baseBarHeight
                    readonly property string focusDispatch: modelData.special
                        ? `hl.dsp.focus({workspace="name:${modelData.name}"})`
                        : `hl.dsp.focus({workspace=${modelData.id}})`
                    // True when this section opens a new monitor group (monitor divider above
                    // it). Specials stay ungrouped — no monitor divider on the special block.
                    readonly property bool startsMonitorGroup: index > 0
                        && !modelData.special
                        && modelData.monitor !== root.workspaceSections[index - 1].monitor

                    width: parent.width
                    height: sectionContent.implicitHeight
                    color: isTarget ? targetColor : sectionColor
                    radius: Appearance.rounding.small
                    Behavior on color {
                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                    }

                    Column {
                        id: sectionContent
                        anchors.top: parent.top
                        anchors.left: parent.left
                        anchors.right: parent.right
                        spacing: 0

                        Item { // Monitor-group divider: heavier line + monitor name
                            visible: section.startsMonitorGroup
                            width: parent.width
                            height: Appearance.sizes.hyprlandGapsOut * 6

                            StyledText {
                                id: monLabel
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                                anchors.rightMargin: Appearance.sizes.hyprlandGapsOut * 3
                                text: section.modelData.monitor
                                color: Appearance.colors.colPrimary
                                font.pixelSize: Appearance.font.pixelSize.small
                                font.variableAxes: Appearance.font.variableAxes.title
                            }
                            Rectangle {
                                height: 2
                                radius: 1
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.right: monLabel.left
                                anchors.rightMargin: 8
                                color: ColorUtils.mix(Appearance.colors.colOutlineVariant, Appearance.colors.colPrimary, 0.65)
                                visible: width > 0 // degrade gracefully when the label leaves no room
                            }
                        }

                        Repeater {
                            model: section.modelData.windows

                            delegate: Column {
                                id: windowUnit
                                required property var modelData
                                readonly property var kittyMatch: root.kittyTabByAddress[modelData.address] ?? null
                                readonly property bool hasMultiTabs: kittyMatch !== null && kittyMatch.osWindow.tabs.length > 1
                                readonly property bool tabsShown: hasMultiTabs && root.tabsExpanded(kittyMatch.osWindow.id)
                                readonly property bool dimmed: {
                                    // Dim = window is parked on a background workspace of its own
                                    // monitor. Special workspaces (overlay) and unknowns stay bright.
                                    const ws = modelData.workspace;
                                    if (!ws || typeof ws.id !== "number")
                                        return false;
                                    const mon = HyprlandData.monitors.find(m => m.id === modelData.monitor);
                                    const activeWsId = mon?.activeWorkspace?.id;
                                    return typeof activeWsId === "number" && ws.id !== activeWsId;
                                }

                                width: parent ? parent.width : 0
                                spacing: Appearance.sizes.hyprlandGapsOut

                                Rectangle {
                                    id: windowRow
                                    width: parent.width
                                    height: section.rowHeight
                                    radius: Appearance.rounding.small
                                    color: dragArea.containsMouse || expanderMouse.containsMouse ? Appearance.colors.colLayer1Hover : "transparent"
                                    opacity: windowUnit.dimmed ? 0.4 : 1

                                    Behavior on color {
                                        animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                                    }

                                    Drag.active: dragArea.drag.active
                                    Drag.source: windowRow
                                    Drag.hotSpot.x: windowRow.width / 2
                                    Drag.hotSpot.y: windowRow.height / 2

                                    MouseArea { // below rowContent so the expander/hint on top can take clicks
                                        id: dragArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                        acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                        drag.target: windowRow
                                        drag.axis: Drag.YAxis
                                        onPressed: (mouse) => {
                                            root.draggingAddress = windowUnit.modelData.address;
                                            root.startRowDrag();
                                            windowRow.Drag.active = true;
                                            windowRow.Drag.source = windowRow;
                                            windowRow.Drag.hotSpot.x = mouse.x;
                                            windowRow.Drag.hotSpot.y = mouse.y;
                                        }
                                        onReleased: {
                                            const targetKey = root.draggingTargetKey;
                                            const dropMonitor = targetKey === "" ? root.monitorDropTarget : "";
                                            const client = windowUnit.modelData;
                                            windowRow.Drag.active = false;
                                            root.stopRowDrag();
                                            root.resetDragging();
                                            windowRow.x = 0;
                                            windowRow.y = 0;
                                            const sourceKey = root.wsKeyFor(client);
                                            if (targetKey !== "" && targetKey !== sourceKey) {
                                                const targetSection = root.workspaceSections.find(s => s.key === targetKey);
                                                if (!targetSection) return;
                                                const wsDesignator = targetSection.special ? `"${targetSection.name}"` : `${targetSection.id}`;
                                                Hyprland.dispatch(`hl.dsp.window.move({window="address:${client.address}",workspace=${wsDesignator},follow=false})`);
                                            } else if (dropMonitor !== "") {
                                                root.moveWindowToMonitor(client.address, client, dropMonitor);
                                            }
                                        }
                                        onClicked: (event) => {
                                            if (event.button === Qt.LeftButton) {
                                                GlobalStates.windowListOpen = false;
                                                Hyprland.dispatch(`hl.dsp.focus({window="address:${windowUnit.modelData.address}"})`);
                                                event.accepted = true;
                                            } else if (event.button === Qt.MiddleButton) {
                                                Hyprland.dispatch(`hl.dsp.window.close({window="address:${windowUnit.modelData.address}"})`);
                                                event.accepted = true;
                                            }
                                        }

                                        StyledToolTip {
                                            extraVisibleCondition: false
                                            alternativeVisibleCondition: dragArea.containsMouse && !windowRow.Drag.active
                                            text: `${windowUnit.modelData.title}\n[${windowUnit.modelData.class}] ${windowUnit.modelData.xwayland ? "[XWayland] " : ""}`
                                        }
                                    }

                                    Item { // Icon + title + expander + drop hint
                                        id: rowContent
                                        readonly property real horizontalMargin: Appearance.sizes.hyprlandGapsOut * 3
                                        readonly property real iconSize: Appearance.font.pixelSize.larger
                                        anchors.fill: parent
                                        anchors.leftMargin: rowContent.horizontalMargin
                                        anchors.rightMargin: rowContent.horizontalMargin

                                        Image {
                                            id: rowIcon
                                            // file:// resolver (QIcon-free) — Quickshell.iconPath
                                            // goes per-name flaky after engine reloads
                                            readonly property string iconSource: AppSearch.windowIconSource(windowUnit.modelData.class ?? "")
                                            visible: iconSource !== ""
                                            width: rowContent.iconSize
                                            height: rowContent.iconSize
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: parent.left
                                            source: iconSource
                                            asynchronous: true
                                            fillMode: Image.PreserveAspectFit
                                            smooth: true
                                            mipmap: true
                                        }
                                        StyledText {
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.left: rowIcon.right
                                            anchors.leftMargin: rowContent.horizontalMargin
                                            anchors.right: monitorHint.visible ? monitorHint.left : (tabExpander.visible ? tabExpander.left : parent.right)
                                            elide: Text.ElideRight
                                            maximumLineCount: 1
                                            text: windowUnit.modelData.title
                                        }

                                        Item { // Chevron expander for kitty OS windows with >1 tabs
                                            id: tabExpander
                                            visible: windowUnit.hasMultiTabs
                                            width: Appearance.sizes.hyprlandGapsOut * 6
                                            height: parent.height
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.right: parent.right

                                            MouseArea {
                                                id: expanderMouse
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: root.toggleTabsExpanded(windowUnit.kittyMatch.osWindow.id)
                                            }
                                            MaterialSymbol {
                                                anchors.centerIn: parent
                                                text: windowUnit.tabsShown ? "keyboard_arrow_down" : "keyboard_arrow_right"
                                                iconSize: Appearance.font.pixelSize.normal
                                                color: expanderMouse.containsMouse ? Appearance.colors.colPrimary : Appearance.colors.colOnLayer1Inactive
                                                Behavior on color {
                                                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                                                }
                                            }
                                        }

                                        Rectangle { // Monitor-drop hint while dragging outside the sidebar
                                            id: monitorHint
                                            visible: root.draggingAddress === windowUnit.modelData.address && root.monitorDropTarget !== ""
                                            height: Appearance.font.pixelSize.smaller + Appearance.sizes.hyprlandGapsOut * 2
                                            width: monitorHintLabel.implicitWidth + Appearance.sizes.hyprlandGapsOut * 3
                                            radius: height / 2
                                            anchors.verticalCenter: parent.verticalCenter
                                            anchors.right: parent.right
                                            color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.82)
                                            border.width: 1
                                            border.color: ColorUtils.transparentize(Appearance.colors.colPrimary, 0.5)

                                            StyledText {
                                                id: monitorHintLabel
                                                anchors.centerIn: parent
                                                text: `→ ${root.monitorDropTarget}`
                                                font.pixelSize: Appearance.font.pixelSize.smaller
                                                font.variableAxes: Appearance.font.variableAxes.numbers
                                                color: Appearance.colors.colPrimary
                                            }
                                        }
                                    }
                                }

                                Rectangle { // Grouping box: these tabs belong to this one kitty window
                                    id: tabsBox
                                    visible: windowUnit.tabsShown
                                    opacity: windowUnit.dimmed ? 0.4 : 1
                                    x: rowContent.horizontalMargin + rowContent.iconSize // indent past the icon column
                                    width: parent.width - x * 2
                                    height: tabsColumn.implicitHeight + Appearance.sizes.hyprlandGapsOut * 2
                                    radius: Appearance.rounding.small
                                    color: ColorUtils.mix(section.sectionColor, Appearance.colors.colLayer1Hover, 0.6)
                                    border.width: 1
                                    border.color: Appearance.colors.colOutlineVariant

                                    Column {
                                        id: tabsColumn
                                        anchors.top: parent.top
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        anchors.topMargin: Appearance.sizes.hyprlandGapsOut
                                        anchors.leftMargin: Appearance.sizes.hyprlandGapsOut
                                        anchors.rightMargin: Appearance.sizes.hyprlandGapsOut
                                        spacing: 2

                                        Repeater {
                                            model: windowUnit.kittyMatch?.osWindow.tabs ?? []

                                            delegate: Rectangle {
                                                id: tabRow
                                                required property var modelData
                                                readonly property bool activeTab: modelData.active === true
                                                height: Math.round(section.rowHeight * 0.8)
                                                radius: Appearance.rounding.verysmall
                                                width: parent ? parent.width : 0
                                                color: tabMouse.containsMouse
                                                    ? (activeTab ? ColorUtils.mix(tabsBox.color, Appearance.colors.colPrimary, 0.78) : Appearance.colors.colLayer1Hover)
                                                    : (activeTab ? ColorUtils.mix(tabsBox.color, Appearance.colors.colPrimary, 0.88) : "transparent")
                                                Behavior on color {
                                                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                                                }

                                                StyledText {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    anchors.left: parent.left
                                                    anchors.leftMargin: Appearance.sizes.hyprlandGapsOut * 2
                                                    anchors.right: attentionDot.visible ? attentionDot.left : parent.right
                                                    anchors.rightMargin: Appearance.sizes.hyprlandGapsOut * 2
                                                    elide: Text.ElideRight
                                                    maximumLineCount: 1
                                                    text: tabRow.modelData.title
                                                    font.pixelSize: Appearance.font.pixelSize.smaller
                                                    color: tabRow.activeTab ? Appearance.colors.colPrimary : Appearance.m3colors.m3onBackground
                                                    font.variableAxes: tabRow.activeTab ? Appearance.font.variableAxes.title : Appearance.font.variableAxes.main
                                                }

                                                Rectangle { // "needs attention" dot (a pane has needs_attention)
                                                    id: attentionDot
                                                    visible: tabRow.modelData.needsAttention === true
                                                    width: 7
                                                    height: width
                                                    radius: width / 2
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    anchors.right: parent.right
                                                    anchors.rightMargin: Appearance.sizes.hyprlandGapsOut * 2
                                                    color: Appearance.colors.colTertiary
                                                }

                                                MouseArea {
                                                    id: tabMouse
                                                    anchors.fill: parent
                                                    hoverEnabled: true
                                                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                                    cursorShape: Qt.PointingHandCursor
                                                    onClicked: (event) => {
                                                        if (event.button === Qt.LeftButton) {
                                                            // Dispatch kitty focus BEFORE closing the
                                                            // panel — closing a layer window can affect
                                                            // focus hand-off.
                                                            KittyTabs.focusTab(windowUnit.kittyMatch.pid, windowUnit.kittyMatch.osWindow.id, tabRow.modelData.id);
                                                            GlobalStates.windowListOpen = false;
                                                            event.accepted = true;
                                                        } else if (event.button === Qt.MiddleButton) {
                                                            KittyTabs.closeTab(windowUnit.kittyMatch.pid, tabRow.modelData.id);
                                                            event.accepted = true;
                                                        }
                                                    }

                                                    StyledToolTip {
                                                        extraVisibleCondition: false
                                                        alternativeVisibleCondition: tabMouse.containsMouse
                                                        text: tabRow.modelData.title
                                                    }
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Item { // Divider with workspace label
                            id: divider
                            width: parent.width
                            height: Appearance.sizes.hyprlandGapsOut * 5

                            MouseArea {
                                anchors.fill: parent
                                onClicked: {
                                    GlobalStates.windowListOpen = false;
                                    Hyprland.dispatch(section.focusDispatch);
                                }
                            }

                            StyledText {
                                id: wsLabel
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                                anchors.rightMargin: Appearance.sizes.hyprlandGapsOut * 3
                                text: section.sectionLabel
                                color: Appearance.colors.colOutlineVariant
                            }
                            Rectangle {
                                id: line
                                height: 1
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.left: parent.left
                                anchors.right: wsLabel.left // stop short of the label, no strikethrough
                                anchors.rightMargin: 8
                                color: Appearance.colors.colOutlineVariant
                                visible: width > 0 // degrade gracefully when the label leaves no room
                            }
                        }
                    }

                    DropArea {
                        anchors {
                            fill: parent
                            topMargin: -Appearance.sizes.hyprlandGapsOut * 2
                            bottomMargin: -Appearance.sizes.hyprlandGapsOut * 2
                        }
                        onEntered: (drag) => {
                            if (root.draggingAddress)
                                root.draggingTargetKey = section.modelData.key;
                        }
                        onExited: {
                            if (root.draggingTargetKey === section.modelData.key)
                                root.draggingTargetKey = "";
                        }
                    }
                }
            }
        }
    }
}
