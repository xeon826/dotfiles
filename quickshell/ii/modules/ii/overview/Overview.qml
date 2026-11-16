pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import Qt.labs.synchronizer
import QtQuick
import QtQuick.Controls
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope {
    id: overviewScope
    property bool dontAutoCancelSearch: false

    // One overview panel per monitor: each shows its own workspace group.
    property var instances: []

    function focusedPanel() {
        const focused = Hyprland.focusedMonitor?.name;
        const candidates = overviewScope.instances.filter(w => w.screen?.name === focused);
        return candidates[0] ?? overviewScope.instances[0] ?? null;
    }

    function setSearchingText(text) {
        const panel = overviewScope.focusedPanel();
        if (!panel) return;
        panel.setSearchingText(text);
    }

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: panelWindow
            required property ShellScreen modelData
            screen: modelData
            readonly property HyprlandMonitor monitor: Hyprland.monitorFor(panelWindow.screen)

            property string searchingText: ""
            visible: GlobalStates.overviewOpen

            WlrLayershell.namespace: "quickshell:overview"
            WlrLayershell.layer: WlrLayer.Top
            WlrLayershell.keyboardFocus: GlobalStates.overviewOpen ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None
            color: "transparent"

            mask: Region {
                item: GlobalStates.overviewOpen ? columnLayout : null
            }

            anchors {
                top: true
                bottom: true
                left: true
                right: true
            }

            Component.onCompleted: overviewScope.instances.push(panelWindow)
            Component.onDestruction: {
                const idx = overviewScope.instances.indexOf(panelWindow);
                if (idx !== -1) overviewScope.instances.splice(idx, 1);
            }

            function setSearchingText(text) {
                searchWidget.setSearchingText(text);
                searchWidget.focusFirstItem();
            }

            Connections {
                target: GlobalStates
                function onOverviewOpenChanged() {
                    if (!GlobalStates.overviewOpen) {
                        searchWidget.disableExpandAnimation();
                        overviewScope.dontAutoCancelSearch = false;
                        GlobalFocusGrab.dismiss();
                    } else {
                        if (!overviewScope.dontAutoCancelSearch) {
                            searchWidget.cancelSearch();
                        }
                        GlobalFocusGrab.addDismissable(panelWindow);
                    }
                }
            }

            Connections {
                target: GlobalFocusGrab
                function onDismissed() {
                    GlobalStates.overviewOpen = false;
                }
            }
            implicitWidth: columnLayout.implicitWidth
            implicitHeight: columnLayout.implicitHeight

            Column {
                id: columnLayout
                visible: GlobalStates.overviewOpen
                anchors {
                    horizontalCenter: parent.horizontalCenter
                    top: parent.top
                }
                spacing: -8

                Keys.onPressed: event => {
                    if (event.key === Qt.Key_Escape) {
                        GlobalStates.overviewOpen = false;
                    } else if (event.key === Qt.Key_Left) {
                        if (!panelWindow.searchingText)
                            Hyprland.dispatch(`hl.dsp.focus({workspace="r-1"})`);
                    } else if (event.key === Qt.Key_Right) {
                        if (!panelWindow.searchingText)
                            Hyprland.dispatch(`hl.dsp.focus({workspace="r+1"})`);
                    }
                }

                SearchWidget {
                    id: searchWidget
                    anchors.horizontalCenter: parent.horizontalCenter
                    Synchronizer on searchingText {
                        property alias source: panelWindow.searchingText
                    }
                }

                Loader {
                    id: overviewLoader
                    anchors.horizontalCenter: parent.horizontalCenter
                    active: GlobalStates.overviewOpen && (Config?.options.overview.enable ?? true)
                    sourceComponent: OverviewWidget {
                        screen: panelWindow.screen
                        visible: (panelWindow.searchingText == "")
                    }
                }
            }
        }
    }

    function toggleClipboard() {
        if (GlobalStates.overviewOpen && overviewScope.dontAutoCancelSearch) {
            GlobalStates.overviewOpen = false;
            return;
        }
        overviewScope.dontAutoCancelSearch = true;
        overviewScope.setSearchingText(Config.options.search.prefix.clipboard);
        GlobalStates.overviewOpen = true;
    }

    function toggleEmojis() {
        if (GlobalStates.overviewOpen && overviewScope.dontAutoCancelSearch) {
            GlobalStates.overviewOpen = false;
            return;
        }
        overviewScope.dontAutoCancelSearch = true;
        overviewScope.setSearchingText(Config.options.search.prefix.emojis);
        GlobalStates.overviewOpen = true;
    }

    IpcHandler {
        target: "search"

        function toggle() {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
        function workspacesToggle() {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
        function close() {
            GlobalStates.overviewOpen = false;
        }
        function open() {
            GlobalStates.overviewOpen = true;
        }
        function toggleReleaseInterrupt() {
            GlobalStates.superReleaseMightTrigger = false;
        }
        function clipboardToggle() {
            overviewScope.toggleClipboard();
        }
    }

    GlobalShortcut {
        name: "searchToggle"
        description: "Toggles search on press"

        onPressed: {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
    }
    GlobalShortcut {
        name: "overviewWorkspacesClose"
        description: "Closes overview on press"

        onPressed: {
            GlobalStates.overviewOpen = false;
        }
    }
    GlobalShortcut {
        name: "overviewWorkspacesToggle"
        description: "Toggles overview on press"

        onPressed: {
            GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
        }
    }
    // Disabled: overview toggle on super key release
    // GlobalShortcut {
    //     name: "searchToggleRelease"
    //     description: "Toggles search on release"
    //
    //     onPressed: {
    //         GlobalStates.superReleaseMightTrigger = true;
    //     }
    //
    //     onReleased: {
    //         if (!GlobalStates.superReleaseMightTrigger) {
    //             GlobalStates.superReleaseMightTrigger = true;
    //             return;
    //         }
    //         GlobalStates.overviewOpen = !GlobalStates.overviewOpen;
    //     }
    // }
    // GlobalShortcut {
    //     name: "searchToggleReleaseInterrupt"
    //     description: "Interrupts possibility of search being toggled on release. " + "This is necessary because GlobalShortcut.onReleased in quickshell triggers whether or not you press something else while holding the key. " + "To make sure this works consistently, use binditn = MODKEYS, catchall in an automatically triggered submap that includes everything."
    //
    //     onPressed: {
    //         GlobalStates.superReleaseMightTrigger = false;
    //     }
    // }
    GlobalShortcut {
        name: "overviewClipboardToggle"
        description: "Toggle clipboard query on overview widget"

        onPressed: {
            overviewScope.toggleClipboard();
        }
    }

    GlobalShortcut {
        name: "overviewEmojiToggle"
        description: "Toggle emoji query on overview widget"

        onPressed: {
            overviewScope.toggleEmojis();
        }
    }
}
