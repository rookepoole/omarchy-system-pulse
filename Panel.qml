import QtQuick
import Quickshell
import qs.Commons
import qs.Ui

Panel {
    id: root
    moduleName: "io.github.rookepoole.system-pulse"
    manageIpc: false
    property var anchorItem: null
    property var hostWidget: null

    function open() {
        if (hostWidget)
            hostWidget.refresh();
        root.controller.show();
    }
    function close() {
        root.controller.hide();
    }
    function switchPanel(direction) {
        if (root.bar && typeof root.bar.switchPanelFrom === "function")
            return root.bar.switchPanelFrom(root.hostWidget || root, direction);
        return false;
    }

    component Meter: Column {
        required property string label
        required property real value
        width: parent ? parent.width : 0
        spacing: Style.space(5)
        Row {
            width: parent.width
            Text {
                text: label
                color: root.barForeground
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
                font.pixelSize: Style.font.body
            }
            Item {
                width: parent.width - parent.children[0].implicitWidth - parent.children[2].implicitWidth
                height: 1
            }
            Text {
                text: Math.round(value) + "%"
                color: root.barForeground
                font.bold: true
                font.family: root.bar ? root.bar.fontFamily : Style.font.family
            }
        }
        Rectangle {
            width: parent.width
            height: Style.space(8)
            radius: height / 2
            color: Qt.rgba(root.barForeground.r, root.barForeground.g, root.barForeground.b, 0.12)
            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, value / 100))
                height: parent.height
                radius: height / 2
                color: value >= 90 ? Color.urgent : value >= 75 ? "#f4b942" : Color.accent
                Behavior on width {
                    NumberAnimation {
                        duration: 260
                        easing.type: Easing.OutCubic
                    }
                }
            }
        }
    }

    KeyboardPanel {
        id: panel
        anchorItem: root.anchorItem
        owner: root.hostWidget || root
        bar: root.bar
        open: root.opened
        focusTarget: keyCatcher
        contentWidth: panel.fittedContentWidth(Style.space(320))
        contentHeight: panel.fittedContentHeight(content.implicitHeight + Style.space(18))

        PanelKeyCatcher {
            id: keyCatcher
            anchors.fill: parent
            onCloseRequested: root.close()
            onTabRequested: function (direction) {
                root.switchPanel(direction);
            }
            onActivateRequested: if (root.hostWidget)
                root.hostWidget.refresh()

            Column {
                id: content
                width: parent.width
                spacing: Style.space(14)
                Text {
                    text: "SYSTEM PULSE"
                    color: root.barForeground
                    font.bold: true
                    font.pixelSize: Style.font.subtitle
                    font.family: root.bar ? root.bar.fontFamily : Style.font.family
                }
                Text {
                    text: root.hostWidget ? Number(root.hostWidget.loadOne).toFixed(2) : "0.00"
                    color: Color.accent
                    font.bold: true
                    font.pixelSize: Style.font.displayLarge * 1.6
                    font.family: root.bar ? root.bar.fontFamily : Style.font.family
                }
                Text {
                    text: "one-minute load"
                    color: root.barForeground
                    opacity: 0.62
                    font.pixelSize: Style.font.caption
                    font.family: root.bar ? root.bar.fontFamily : Style.font.family
                }
                Meter {
                    label: "Memory"
                    value: root.hostWidget ? root.hostWidget.memoryPercent : 0
                }
                Meter {
                    label: "Root disk"
                    value: root.hostWidget ? root.hostWidget.diskPercent : 0
                }
                Text {
                    width: parent.width
                    text: root.hostWidget && root.hostWidget.lastError ? root.hostWidget.lastError : "Read-only local probe · refreshes every 5 seconds · Enter refreshes now"
                    color: root.hostWidget && root.hostWidget.lastError ? Color.urgent : root.barForeground
                    opacity: 0.64
                    wrapMode: Text.WordWrap
                    font.pixelSize: Style.font.caption
                    font.family: root.bar ? root.bar.fontFamily : Style.font.family
                }
            }
        }
    }
}
