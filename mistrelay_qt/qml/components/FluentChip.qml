import QtQuick
import QtQuick.Controls
import "../theme" as ThemeSystem

Button {
    id: root

    property bool active: false

    implicitHeight: 34
    leftPadding: 14
    rightPadding: 14
    hoverEnabled: true

    background: Rectangle {
        radius: 999
        color: root.active
               ? ThemeSystem.Theme.sidebarActiveFill
               : (root.hovered ? ThemeSystem.Theme.sidebarHoverFill : "#ffffff")
        border.width: 1
        border.color: root.active ? "#9dc7f0" : ThemeSystem.Theme.cardBorder

        Behavior on color {
            ColorAnimation { duration: ThemeSystem.Theme.fastDuration }
        }
    }

    contentItem: Text {
        text: root.text
        color: root.active ? ThemeSystem.Theme.colorPrimary : ThemeSystem.Theme.textSecondary
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        font.pixelSize: 13
        font.bold: root.active
        font.family: ThemeSystem.Theme.fontFamily
    }
}
