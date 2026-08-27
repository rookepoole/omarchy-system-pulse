import QtQuick
import Quickshell
import Quickshell.Io
import qs.Ui

BarWidget {
    id: root
    moduleName: "io.github.rookepoole.system-pulse"

    property real loadOne: 0
    property int memoryPercent: 0
    property int diskPercent: 0
    property string lastError: ""
    readonly property int pressure: Math.max(memoryPercent, diskPercent)
    readonly property bool opened: panelLoader.item ? panelLoader.item.opened === true : false
    readonly property bool popoutSwitchClosing: panelLoader.item ? panelLoader.item.popoutSwitchClosing === true : false

    function open() {
        if (panelLoader.item)
            panelLoader.item.open();
    }
    function close() {
        if (panelLoader.item)
            panelLoader.item.close();
    }
    function toggle() {
        if (panelLoader.item)
            panelLoader.item.toggle();
    }
    function closeForPopoutSwitch() {
        if (panelLoader.item)
            panelLoader.item.closeForPopoutSwitch();
    }
    function refresh() {
        if (!probe.running)
            probe.running = true;
    }
    function updateMetrics(raw) {
        var lines = String(raw || "").trim().split("\n");
        if (lines.length < 3) {
            lastError = "Probe returned incomplete data";
            return;
        }
        loadOne = Number(lines[0]) || 0;
        memoryPercent = Math.max(0, Math.min(100, Number(lines[1]) || 0));
        diskPercent = Math.max(0, Math.min(100, Number(lines[2]) || 0));
        lastError = "";
    }
    function injectPanel() {
        if (!panelLoader.item)
            return;
        panelLoader.item.bar = root.bar;
        panelLoader.item.anchorItem = button;
        panelLoader.item.hostWidget = root;
    }

    implicitWidth: button.implicitWidth
    implicitHeight: button.implicitHeight
    onBarChanged: injectPanel()
    Component.onCompleted: refresh()

    Process {
        id: probe
        command: ["sh", "-c", "awk '{print $1}' /proc/loadavg; awk '/MemTotal/{t=$2}/MemAvailable/{a=$2}END{if(t>0)printf \"%.0f\\n\",(t-a)*100/t;else print 0}' /proc/meminfo; df -P / | awk 'NR==2{gsub(/%/,\"\",$5);print $5}'"]
        stdout: StdioCollector {
            waitForEnd: true
            onStreamFinished: root.updateMetrics(text)
        }
        stderr: StdioCollector {
            waitForEnd: true
            onStreamFinished: if (String(text || "").trim())
                root.lastError = String(text).trim()
        }
    }

    Timer {
        interval: 5000
        running: true
        repeat: true
        onTriggered: root.refresh()
    }

    Loader {
        id: panelLoader
        active: true
        source: Qt.resolvedUrl("Panel.qml")
        visible: false
        onLoaded: {
            root.injectPanel();
            Qt.callLater(root.injectPanel);
        }
    }

    WidgetButton {
        id: button
        anchors.fill: parent
        bar: root.bar
        text: root.pressure >= 90 ? "♥!" : root.pressure >= 75 ? "♥·" : "♥"
        tooltipText: "System Pulse — " + root.memoryPercent + "% memory, " + root.diskPercent + "% disk"
        onPressed: root.toggle()
    }
}
