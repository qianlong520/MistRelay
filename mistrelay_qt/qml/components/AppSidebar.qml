import QtQuick
import QtQuick.Layouts
import "../theme" as ThemeSystem

Rectangle {
    id: root

    signal routeSelected(string route)

    property string currentRoute: "dashboard"

    color: ThemeSystem.Theme.sidebarStart
    border.width: 0
    radius: 0
    implicitWidth: 252

    Rectangle {
        anchors.top: parent.top
        anchors.bottom: parent.bottom
        anchors.right: parent.right
        width: 1
        color: ThemeSystem.Theme.sidebarBorder
        opacity: 0.8
    }

    ColumnLayout {
        anchors.fill: parent
        anchors.leftMargin: 12
        anchors.rightMargin: 12
        anchors.topMargin: 0
        anchors.bottomMargin: 12
        spacing: 0

        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 58
            radius: 0
            color: "#f7faff"
            border.width: 0

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: ThemeSystem.Theme.sidebarBorder
                opacity: 0.75
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 34
                    Layout.preferredHeight: 34
                    radius: 10
                    color: "#dfefff"
                    border.width: 1
                    border.color: "#c3ddf3"

                    Image {
                        anchors.centerIn: parent
                        width: 22
                        height: 22
                        source: "../../../desktop/icons/icon.png"
                        fillMode: Image.PreserveAspectFit
                        smooth: true
                    }
                }

                ColumnLayout {
                    spacing: 1

                    Text {
                        text: "MistRelay"
                        color: ThemeSystem.Theme.textPrimary
                        font.pixelSize: 17
                        font.bold: true
                        font.family: ThemeSystem.Theme.fontFamily
                    }

                    Text {
                        text: "客户端"
                        color: ThemeSystem.Theme.textSecondary
                        font.pixelSize: 11
                        font.family: ThemeSystem.Theme.fontFamily
                    }
                }
            }
        }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.topMargin: 12
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
