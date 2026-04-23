import QtQuick
import QtQuick.Layouts
import "../theme" as ThemeSystem

Rectangle {
    id: root

    signal routeSelected(string route)

    property string currentRoute: "dashboard"

    color: ThemeSystem.Theme.sidebarStart
    border.width: 1
    border.color: ThemeSystem.Theme.sidebarBorder
    radius: ThemeSystem.Theme.radiusXLarge
    implicitWidth: 264

    ColumnLayout {
        anchors.fill: parent
        anchors.margins: 12
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 82
            radius: ThemeSystem.Theme.radiusLarge
            color: "#ffffffde"
            border.width: 1
            border.color: ThemeSystem.Theme.cardBorder

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 18
                anchors.rightMargin: 18
                spacing: 14

                Rectangle {
                    Layout.preferredWidth: 44
                    Layout.preferredHeight: 44
                    radius: 14
                    color: ThemeSystem.Theme.colorPrimary

                    FluentNavIcon {
                        anchors.centerIn: parent
                        iconName: "dashboard"
                        iconColor: ThemeSystem.Theme.textOnAccent
                        iconSize: 20
                    }
                }

                ColumnLayout {
                    spacing: 1

                    Text {
                        text: "MistRelay"
                        color: ThemeSystem.Theme.textPrimary
                        font.pixelSize: 19
                        font.bold: true
                        font.family: ThemeSystem.Theme.fontFamily
                    }

                    Text {
                        text: "Desktop"
                        color: ThemeSystem.Theme.textSecondary
                        font.pixelSize: 12
                        font.family: ThemeSystem.Theme.fontFamily
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 14
            Layout.leftMargin: 2
            Layout.rightMargin: 2
            spacing: 8

            SidebarButton {
                Layout.fillWidth: true
                text: "\u4eea\u8868\u677f"
                iconName: "dashboard"
                active: root.currentRoute === "dashboard"
                onClicked: root.routeSelected("dashboard")
            }

            SidebarButton {
                Layout.fillWidth: true
                text: "\u4efb\u52a1\u4e2d\u5fc3"
                iconName: "downloads"
                active: root.currentRoute === "downloads"
                onClicked: root.routeSelected("downloads")
            }

            SidebarButton {
                Layout.fillWidth: true
                text: "\u6211\u7684\u7f51\u76d8"
                iconName: "drive"
                active: root.currentRoute === "drive"
                onClicked: root.routeSelected("drive")
            }

            SidebarButton {
                Layout.fillWidth: true
                text: "\u7cfb\u7edf\u8bbe\u7f6e"
                iconName: "settings"
                active: root.currentRoute === "settings"
                onClicked: root.routeSelected("settings")
            }
        }

        Item {
            Layout.fillHeight: true
        }
    }
}
