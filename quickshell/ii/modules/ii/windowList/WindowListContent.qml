pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import qs.modules.common.functions
import QtQuick
import Quickshell
import Quickshell.Hyprland

Item {
    id: root
    required property var scopeRoot
    required property var panelWindow
    readonly property int monitorId: Hyprland.monitorFor(panelWindow.screen)?.id ?? -1

    property string draggingTargetKey: ""
    property string draggingAddress: ""

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
                byKey.set(`${ws.id}`, { key: `${ws.id}`, id: ws.id, name: ws.name, special: false, windows: [] });
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
                byKey.set(key, { key, id: special ? null : ws.id, name: ws.name, special, windows: [] });
            }
            byKey.get(key).windows.push(win);
        }
        const sections = [...byKey.values()];
        sections.sort((a, b) => {
            if (a.special !== b.special)
                return a.special ? 1 : -1; // numbered ascending first, specials last
            if (a.special)
                return (a.name ?? "").localeCompare(b.name ?? "");
            return a.id - b.id;
        });
        for (const section of sections) {
            section.windows.sort((a, b) => (a.at[1] - b.at[1]) || (a.at[0] - b.at[0]));
        }
        return sections;
    }

    function resetDragging() {
        root.draggingTargetKey = "";
        root.draggingAddress = "";
    }

    Flickable {
        id: flick
        anchors.fill: parent
        contentWidth: width
        contentHeight: sectionColumn.implicitHeight
        clip: true
        interactive: !root.draggingAddress

        Column {
            id: sectionColumn
            width: flick.width
            spacing: 0

            Repeater {
                model: root.workspaceSections

                delegate: Rectangle {
                    id: section
                    required property var modelData
                    readonly property bool isTarget: root.draggingTargetKey === modelData.key
                    readonly property color sectionColor: Appearance.colors.colBackgroundSurfaceContainer
                    readonly property color targetColor: ColorUtils.mix(sectionColor, Appearance.colors.colLayer1Hover, 0.5)
                    readonly property string sectionLabel: modelData.special ? (modelData.name ?? "").replace(/^special:/, "") : `${modelData.id}`
                    readonly property real rowHeight: Appearance.sizes.baseBarHeight
                    readonly property string focusDispatch: modelData.special
                        ? `hl.dsp.focus({workspace="name:${modelData.name}"})`
                        : `hl.dsp.focus({workspace=${modelData.id}})`

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

                        Repeater {
                            model: section.modelData.windows

                            delegate: Rectangle {
                                id: windowRow
                                required property var modelData
                                readonly property bool dimmed: modelData.monitor !== root.monitorId

                                width: parent.width
                                height: section.rowHeight
                                radius: Appearance.rounding.small
                                color: dragArea.containsMouse ? Appearance.colors.colLayer1Hover : "transparent"
                                opacity: dimmed ? 0.4 : 1

                                Behavior on color {
                                    animation: Appearance.animation.elementMoveFast.colorAnimation.createObject(this)
                                }

                                Drag.active: dragArea.drag.active
                                Drag.source: windowRow
                                Drag.hotSpot.x: windowRow.width / 2
                                Drag.hotSpot.y: windowRow.height / 2

                                Item { // Icon + title
                                    id: rowContent
                                    readonly property real horizontalMargin: Appearance.sizes.hyprlandGapsOut * 3
                                    readonly property real iconSize: Appearance.font.pixelSize.larger
                                    anchors.fill: parent
                                    anchors.leftMargin: rowContent.horizontalMargin
                                    anchors.rightMargin: rowContent.horizontalMargin

                                    Image {
                                        id: rowIcon
                                        width: rowContent.iconSize
                                        height: rowContent.iconSize
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        source: Quickshell.iconPath(AppSearch.guessIcon(windowRow.modelData.class), "image-missing")
                                        asynchronous: true
                                        fillMode: Image.PreserveAspectFit
                                        smooth: true
                                        mipmap: true
                                    }
                                    StyledText {
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: rowIcon.right
                                        anchors.leftMargin: rowContent.horizontalMargin
                                        anchors.right: parent.right
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                        text: windowRow.modelData.title
                                    }
                                }

                                MouseArea {
                                    id: dragArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.MiddleButton
                                    drag.target: windowRow
                                    drag.axis: Drag.YAxis
                                    onPressed: (mouse) => {
                                        root.draggingAddress = windowRow.modelData.address;
                                        windowRow.Drag.active = true;
                                        windowRow.Drag.source = windowRow;
                                        windowRow.Drag.hotSpot.x = mouse.x;
                                        windowRow.Drag.hotSpot.y = mouse.y;
                                    }
                                    onReleased: {
                                        const targetKey = root.draggingTargetKey;
                                        windowRow.Drag.active = false;
                                        root.resetDragging();
                                        windowRow.x = 0;
                                        windowRow.y = 0;
                                        const sourceKey = root.wsKeyFor(windowRow.modelData);
                                        if (targetKey !== "" && targetKey !== sourceKey) {
                                            const targetSection = root.workspaceSections.find(s => s.key === targetKey);
                                            if (!targetSection) return;
                                            const wsDesignator = targetSection.special ? `"${targetSection.name}"` : `${targetSection.id}`;
                                            Hyprland.dispatch(`hl.dsp.window.move({window="address:${windowRow.modelData.address}",workspace=${wsDesignator},follow=false})`);
                                        }
                                    }
                                    onClicked: (event) => {
                                        if (event.button === Qt.LeftButton) {
                                            GlobalStates.windowListOpen = false;
                                            Hyprland.dispatch(`hl.dsp.focus({window="address:${windowRow.modelData.address}"})`);
                                            event.accepted = true;
                                        } else if (event.button === Qt.MiddleButton) {
                                            Hyprland.dispatch(`hl.dsp.window.close({window="address:${windowRow.modelData.address}"})`);
                                            event.accepted = true;
                                        }
                                    }

                                    StyledToolTip {
                                        extraVisibleCondition: false
                                        alternativeVisibleCondition: dragArea.containsMouse && !windowRow.Drag.active
                                        text: `${windowRow.modelData.title}\n[${windowRow.modelData.class}] ${windowRow.modelData.xwayland ? "[XWayland] " : ""}`
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

                            Rectangle {
                                id: line
                                width: parent.width
                                height: 1
                                anchors.verticalCenter: parent.verticalCenter
                                color: Appearance.colors.colOutlineVariant
                            }
                            StyledText {
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                                anchors.rightMargin: Appearance.sizes.hyprlandGapsOut * 3
                                text: section.sectionLabel
                                color: Appearance.colors.colOutlineVariant
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
