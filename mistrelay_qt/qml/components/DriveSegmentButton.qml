import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme" as ThemeSystem

Button {
    id: root

    property string iconName: ""
    property bool selected: false

    implicitHeight: 30
    implicitWidth: contentRow.implicitWidth + 22
    leftPadding: 0
    rightPadding: 0
    hoverEnabled: true

    font.family: ThemeSystem.Theme.fontFamily
    font.pixelSize: 12
    font.bold: true

    background: Rectangle {
        radius: 11
        color: !root.enabled
               ? "#edf1f6"
               : root.selected
                 ? ThemeSystem.Theme.colorPrimary
                 : root.down
                   ? "#e9f1fb"
                   : (root.hovered ? "#f5f8fc" : "transparent")
        border.width: root.selected ? 0 : 1
        border.color: root.selected ? "transparent" : (root.hovered ? "#d3deec" : "transparent")

        Behavior on color {
            ColorAnimation { duration: ThemeSystem.Theme.fastDuration }
        }
    }

    contentItem: Item {
        implicitWidth: contentRow.implicitWidth
        implicitHeight: contentRow.implicitHeight

        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: 6

            FluentNavIcon {
                visible: root.iconName.length > 0
                iconName: root.iconName
                iconColor: root.selected ? "#ffffff" : ThemeSystem.Theme.textSecondary
                iconSize: 14
            }

            Text {
                text: root.text
                color: root.selected ? "#ffffff" : ThemeSystem.Theme.textPrimary
                font: root.font
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
            }
        }
    }
}
