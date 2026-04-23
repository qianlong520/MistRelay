import QtQuick
import QtQuick.Layouts
import "../theme" as ThemeSystem

Rectangle {
    id: root

    property string tone: "info"
    property string title: ""
    property string description: ""

    function toneColor() {
        switch (tone) {
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
        switch (tone) {
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

    radius: ThemeSystem.Theme.radiusLarge
    color: toneSoftColor()
    border.width: 1
    border.color: Qt.rgba(toneColor().r, toneColor().g, toneColor().b, 0.28)
    implicitHeight: bannerLayout.implicitHeight + 24

    RowLayout {
        id: bannerLayout
        anchors.fill: parent
        anchors.margins: 14
        spacing: 12

        Rectangle {
            Layout.preferredWidth: 30
            Layout.preferredHeight: 30
            radius: 10
            color: Qt.rgba(root.toneColor().r, root.toneColor().g, root.toneColor().b, 0.14)

            Text {
                anchors.centerIn: parent
                text: root.tone === "danger" ? "!" : (root.tone === "warning" ? "!" : "i")
                color: root.toneColor()
                font.pixelSize: 14
                font.bold: true
                font.family: ThemeSystem.Theme.fontFamily
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            spacing: 2

            Text {
                visible: root.title.length > 0
                Layout.fillWidth: true
                text: root.title
                color: ThemeSystem.Theme.textPrimary
                font.pixelSize: 14
                font.bold: true
                wrapMode: Text.WordWrap
                font.family: ThemeSystem.Theme.fontFamily
            }

            Text {
                Layout.fillWidth: true
                text: root.description
                color: ThemeSystem.Theme.textSecondary
                font.pixelSize: 13
                wrapMode: Text.WordWrap
                lineHeight: 1.25
                font.family: ThemeSystem.Theme.fontFamily
            }
        }
    }
}
