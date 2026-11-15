pragma ComponentBehavior: Bound
import qs
import qs.modules.common
import qs.modules.common.functions
import qs.services
import QtQuick
import Quickshell
import Quickshell.Wayland
import Quickshell.Hyprland

/**
 * Breathing dashed border around the region currently being recorded (or the
 * whole monitor for fullscreen recordings). Shown only on the recorded
 * monitor; region/monitor state comes from record.sh via ScreenRecorder.
 */
Scope {
    id: root

    Variants {
        model: Quickshell.screens

        PanelWindow {
            id: win

            required property var modelData
            readonly property HyprlandMonitor hyprlandMonitor: Hyprland.monitorFor(win.screen)
            readonly property bool active: ScreenRecorder.recording && ScreenRecorder.region !== null && ScreenRecorder.region.monitor === win.modelData.name
            readonly property color borderColor: ColorUtils.mix(
                Appearance.m3colors.darkmode ? Appearance.colors.colOnLayer0 : Appearance.colors.colLayer0,
                Appearance.m3colors.darkmode ? Appearance.colors.colSecondary : Appearance.colors.colOnSecondary,
                0.5)

            screen: modelData
            visible: active
            color: "transparent"
            exclusionMode: ExclusionMode.Ignore
            mask: Region {} // Fully click-through
            WlrLayershell.namespace: "quickshell:recordingIndicator"
            WlrLayershell.layer: WlrLayer.Top
            anchors {
                left: true
                right: true
                top: true
                bottom: true
            }

            Loader {
                anchors.fill: parent
                active: win.active
                sourceComponent: RectCornersSelectionDetails {
                    // Same look as the old Phase.Post indicator after snipping
                    regionX: ScreenRecorder.region.x - win.hyprlandMonitor.x
                    regionY: ScreenRecorder.region.y - win.hyprlandMonitor.y
                    regionWidth: ScreenRecorder.region.w
                    regionHeight: ScreenRecorder.region.h
                    mouseX: -1
                    mouseY: -1
                    color: win.borderColor
                    overlayColor: "transparent"
                    breathingBorderOnly: true
                }
            }
        }
    }
}
