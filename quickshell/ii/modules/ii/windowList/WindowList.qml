pragma ComponentBehavior: Bound
import qs
import qs.services
import qs.modules.common
import qs.modules.common.widgets
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import Quickshell.Hyprland

Scope { // Scope
    id: root

    PanelWindow { // Window
        id: panelWindow
        visible: GlobalStates.windowListOpen

        function hide() {
            GlobalStates.windowListOpen = false;
        }

        exclusionMode: ExclusionMode.Normal
        exclusiveZone: 0
        implicitWidth: Appearance.sizes.sidebarWidth + Appearance.sizes.elevationMargin
        WlrLayershell.namespace: "quickshell:windowList"
        WlrLayershell.layer: WlrLayer.Top
        // Hyprland 0.49: OnDemand is Exclusive, Exclusive just breaks click-outside-to-close
        WlrLayershell.keyboardFocus: WlrKeyboardFocus.OnDemand
        color: "transparent"

        anchors {
            top: true
            left: true
            bottom: true
        }

        mask: Region {
            item: windowListBackground
        }

        onVisibleChanged: {
            if (visible) {
                GlobalFocusGrab.addDismissable(panelWindow);
            } else {
                GlobalFocusGrab.removeDismissable(panelWindow);
            }
        }
        Connections {
            target: GlobalFocusGrab
            function onDismissed() {
                panelWindow.hide();
            }
        }

        // Content
        StyledRectangularShadow {
            target: windowListBackground
            radius: windowListBackground.radius
        }
        Rectangle {
            id: windowListBackground
            focus: GlobalStates.windowListOpen
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.bottom: parent.bottom
            anchors.topMargin: Appearance.sizes.hyprlandGapsOut
            anchors.leftMargin: Appearance.sizes.hyprlandGapsOut
            anchors.bottomMargin: Appearance.sizes.hyprlandGapsOut
            width: Appearance.sizes.sidebarWidth - Appearance.sizes.hyprlandGapsOut - Appearance.sizes.elevationMargin
            color: Appearance.colors.colBackgroundSurfaceContainer
            radius: Appearance.rounding.large

            Keys.onPressed: (event) => {
                if (event.key === Qt.Key_Escape) {
                    panelWindow.hide();
                }
            }

            WindowListContent {
                id: windowListContent
                anchors.fill: parent
                anchors.margins: Appearance.sizes.hyprlandGapsOut * 2
                scopeRoot: root
                panelWindow: panelWindow
            }
        }
    }

    IpcHandler {
        target: "windowList"

        function toggle(): void {
            GlobalStates.windowListOpen = !GlobalStates.windowListOpen;
        }
        function close(): void {
            GlobalStates.windowListOpen = false;
        }
        function open(): void {
            GlobalStates.windowListOpen = true;
        }
    }

    GlobalShortcut {
        name: "windowListToggle"
        description: "Toggles the window list sidebar"

        onPressed: {
            GlobalStates.windowListOpen = !GlobalStates.windowListOpen;
        }
    }
}
