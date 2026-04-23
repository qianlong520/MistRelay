import QtQuick
import QtQuick.Layouts
import "../theme" as ThemeSystem

ColumnLayout {
    id: root

    property string eyebrow: ""
    property string title: ""
    property string description: ""

    spacing: 6

    Text {
        visible: root.eyebrow.length > 0
        text: root.eyebrow
        color: ThemeSystem.Theme.colorPrimary
        font.pixelSize: 12
        font.bold: true
        font.family: ThemeSystem.Theme.fontFamily
    }

    Text {
        Layout.fillWidth: true
        text: root.title
        color: ThemeSystem.Theme.textPrimary
        font.pixelSize: 28
        font.bold: true
        wrapMode: Text.WordWrap
        font.family: ThemeSystem.Theme.fontFamily
    }

    Text {
        visible: root.description.length > 0
        Layout.fillWidth: true
        text: root.description
        color: ThemeSystem.Theme.textSecondary
        font.pixelSize: 14
        wrapMode: Text.WordWrap
        lineHeight: 1.25
        font.family: ThemeSystem.Theme.fontFamily
    }
}
