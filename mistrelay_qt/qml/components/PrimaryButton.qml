import QtQuick
import QtQuick.Controls
import "../theme" as ThemeSystem

Button {
    id: root

    implicitHeight: ThemeSystem.Theme.controlHeightLarge
    implicitWidth: 140
    hoverEnabled: true

    font.family: ThemeSystem.Theme.fontFamily
    font.pixelSize: 15
    font.bold: true

    contentItem: Text {
        text: root.text
        font: root.font
        color: "#ffffff"
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    background: Item {
        Rectangle {
            anchors.fill: parent
            y: root.down ? 5 : 8
            radius: ThemeSystem.Theme.radiusMedium
            color: ThemeSystem.Theme.colorPrimaryDark
            opacity: root.enabled ? (root.down ? 0.12 : 0.16) : 0.06
        }

        Rectangle {
            anchors.fill: parent
            radius: ThemeSystem.Theme.radiusMedium
            color: !root.enabled
                   ? "#b8cce0"
                   : root.down
                     ? ThemeSystem.Theme.colorPrimaryPressed
                     : (root.hovered ? ThemeSystem.Theme.colorPrimaryHover : ThemeSystem.Theme.colorPrimary)
            border.width: 1
            border.color: root.enabled ? "#85ffffff" : "#48ffffff"
            opacity: 1.0
            scale: root.down ? 0.985 : (root.hovered ? 1.01 : 1.0)
            y: root.down ? 1 : 0

            Behavior on scale {
                NumberAnimation { duration: ThemeSystem.Theme.fastDuration }
            }

            Behavior on y {
                NumberAnimation { duration: ThemeSystem.Theme.fastDuration }
            }
        }
    }
}
