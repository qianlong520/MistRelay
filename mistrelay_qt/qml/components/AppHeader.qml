import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme" as ThemeSystem

Rectangle {
    id: root

    signal logoutRequested()

    property string title: ""
    property string subtitle: ""
    property string userName: ""
    property string connectionState: "disconnected"
    readonly property string serverLabel: dashboardViewModel.serverBaseUrl.length > 0
                                          ? dashboardViewModel.serverBaseUrl.replace("http://", "").replace("https://", "")
                                          : "\u672a\u914d\u7f6e\u670d\u52a1\u5668"

    color: "#fbfdffea"
    border.width: 1
    border.color: ThemeSystem.Theme.cardBorder
    radius: ThemeSystem.Theme.radiusXLarge
    implicitHeight: 78

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 24
        anchors.rightMargin: 24
        spacing: 20

        RowLayout {
            spacing: 12

            Rectangle {
                Layout.preferredWidth: ThemeSystem.Theme.headerIconBox
                Layout.preferredHeight: ThemeSystem.Theme.headerIconBox
                radius: 12
                color: ThemeSystem.Theme.sidebarActiveFill

                FluentNavIcon {
                    anchors.centerIn: parent
                    iconName: "dashboard"
                    iconColor: ThemeSystem.Theme.colorPrimary
                    iconSize: ThemeSystem.Theme.headerIconSize
                }
            }

            ColumnLayout {
                spacing: 1

                Text {
                    text: root.title.length > 0 ? root.title : "\u5de5\u4f5c\u53f0"
                    color: ThemeSystem.Theme.textPrimary
                    font.pixelSize: 20
                    font.bold: true
                    font.family: ThemeSystem.Theme.fontFamily
                }

                Text {
                    text: root.subtitle.length > 0 ? root.subtitle : "\u6982\u89c8"
                    color: ThemeSystem.Theme.textSecondary
                    font.pixelSize: 13
                    font.family: ThemeSystem.Theme.fontFamily
                }
            }
        }

        Item {
            Layout.fillWidth: true
        }

        Rectangle {
            radius: ThemeSystem.Theme.radiusLarge
            color: "#ffffffdd"
            border.width: 1
            border.color: ThemeSystem.Theme.cardBorder
            implicitHeight: 44
            implicitWidth: 238

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                spacing: 10

                Rectangle {
                    Layout.preferredWidth: 12
                    Layout.preferredHeight: 12
                    radius: 6
                    color: root.connectionState === "connected"
                           ? ThemeSystem.Theme.colorSuccess
                           : root.connectionState === "connecting"
                             ? ThemeSystem.Theme.colorWarning
                             : ThemeSystem.Theme.colorDanger
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        Layout.fillWidth: true
                        text: root.serverLabel
                        color: ThemeSystem.Theme.textPrimary
                        font.pixelSize: 14
                        font.bold: true
                        elide: Text.ElideRight
                        font.family: ThemeSystem.Theme.fontFamily
                    }

                    Text {
                        text: root.connectionState === "connected"
                              ? "\u5df2\u8fde\u63a5\u5230\u670d\u52a1\u7aef"
                              : root.connectionState === "connecting"
                                ? "\u6b63\u5728\u5efa\u7acb\u8fde\u63a5"
                                : "\u5f53\u524d\u5904\u4e8e\u79bb\u7ebf\u72b6\u6001"
                        color: ThemeSystem.Theme.textSecondary
                        font.pixelSize: 12
                        font.family: ThemeSystem.Theme.fontFamily
                    }
                }
            }
        }

        Button {
            id: profileButton

            implicitHeight: 50
            implicitWidth: 176
            hoverEnabled: true

            background: Rectangle {
                radius: ThemeSystem.Theme.radiusLarge
                color: profileButton.down
                       ? ThemeSystem.Theme.sidebarHoverFill
                       : (profileButton.hovered ? "#f3f7fc" : "#ffffffdd")
                border.width: 1
                border.color: ThemeSystem.Theme.cardBorder

                Behavior on color {
                    ColorAnimation { duration: ThemeSystem.Theme.fastDuration }
                }
            }

            contentItem: RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 10
                anchors.rightMargin: 12
                spacing: 10

                Rectangle {
                    Layout.preferredWidth: 42
                    Layout.preferredHeight: 42
                    radius: 21
                    color: ThemeSystem.Theme.colorPrimary

                    Text {
                        anchors.centerIn: parent
                        text: root.userName.length > 0 ? root.userName[0].toUpperCase() : "U"
                        color: ThemeSystem.Theme.textOnAccent
                        font.pixelSize: 16
                        font.bold: true
                        font.family: ThemeSystem.Theme.fontFamily
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 0

                    Text {
                        text: root.userName.length > 0 ? root.userName : "\u7528\u6237"
                        color: ThemeSystem.Theme.textPrimary
                        font.pixelSize: 14
                        font.bold: true
                        font.family: ThemeSystem.Theme.fontFamily
                    }

                    Text {
                        text: dashboardViewModel.userRole.length > 0 ? dashboardViewModel.userRole : "\u7cfb\u7edf\u6210\u5458"
                        color: ThemeSystem.Theme.textSecondary
                        font.pixelSize: 12
                        font.family: ThemeSystem.Theme.fontFamily
                    }
                }

                Item {
                    Layout.preferredWidth: 14
                    Layout.preferredHeight: 14

                    Rectangle {
                        width: 8
                        height: 2
                        radius: 1
                        rotation: 45
                        color: ThemeSystem.Theme.textTertiary
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: -2
                    }

                    Rectangle {
                        width: 8
                        height: 2
                        radius: 1
                        rotation: -45
                        color: ThemeSystem.Theme.textTertiary
                        anchors.centerIn: parent
                        anchors.horizontalCenterOffset: 2
                    }
                }
            }

            onClicked: {
                if (accountMenu.opened) {
                    accountMenu.close()
                } else {
                    accountMenu.open()
                }
            }
        }
    }

    Popup {
        id: accountMenu

        parent: root
        x: root.width - width - 24
        y: profileButton.y + profileButton.height + 10
        width: 196
        modal: false
        focus: true
        padding: 8
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutsideParent

        background: Rectangle {
            radius: ThemeSystem.Theme.radiusLarge
            color: ThemeSystem.Theme.acrylicFill
            border.width: 1
            border.color: ThemeSystem.Theme.cardBorder
        }

        contentItem: ColumnLayout {
            spacing: 4

            Button {
                id: logoutButton

                Layout.fillWidth: true
                implicitHeight: 42
                hoverEnabled: true

                background: Rectangle {
                    radius: 12
                    color: logoutButton.hovered ? ThemeSystem.Theme.sidebarHoverFill : "transparent"

                    Behavior on color {
                        ColorAnimation { duration: ThemeSystem.Theme.fastDuration }
                    }
                }

                contentItem: RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    spacing: 10

                    FluentNavIcon {
                        Layout.preferredWidth: 18
                        Layout.preferredHeight: 18
                        iconName: "logout"
                        iconColor: ThemeSystem.Theme.textPrimary
                        iconSize: 18
                    }

                    Text {
                        text: "\u9000\u51fa\u767b\u5f55"
                        color: ThemeSystem.Theme.textPrimary
                        font.pixelSize: 14
                        font.family: ThemeSystem.Theme.fontFamily
                        Layout.fillWidth: true
                        verticalAlignment: Text.AlignVCenter
                    }
                }

                onClicked: {
                    accountMenu.close()
                    root.logoutRequested()
                }
            }
        }
    }
}
