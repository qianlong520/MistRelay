import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtQuick.Controls.Universal
import "theme" as ThemeSystem
import "components"
import "pages"

ApplicationWindow {
    id: window

    visible: true
    title: appViewModel.windowTitle
    color: ThemeSystem.Theme.surface
    readonly property bool promptCompact: width < 760
    Universal.theme: Universal.Light
    Universal.accent: ThemeSystem.Theme.colorPrimary
    Universal.foreground: ThemeSystem.Theme.textPrimary
    font.family: ThemeSystem.Theme.fontFamily

    Component.onCompleted: Qt.callLater(function() {
        updateViewModel.startupCheck()
    })

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: ThemeSystem.Theme.micaTintStrong }
            GradientStop { position: 0.45; color: ThemeSystem.Theme.micaBase }
            GradientStop { position: 1.0; color: ThemeSystem.Theme.surfaceAlt }
        }
    }

    Rectangle {
        x: width * 0.7
        y: -40
        width: 320
        height: 140
        radius: 42
        rotation: -14
        color: "#ffffff"
        opacity: 0.42
    }

    Loader {
        anchors.fill: parent
        sourceComponent: appViewModel.loggedIn ? shellComponent : loginComponent
        opacity: status === Loader.Ready ? 1 : 0

        Behavior on opacity {
            NumberAnimation { duration: ThemeSystem.Theme.mediumDuration }
        }
    }

    Item {
        anchors.fill: parent
        visible: updateViewModel.promptVisible
        z: 20

        Rectangle {
            anchors.fill: parent
            color: ThemeSystem.Theme.overlayScrim
        }

        MouseArea {
            anchors.fill: parent
        }

        GlassCard {
            anchors.centerIn: parent
            width: Math.min(window.width - 64, 620)
            implicitHeight: contentLayout.implicitHeight + padding * 2
            backgroundColor: ThemeSystem.Theme.cardBackground
            borderColor: ThemeSystem.Theme.cardBorderStrong
            shadowOpacity: 0.18
            shadowOffsetY: 18
            shadowSpread: 28

            ColumnLayout {
                id: contentLayout
                anchors.fill: parent
                spacing: 16

                Rectangle {
                    Layout.preferredWidth: 140
                    Layout.preferredHeight: 34
                    radius: 999
                    color: ThemeSystem.Theme.sidebarActiveFill

                    Text {
                        anchors.centerIn: parent
                        text: "发现新版本"
                        color: ThemeSystem.Theme.colorPrimary
                        font.pixelSize: 13
                        font.bold: true
                        font.family: ThemeSystem.Theme.fontFamily
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "MistRelay Desktop Qt v" + updateViewModel.updateVersion + " 已可用"
                    color: ThemeSystem.Theme.textPrimary
                    font.pixelSize: 28
                    font.bold: true
                    wrapMode: Text.WordWrap
                    font.family: ThemeSystem.Theme.fontFamily
                }

                Text {
                    Layout.fillWidth: true
                    text: updateViewModel.updateState
                    color: ThemeSystem.Theme.textSecondary
                    font.pixelSize: 14
                    wrapMode: Text.WordWrap
                    font.family: ThemeSystem.Theme.fontFamily
                }

                ProgressBar {
                    visible: updateViewModel.updateProgressPercent >= 0
                    Layout.fillWidth: true
                    from: 0
                    to: 100
                    value: updateViewModel.updateProgressPercent
                }

                Rectangle {
                    visible: updateViewModel.updateNotes.length > 0
                    Layout.fillWidth: true
                    radius: ThemeSystem.Theme.radiusMedium
                    color: ThemeSystem.Theme.panelSurfaceSecondary
                    border.width: 1
                    border.color: ThemeSystem.Theme.lineColor
                    implicitHeight: notesText.implicitHeight + 24

                    Text {
                        id: notesText
                        anchors.fill: parent
                        anchors.margins: 12
                        text: updateViewModel.updateNotes
                        wrapMode: Text.WordWrap
                        color: ThemeSystem.Theme.textPrimary
                        font.pixelSize: 13
                        font.family: ThemeSystem.Theme.fontFamily
                    }
                }

                GridLayout {
                    Layout.fillWidth: true
                    columns: window.promptCompact ? 1 : 3
                    columnSpacing: 12
                    rowSpacing: 12

                    Button {
                        text: "稍后再说"
                        enabled: !updateViewModel.busy
                        Layout.fillWidth: window.promptCompact
                        onClicked: updateViewModel.dismissPrompt()
                    }

                    Item {
                        visible: !window.promptCompact
                        Layout.fillWidth: true
                    }

                    PrimaryButton {
                        Layout.fillWidth: true
                        Layout.preferredWidth: 220
                        text: updateViewModel.busy
                              ? (updateViewModel.updateProgressPercent >= 0 ? "正在更新..." : "正在检查...")
                              : "立即更新到 v" + updateViewModel.updateVersion
                        enabled: !updateViewModel.busy
                        onClicked: updateViewModel.installUpdate()
                    }
                }
            }
        }
    }

    Component {
        id: loginComponent

        LoginPage { }
    }

    Component {
        id: shellComponent

        AppShell { }
    }

    FloatingToast {
        id: toast
        z: 10
    }

    Connections {
        target: appViewModel

        function onToastRequested(level, message) {
            toast.showMessage(level, message)
        }
    }
}
