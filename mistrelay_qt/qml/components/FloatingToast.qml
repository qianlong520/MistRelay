import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme" as ThemeSystem

Item {
    id: root

    property string level: "info"
    property string message: ""
    property bool open: false

    function toneColor() {
        switch (level) {
        case "success":
            return ThemeSystem.Theme.colorSuccess
        case "warning":
            return ThemeSystem.Theme.colorWarning
        case "danger":
            return ThemeSystem.Theme.colorDanger
        default:
            return ThemeSystem.Theme.colorInfo
        }
    }

    function toneSoftColor() {
        switch (level) {
        case "success":
            return ThemeSystem.Theme.successSoft
        case "warning":
            return ThemeSystem.Theme.warningSoft
        case "danger":
            return ThemeSystem.Theme.dangerSoft
        default:
            return ThemeSystem.Theme.infoSoft
        }
    }

    function iconText() {
        return level === "danger" ? "!" : "i"
    }

    function showMessage(nextLevel, nextMessage) {
        level = nextLevel
        message = nextMessage
        open = true
        hideTimer.interval = nextLevel === "warning" || nextLevel === "danger" ? 3200 : 2400
        hideTimer.restart()
    }

    anchors.top: parent.top
    anchors.horizontalCenter: parent.horizontalCenter
    anchors.topMargin: 22
    width: Math.max(320, Math.min(parent.width - 48, 420))
    height: toastCard.implicitHeight
    visible: open
    opacity: open ? 1 : 0
    y: open ? 0 : -12

    Behavior on opacity {
        NumberAnimation { duration: ThemeSystem.Theme.mediumDuration }
    }

    Behavior on y {
        NumberAnimation { duration: ThemeSystem.Theme.mediumDuration }
    }

    Rectangle {
        id: toastCard

        width: parent.width
        radius: ThemeSystem.Theme.radiusMedium
        color: root.toneSoftColor()
        border.width: 1
        border.color: Qt.rgba(root.toneColor().r, root.toneColor().g, root.toneColor().b, 0.24)
        opacity: 0.97
        layer.enabled: true
        layer.smooth: true

        implicitHeight: content.implicitHeight + 18

        RowLayout {
            id: content

            anchors.fill: parent
            anchors.leftMargin: 12
            anchors.rightMargin: 14
            anchors.topMargin: 9
            anchors.bottomMargin: 9
            spacing: 10

            Rectangle {
                Layout.alignment: Qt.AlignTop
                Layout.preferredWidth: 18
                Layout.preferredHeight: 18
                radius: 9
                color: Qt.rgba(root.toneColor().r, root.toneColor().g, root.toneColor().b, 0.14)

                Text {
                    anchors.centerIn: parent
                    text: root.iconText()
                    color: root.toneColor()
                    font.pixelSize: 11
                    font.bold: true
                    font.family: ThemeSystem.Theme.fontFamily
                }
            }

            Text {
                Layout.fillWidth: true
                text: root.message
                wrapMode: Text.WordWrap
                maximumLineCount: 3
                elide: Text.ElideRight
                color: ThemeSystem.Theme.textPrimary
                font.pixelSize: 13
                font.family: ThemeSystem.Theme.fontFamily
            }
        }
    }

    Timer {
        id: hideTimer

        interval: 2400
        repeat: false
        onTriggered: root.open = false
    }
}
