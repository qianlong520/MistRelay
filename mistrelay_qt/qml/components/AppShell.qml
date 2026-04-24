import QtQuick
import QtQuick.Layouts
import "../theme" as ThemeSystem
import "../pages"

Item {
    id: root

    readonly property var appVm: appViewModel || ({
        currentRoute: "dashboard",
        currentRouteIndex: 0,
        userDisplayName: "",
        connectionState: "disconnected",
        navigate: function() {},
        logout: function() {}
    })

    readonly property real currentHeaderRevealProgress: {
        switch (root.appVm.currentRoute) {
        case "dashboard":
            return dashboardPage.headerRevealProgress
        case "downloads":
            return downloadsPage.headerRevealProgress
        case "drive":
            return drivePage.headerRevealProgress
        case "settings":
            return settingsPage.headerRevealProgress
        default:
            return 1.0
        }
    }

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
                currentRoute: root.appVm.currentRoute
                onRouteSelected: (route) => root.appVm.navigate(route)
            }

        ColumnLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            AppHeader {
                id: appHeader
                Layout.fillWidth: true
                revealProgress: root.currentHeaderRevealProgress
                currentPageText: root.appVm.currentRoute === "dashboard"
                                 ? ""
                                 : root.appVm.currentRoute === "downloads"
                                   ? "\u4efb\u52a1\u4e2d\u5fc3"
                                   : root.appVm.currentRoute === "drive"
                                     ? "\u7f51\u76d8\u7ba1\u7406"
                                     : "\u7cfb\u7edf\u8bbe\u7f6e"
                title: root.appVm.currentRoute === "dashboard"
                       ? "\u4eea\u8868\u677f"
                       : root.appVm.currentRoute === "downloads"
                         ? "\u4efb\u52a1\u4e2d\u5fc3"
                         : root.appVm.currentRoute === "drive"
                           ? "\u6211\u7684\u7f51\u76d8"
                           : "\u7cfb\u7edf\u8bbe\u7f6e"
                subtitle: root.appVm.currentRoute === "dashboard"
                          ? "\u8fd0\u884c\u6982\u89c8"
                          : root.appVm.currentRoute === "downloads"
                            ? "\u4efb\u52a1\u4e0e\u8fdb\u5ea6"
                            : root.appVm.currentRoute === "drive"
                              ? "\u6587\u4ef6\u4e0e\u5b58\u50a8"
                              : "\u504f\u597d\u4e0e\u8fde\u63a5"
                userName: root.appVm.userDisplayName
                connectionState: root.appVm.connectionState
                onHomeRequested: root.appVm.navigate("dashboard")
                onLogoutRequested: root.appVm.logout()
            }

            StackLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                currentIndex: root.appVm.currentRouteIndex
                opacity: 1

                Behavior on opacity {
                    NumberAnimation { duration: ThemeSystem.Theme.mediumDuration }
                }

                DashboardPage {
                    id: dashboardPage
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
                DownloadsPage {
                    id: downloadsPage
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
                DrivePage {
                    id: drivePage
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
                SettingsPage {
                    id: settingsPage
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                }
            }
        }
    }
}
