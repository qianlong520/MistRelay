import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme" as ThemeSystem

Button {
    id: root

    property bool active: false
    property string iconName: ""

    implicitHeight: ThemeSystem.Theme.navItemHeight
    leftPadding: 16
    rightPadding: 16
    hoverEnabled: true

    background: Rectangle {
        radius: ThemeSystem.Theme.radiusLarge
        color: root.active
               ? ThemeSystem.Theme.sidebarActiveFill
               : (root.hovered ? ThemeSystem.Theme.sidebarHoverFill : "transparent")
        border.width: 1
        border.color: root.active ? "#99c8f0" : "transparent"

        Behavior on color {
            ColorAnimation { duration: ThemeSystem.Theme.fastDuration }
        }
    }

    contentItem: RowLayout {
        spacing: 14

        Rectangle {
            Layout.preferredWidth: ThemeSystem.Theme.navGlyphBox
            Layout.preferredHeight: ThemeSystem.Theme.navGlyphBox
            radius: 12
            color: root.active ? "#ffffff" : ThemeSystem.Theme.sidebarHoverFill

            FluentNavIcon {
                anchors.centerIn: parent
                iconName: root.iconName
                iconColor: root.active ? ThemeSystem.Theme.colorPrimary : ThemeSystem.Theme.sidebarTextMuted
                iconSize: ThemeSystem.Theme.navGlyphSize
            }
        }

        Text {
            text: root.text
            color: root.active ? ThemeSystem.Theme.sidebarText : ThemeSystem.Theme.sidebarTextMuted
            font.pixelSize: ThemeSystem.Theme.navTextSize
            font.bold: root.active
            font.family: ThemeSystem.Theme.fontFamily
            Layout.fillWidth: true
            Layout.alignment: Qt.AlignVCenter
        }
    }
}
