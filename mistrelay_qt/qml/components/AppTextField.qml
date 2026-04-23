import QtQuick
import QtQuick.Controls
import "../theme" as ThemeSystem

TextField {
    id: root

    implicitHeight: ThemeSystem.Theme.controlHeight
    hoverEnabled: true
    color: ThemeSystem.Theme.textPrimary
    selectionColor: ThemeSystem.Theme.colorPrimary
    selectedTextColor: "#ffffff"
    font.family: ThemeSystem.Theme.fontFamily
    font.pixelSize: 15
    placeholderTextColor: ThemeSystem.Theme.textTertiary
    leftPadding: 16
    rightPadding: 16
    selectByMouse: true

    background: Item {
        Rectangle {
            anchors.fill: parent
            radius: ThemeSystem.Theme.radiusMedium
            color: ThemeSystem.Theme.colorPrimary
            opacity: root.activeFocus ? 0.08 : 0.0
            scale: root.activeFocus ? 1.02 : 1.0

            Behavior on opacity {
                NumberAnimation { duration: ThemeSystem.Theme.mediumDuration }
            }

            Behavior on scale {
                NumberAnimation { duration: ThemeSystem.Theme.mediumDuration }
            }
        }

        Rectangle {
            anchors.fill: parent
            radius: ThemeSystem.Theme.radiusMedium
            color: root.enabled ? "#ffffff" : "#eef2f6"
            border.width: root.activeFocus ? 2 : 1
            border.color: root.activeFocus
                          ? ThemeSystem.Theme.colorPrimary
                          : (root.hovered ? "#b9cde0" : ThemeSystem.Theme.lineColor)
        }
    }
}
