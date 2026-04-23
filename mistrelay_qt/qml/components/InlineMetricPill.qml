import QtQuick
import QtQuick.Layouts
import "../theme" as ThemeSystem

Rectangle {
    id: root

    property string title: ""
    property string value: ""
    property string caption: ""
    property string tone: "primary"

    function toneColor() {
        switch (tone) {
        case "success":
            return ThemeSystem.Theme.colorSuccess
        case "warning":
            return ThemeSystem.Theme.colorWarning
        case "danger":
            return ThemeSystem.Theme.colorDanger
        case "info":
            return ThemeSystem.Theme.colorInfo
        default:
            return ThemeSystem.Theme.colorPrimary
        }
    }

    function toneFill() {
        var color = toneColor()
        return Qt.rgba(color.r, color.g, color.b, 0.08)
    }

    implicitWidth: 148
    implicitHeight: 84
    radius: 18
    color: toneFill()
    border.width: 1
    border.color: Qt.rgba(toneColor().r, toneColor().g, toneColor().b, 0.18)

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 14
        spacing: 4

        RowLayout {
            Layout.fillWidth: true
            spacing: 8

            Rectangle {
                Layout.preferredWidth: 8
                Layout.preferredHeight: 8
                radius: 4
                color: root.toneColor()
            }

            Text {
                Layout.fillWidth: true
                text: root.title
                color: ThemeSystem.Theme.textSecondary
                font.pixelSize: 12
                font.bold: true
                elide: Text.ElideRight
                font.family: ThemeSystem.Theme.fontFamily
            }
        }

        Text {
            text: root.value
            color: ThemeSystem.Theme.textPrimary
            font.pixelSize: 24
            font.bold: true
            font.family: ThemeSystem.Theme.fontFamily
        }

        Text {
            Layout.fillWidth: true
            text: root.caption
            color: ThemeSystem.Theme.textTertiary
            font.pixelSize: 12
            elide: Text.ElideRight
            font.family: ThemeSystem.Theme.fontFamily
        }
    }
}
