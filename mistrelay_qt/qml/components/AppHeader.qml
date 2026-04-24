import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme" as ThemeSystem

Rectangle {
    id: root

    readonly property var dashboardVm: dashboardViewModel || ({
        serverBaseUrl: "",
        userRole: ""
    })

    signal logoutRequested()
    signal homeRequested()

    property string title: ""
    property string subtitle: ""
    property string currentPageText: ""
    property string userName: ""
    property string connectionState: "disconnected"
    property real revealProgress: 1.0
    readonly property bool showCurrentPage: root.currentPageText.length > 0
    readonly property bool canNavigateHome: root.showCurrentPage
    readonly property string serverLabel: root.dashboardVm.serverBaseUrl.length > 0
                                          ? root.dashboardVm.serverBaseUrl.replace("http://", "").replace("https://", "")
                                          : "\u672a\u914d\u7f6e\u670d\u52a1\u5668"
    readonly property real clampedRevealProgress: Math.max(0.0, Math.min(1.0, revealProgress))

    color: "#87CEFA"
    border.width: 0
    radius: 0
    clip: true
    implicitHeight: 52 * clampedRevealProgress
    opacity: clampedRevealProgress

    Behavior on implicitHeight {
        NumberAnimation { duration: ThemeSystem.Theme.mediumDuration }
    }

    Behavior on opacity {
        NumberAnimation { duration: ThemeSystem.Theme.mediumDuration }
    }

    Rectangle {
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.bottom: parent.bottom
        height: 1
        color: ThemeSystem.Theme.lineColor
        opacity: 0.55 * root.clampedRevealProgress
    }

    RowLayout {
        anchors.fill: parent
        anchors.leftMargin: 20
        anchors.rightMargin: 22
        spacing: 18

        RowLayout {
            Layout.alignment: Qt.AlignVCenter
            spacing: 8

            Item {
                Layout.alignment: Qt.AlignVCenter
                implicitWidth: homeContent.implicitWidth + 12
                implicitHeight: 28

                Rectangle {
                    anchors.fill: parent
                    radius: 8
                    color: homeArea.pressed
                           ? "#d8eaf8"
                           : (homeArea.containsMouse && root.canNavigateHome ? "#eaf4fb" : "transparent")

                    Behavior on color {
                        ColorAnimation { duration: ThemeSystem.Theme.fastDuration }
                    }
                }

                RowLayout {
                    id: homeContent

                    anchors.centerIn: parent
                    spacing: 8

                    FluentNavIcon {
                        Layout.preferredWidth: 14
                        Layout.preferredHeight: 14
                        iconName: "home"
                        iconColor: homeArea.containsMouse && root.canNavigateHome
                                   ? ThemeSystem.Theme.colorPrimary
                                   : ThemeSystem.Theme.textTertiary
                        iconSize: 14
                    }

                    Text {
                        text: "\u9996\u9875"
                        color: homeArea.containsMouse && root.canNavigateHome
                               ? ThemeSystem.Theme.colorPrimary
                               : ThemeSystem.Theme.textPrimary
                        font.pixelSize: 14
                        font.bold: true
                        font.family: ThemeSystem.Theme.fontFamily
                    }
                }

                MouseArea {
                    id: homeArea

                    anchors.fill: parent
                    enabled: root.canNavigateHome
                    hoverEnabled: true
                    cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor

                    onClicked: root.homeRequested()
                }
            }

            Text {
                visible: root.showCurrentPage
                text: "/"
                color: ThemeSystem.Theme.textTertiary
                font.pixelSize: 14
                font.bold: true
                font.family: ThemeSystem.Theme.fontFamily
            }

            Text {
                visible: root.showCurrentPage
                text: root.currentPageText
                color: ThemeSystem.Theme.textSecondary
                font.pixelSize: 14
                font.bold: true
                font.family: ThemeSystem.Theme.fontFamily
            }
        }

        Item {
            Layout.fillWidth: true
        }

        Rectangle {
            Layout.preferredHeight: 40
            Layout.preferredWidth: 176
            radius: 9
            color: "#f6fbff"
            border.width: 1
            border.color: "#d5e7f5"

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 12
                anchors.rightMargin: 12
                spacing: 9

                Rectangle {
                    Layout.preferredWidth: 9
                    Layout.preferredHeight: 9
                    radius: 5
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
                        text: "\u540c\u6b65\u670d\u52a1"
                        color: ThemeSystem.Theme.textPrimary
                        font.pixelSize: 12
                        font.bold: true
                        elide: Text.ElideRight
                        font.family: ThemeSystem.Theme.fontFamily
                    }

                    Text {
                        text: root.connectionState === "connected"
                              ? "\u670d\u52a1\u5728\u7ebf"
                              : root.connectionState === "connecting"
                                ? "\u8fde\u63a5\u4e2d"
                                : "\u670d\u52a1\u79bb\u7ebf"
                        color: ThemeSystem.Theme.textSecondary
                        font.pixelSize: 10
                        font.family: ThemeSystem.Theme.fontFamily
                    }
                }
            }
        }

        Button {
            id: profileButton

            implicitHeight: 40
            implicitWidth: 150
            hoverEnabled: true

            background: Rectangle {
                radius: 10
                color: profileButton.down
                       ? ThemeSystem.Theme.sidebarHoverFill
                       : (profileButton.hovered ? "#f3f7fc" : "transparent")
                border.width: 0

                Behavior on color {
                    ColorAnimation { duration: ThemeSystem.Theme.fastDuration }
                }
            }

            contentItem: RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                spacing: 9

                Rectangle {
                    Layout.preferredWidth: 32
                    Layout.preferredHeight: 32
                    radius: 16
                    color: ThemeSystem.Theme.colorPrimary

                    Text {
                        anchors.centerIn: parent
                        text: root.userName.length > 0 ? root.userName[0].toUpperCase() : "U"
                        color: ThemeSystem.Theme.textOnAccent
                        font.pixelSize: 13
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
                        font.pixelSize: 12
                        font.bold: true
                        font.family: ThemeSystem.Theme.fontFamily
                    }

                    Text {
                        text: root.dashboardVm.userRole.length > 0 ? root.dashboardVm.userRole : "\u7cfb\u7edf\u6210\u5458"
                        color: ThemeSystem.Theme.textSecondary
                        font.pixelSize: 10
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
