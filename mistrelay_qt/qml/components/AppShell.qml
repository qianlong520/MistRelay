import QtQuick
import QtQuick.Layouts
import "../theme" as ThemeSystem
import "../pages"

Item {
    anchors.fill: parent

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: ThemeSystem.Theme.micaTintStrong }
            GradientStop { position: 0.48; color: ThemeSystem.Theme.micaBase }
            GradientStop { position: 1.0; color: ThemeSystem.Theme.surfaceAlt }
        }
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"

        Rectangle {
            x: width * 0.18
            y: height * 0.18
            width: 320
            height: 320
            radius: 160
            color: "#b8d9f5"
            opacity: 0.2
        }

        Rectangle {
            x: width * 0.78
            y: height * 0.76
            width: 260
            height: 260
            radius: 130
            color: "#dce9f8"
            opacity: 0.28
        }
    }

    RowLayout {
        anchors.fill: parent
        spacing: 0

            AppSidebar {
                Layout.preferredWidth: 252
                Layout.fillHeight: true
                currentRoute: appViewModel.currentRoute
                onRouteSelected: (route) => appViewModel.navigate(route)
            }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            AppHeader {
                Layout.fillWidth: true
                title: appViewModel.currentRoute === "dashboard"
                       ? "\u4eea\u8868\u677f"
                       : appViewModel.currentRoute === "downloads"
                         ? "\u4efb\u52a1\u4e2d\u5fc3"
                         : appViewModel.currentRoute === "drive"
                           ? "\u6211\u7684\u7f51\u76d8"
                           : "\u7cfb\u7edf\u8bbe\u7f6e"
                subtitle: ""
                userName: appViewModel.userDisplayName
                connectionState: appViewModel.connectionState
                onLogoutRequested: appViewModel.logout()
            }

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: appViewModel.currentRouteIndex
                opacity: 1

                Behavior on opacity {
                    NumberAnimation { duration: ThemeSystem.Theme.mediumDuration }
                }

                DashboardPage {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
                DownloadsPage {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
                DrivePage {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
                SettingsPage {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }
    }
}
