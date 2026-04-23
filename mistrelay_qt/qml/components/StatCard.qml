import QtQuick
import QtQuick.Layouts
import "../theme" as ThemeSystem

GlassCard {
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

    backgroundColor: "#fbfdff"
    borderColor: ThemeSystem.Theme.cardBorder
    shadowOpacity: 0.1
    shadowOffsetY: 12
    shadowSpread: 20

    ColumnLayout {
        anchors.fill: parent
        spacing: 14

        RowLayout {
            Layout.fillWidth: true
            spacing: 10

            Rectangle {
                Layout.preferredWidth: 36
                Layout.preferredHeight: 36
                radius: 12
                color: Qt.rgba(root.toneColor().r, root.toneColor().g, root.toneColor().b, 0.12)

                Rectangle {
                    anchors.centerIn: parent
                    width: 14
                    height: 14
                    radius: 7
                    color: root.toneColor()
                }
            }

            Text {
                text: root.title
                color: ThemeSystem.Theme.textSecondary
                font.pixelSize: 14
                font.family: ThemeSystem.Theme.fontFamily
                Layout.fillWidth: true
                wrapMode: Text.WordWrap
            }
        }

        Text {
            text: root.value
            color: ThemeSystem.Theme.textPrimary
            font.pixelSize: 36
            font.bold: true
            font.family: ThemeSystem.Theme.fontFamily
        }

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 6
            radius: 3
            color: "#edf3fa"

            Rectangle {
                width: Math.max(56, parent.width * 0.34)
                height: parent.height
                radius: parent.radius
                color: root.toneColor()
            }
        }

        Text {
            text: root.caption
            color: ThemeSystem.Theme.textTertiary
            font.pixelSize: 13
            wrapMode: Text.WordWrap
            font.family: ThemeSystem.Theme.fontFamily
        }
    }
}
