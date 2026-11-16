pragma ComponentBehavior: Bound
import qs
import qs.modules.common
import qs.services
import QtQuick
import Quickshell
import Quickshell.Widgets
import Quickshell.Wayland

/**
 * Super-hold workspace deck: overlay window directly below (or above, for
 * bottom bars) the bar's workspaces section, shown while workspace numbers
 * are held. Per workspace button: the main window icon slides down flush
 * under its button and the remaining windows stack straight downward under
 * it in a fully opaque vertical column (no overlap, no jitter, capped).
 * Fully click-through: it must never eat input while Super is held.
 */
PanelWindow {
    id: root

    required property var workspacesRoot

    readonly property bool downward: !(Config.options?.bar.bottom ?? false)
    readonly property real buttonW: workspacesRoot.workspaceButtonWidth
    readonly property real mainCardSize: workspacesRoot.workspaceIconSize
    readonly property real cardSize: buttonW * 0.55
    readonly property real firstStep: 0 // flush under the bar, no gap
    readonly property real deckExtent: firstStep + workspacesRoot.deckMaxCards * cardSize
    readonly property bool deckVisible: (workspacesRoot?.showNumbers ?? false) && workspacesRoot.deckCards.length > 0
    property int revealedCount: 0

    function cardY(slot, size) {
        const offset = firstStep + slot * cardSize; // straight stack, no overlap
        return downward ? offset : deckExtent - offset - size;
    }

    function cardX(slot) {
        const size = slot === 0 ? mainCardSize : cardSize;
        return (buttonW - size) / 2; // column-relative: column Item already offsets by workspaceIndex
    }

    screen: workspacesRoot.QsWindow.window?.screen ?? null
    visible: deckVisible || collapseDelay.running
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    exclusiveZone: -1
    mask: Region {} // Fully click-through
    WlrLayershell.layer: WlrLayer.Top
    WlrLayershell.namespace: "quickshell:workspaceDeck"

    implicitWidth: workspacesRoot.workspacesShown * buttonW
    implicitHeight: deckExtent

    anchors {
        left: true
        top: root.downward
        bottom: !root.downward
    }

    margins {
        left: workspacesRoot.deckGlobalX
        // barHeight: flush against the visible bar strip (the rounding strip
        // below it is transparent midspan — no gap to the nav)
        top: root.downward ? Appearance.sizes.barHeight : 0
        bottom: root.downward ? 0 : Appearance.sizes.barHeight
    }

    onDeckVisibleChanged: {
        if (deckVisible) {
            collapseDelay.stop();
            revealedCount = 0;
            revealTimer.restart();
        } else {
            revealTimer.stop();
            collapseDelay.restart();
        }
    }

    Timer {
        id: revealTimer
        interval: 45
        repeat: true
        onTriggered: {
            root.revealedCount++;
            if (root.revealedCount >= root.workspacesRoot.deckMaxCards) revealTimer.stop();
        }
    }

    Timer {
        id: collapseDelay
        interval: 220 // keep the window mapped briefly so cards animate out
        onTriggered: root.revealedCount = 0
    }

    Item {
        anchors.fill: parent

        Repeater {
            model: root.workspacesRoot.workspacesShown

            Item {
                id: column

                required property int index
                readonly property var cards: root.workspacesRoot.deckCards.filter(c => c.workspaceIndex === index)

                x: index * root.buttonW
                y: 0
                width: root.buttonW
                height: root.deckExtent

                Repeater {
                    model: column.cards

                    Item {
                        id: card

                        required property var modelData
                        readonly property int slot: modelData.slot
                        readonly property real size: slot === 0 ? root.mainCardSize : root.cardSize
                        readonly property string iconSource: AppSearch.windowIconSource(card.modelData.win.class ?? "")
                        readonly property bool hasIcon: iconSource !== ""
                        readonly property bool shown: slot < root.revealedCount && hasIcon

                        x: root.cardX(slot)
                        y: shown ? root.cardY(slot, size) : (root.downward ? -size : root.deckExtent)
                        width: size
                        height: size
                        opacity: shown ? 1 : 0
                        scale: shown ? 1 : 0.5
                        visible: opacity > 0

                        Behavior on y {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                        Behavior on opacity {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }
                        Behavior on scale {
                            animation: Appearance.animation.elementMoveFast.numberAnimation.createObject(this)
                        }

                        // Fully opaque: no monochrome tint overlay here
                        IconImage {
                            anchors.fill: parent
                            source: card.iconSource
                            implicitSize: card.size
                        }
                    }
                }
            }
        }
    }
}
