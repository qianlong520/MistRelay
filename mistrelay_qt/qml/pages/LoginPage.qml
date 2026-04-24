import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme" as ThemeSystem
import "../components"

Item {
    id: root

    anchors.fill: parent

    readonly property var loginVm: loginViewModel || ({
        serverBaseUrl: "",
        username: "",
        password: "",
        errorMessage: "",
        infoMessage: "",
        busy: false,
        setServerBaseUrl: function() {},
        setUsername: function() {},
        setPassword: function() {},
        submitLogin: function() {}
    })
    readonly property real pagePadding: Math.max(24, Math.min(56, width * 0.05))
    readonly property real cardWidth: Math.max(340, Math.min(460, width - pagePadding * 2))
    readonly property bool hasErrorState: root.loginVm.errorMessage.length > 0
    readonly property bool hasBusyState: root.loginVm.busy
    readonly property bool hasInfoState: !root.hasErrorState && !root.hasBusyState && root.loginVm.infoMessage.length > 0
    readonly property bool showStatus: root.hasErrorState || root.hasBusyState || root.hasInfoState
    readonly property string statusMessage: root.hasErrorState
                                            ? root.loginVm.errorMessage
                                            : (root.hasBusyState
                                               ? "正在验证账号并建立连接。"
                                               : root.loginVm.infoMessage)
    readonly property color statusBackgroundColor: root.hasErrorState
                                                   ? ThemeSystem.Theme.dangerSoft
                                                   : (root.hasBusyState ? "#f0fdf4" : ThemeSystem.Theme.infoSoft)
    readonly property color statusBorderColor: root.hasErrorState
                                               ? "#fca5a5"
                                               : (root.hasBusyState ? "#86efac" : "#93c5fd")
    readonly property color statusAccentColor: root.hasErrorState
                                               ? ThemeSystem.Theme.colorDanger
                                               : (root.hasBusyState ? ThemeSystem.Theme.colorSuccess : ThemeSystem.Theme.colorInfo)

    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: ThemeSystem.Theme.micaTintStrong }
            GradientStop { position: 0.52; color: ThemeSystem.Theme.micaBase }
            GradientStop { position: 1.0; color: ThemeSystem.Theme.surfaceAlt }
        }
    }

    Rectangle {
        x: -120
        y: -140
        width: 520
        height: 520
        radius: width / 2
        color: "#9fcfff"
        opacity: 0.14
        antialiasing: true
    }

    Rectangle {
        x: width * 0.68
        y: height * 0.58
        width: 320
        height: 320
        radius: width / 2
        color: "#d6e8f7"
        opacity: 0.2
        antialiasing: true
    }

    Item {
        anchors.fill: parent
        anchors.margins: root.pagePadding

        Flickable {
            id: viewport

            anchors.fill: parent
            contentWidth: width
            contentHeight: Math.max(height, cardShell.implicitHeight + root.pagePadding * 2)
            clip: true
            boundsBehavior: Flickable.StopAtBounds

            Item {
                width: viewport.width
                height: viewport.contentHeight

                Item {
                    id: cardShell

                    width: root.cardWidth
                    implicitHeight: formCard.implicitHeight
                    anchors.horizontalCenter: parent.horizontalCenter
                    y: Math.max(0, (parent.height - implicitHeight) / 2)

                    GlassCard {
                        id: formCard

                        width: parent.width
                        implicitHeight: formContent.implicitHeight + padding * 2
                        padding: 28
                        backgroundColor: ThemeSystem.Theme.cardBackground
                        borderColor: ThemeSystem.Theme.cardBorderStrong
                        shadowOpacity: 0.14
                        shadowOffsetY: 20
                        shadowSpread: 28

                        ColumnLayout {
                            id: formContent

                            anchors.fill: parent
                            spacing: 16

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Text {
                                    text: "MistRelay"
                                    color: ThemeSystem.Theme.textSecondary
                                    font.pixelSize: 13
                                    font.bold: true
                                    font.family: ThemeSystem.Theme.fontFamily
                                }

                                Text {
                                    text: "登录"
                                    color: ThemeSystem.Theme.textPrimary
                                    font.pixelSize: 28
                                    font.bold: true
                                    font.family: ThemeSystem.Theme.fontFamily
                                }

                                Text {
                                    text: "连接到你的服务端。"
                                    color: ThemeSystem.Theme.textSecondary
                                    font.pixelSize: 13
                                    font.family: ThemeSystem.Theme.fontFamily
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: "服务端地址"
                                    color: ThemeSystem.Theme.textPrimary
                                    font.pixelSize: 13
                                    font.bold: true
                                    font.family: ThemeSystem.Theme.fontFamily
                                }

                                AppTextField {
                                    id: serverField
                                    Layout.fillWidth: true
                                    text: root.loginVm.serverBaseUrl
                                    placeholderText: "https://relay.example.com"
                                    onTextEdited: root.loginVm.setServerBaseUrl(text)
                                    onAccepted: usernameField.forceActiveFocus()
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: "用户名"
                                    color: ThemeSystem.Theme.textPrimary
                                    font.pixelSize: 13
                                    font.bold: true
                                    font.family: ThemeSystem.Theme.fontFamily
                                }

                                AppTextField {
                                    id: usernameField
                                    Layout.fillWidth: true
                                    text: root.loginVm.username
                                    placeholderText: "请输入账号"
                                    onTextEdited: root.loginVm.setUsername(text)
                                    onAccepted: passwordField.forceActiveFocus()
                                }
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Text {
                                    text: "密码"
                                    color: ThemeSystem.Theme.textPrimary
                                    font.pixelSize: 13
                                    font.bold: true
                                    font.family: ThemeSystem.Theme.fontFamily
                                }

                                AppTextField {
                                    id: passwordField
                                    Layout.fillWidth: true
                                    text: root.loginVm.password
                                    echoMode: TextInput.Password
                                    placeholderText: "请输入密码"
                                    inputMethodHints: Qt.ImhSensitiveData | Qt.ImhNoPredictiveText
                                    onTextEdited: root.loginVm.setPassword(text)
                                    onAccepted: root.loginVm.submitLogin()
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                visible: root.showStatus
                                radius: ThemeSystem.Theme.radiusMedium
                                color: root.statusBackgroundColor
                                border.width: 1
                                border.color: root.statusBorderColor
                                implicitHeight: statusRow.implicitHeight + 18

                                RowLayout {
                                    id: statusRow

                                    anchors.fill: parent
                                    anchors.margins: 12
                                    spacing: 10

                                    Item {
                                        Layout.preferredWidth: root.hasBusyState ? 22 : 18
                                        Layout.preferredHeight: root.hasBusyState ? 22 : 18
                                        Layout.alignment: Qt.AlignVCenter

                                        BusyIndicator {
                                            anchors.centerIn: parent
                                            running: root.hasBusyState
                                            visible: root.hasBusyState
                                            implicitWidth: 20
                                            implicitHeight: 20
                                        }

                                        Rectangle {
                                            anchors.centerIn: parent
                                            visible: !root.hasBusyState
                                            width: 18
                                            height: 18
                                            radius: 9
                                            color: root.statusAccentColor
                                            opacity: 0.12
                                        }

                                        Text {
                                            anchors.centerIn: parent
                                            visible: !root.hasBusyState
                                            text: root.hasErrorState ? "!" : "i"
                                            color: root.statusAccentColor
                                            font.pixelSize: 11
                                            font.bold: true
                                            font.family: ThemeSystem.Theme.fontFamily
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: root.statusMessage
                                        color: ThemeSystem.Theme.textPrimary
                                        font.pixelSize: 12
                                        wrapMode: Text.WordWrap
                                        maximumLineCount: 3
                                        elide: Text.ElideRight
                                        font.family: ThemeSystem.Theme.fontFamily
                                    }
                                }
                            }

                            PrimaryButton {
                                Layout.fillWidth: true
                                Layout.topMargin: 4
                                text: root.loginVm.busy ? "正在登录..." : "登录"
                                enabled: !root.loginVm.busy
                                onClicked: root.loginVm.submitLogin()
                            }
                        }
                    }
                }
            }
        }
    }
}
