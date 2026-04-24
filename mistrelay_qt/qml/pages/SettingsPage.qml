pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme" as ThemeSystem
import "../components"

ResponsivePage {
    id: root

    readonly property var settingsVm: settingsViewModel || ({
        serverBaseUrl: "",
        proxyEnabled: false,
        proxyUrl: "",
        downloadDir: "",
        maxConcurrentDownloads: 1,
        threadsPerDownload: 1,
        errorMessage: "",
        bootstrap: function() {},
        setServerBaseUrl: function() {},
        setProxyEnabled: function() {},
        setProxyUrl: function() {},
        setDownloadDir: function() {},
        pickDownloadDir: function() {},
        setMaxConcurrentDownloads: function() {},
        setThreadsPerDownload: function() {},
        save: function() {},
    })
    readonly property var updateVm: updateViewModel || ({
        updateState: "",
        updateProgressPercent: -1,
        updateNotes: "",
        busy: false,
        canInstallUpdate: false,
        updateVersion: "",
        manualUrl: "",
        checkForUpdates: function() {},
        installUpdate: function() {},
        openManualUpdateUrl: function() {}
    })

    horizontalPadding: 26
    verticalPadding: 24
    sectionSpacing: 24

    property string clientTab: "connection"
    readonly property int formColumns: compact ? 1 : 2
    readonly property int filterButtonMinWidth: compact ? 0 : 116

    function toneColor(tone) {
        switch (tone) {
        case "success":
            return ThemeSystem.Theme.colorSuccess
        case "warning":
            return ThemeSystem.Theme.colorWarning
        case "danger":
            return ThemeSystem.Theme.colorDanger
        case "primary":
            return ThemeSystem.Theme.colorPrimary
        default:
            return ThemeSystem.Theme.colorInfo
        }
    }

    function toneSoftColor(tone) {
        switch (tone) {
        case "success":
            return ThemeSystem.Theme.successSoft
        case "warning":
            return ThemeSystem.Theme.warningSoft
        case "danger":
            return ThemeSystem.Theme.dangerSoft
        case "primary":
            return "#e9f2ff"
        default:
            return ThemeSystem.Theme.infoSoft
        }
    }

    function displayText(value, fallback) {
        if (value === undefined || value === null || value === "") {
            return fallback || "-"
        }
        return String(value)
    }

    function clampedRatio(percent) {
        return Math.max(0, Math.min(1, Number(percent || 0) / 100))
    }

    Component.onCompleted: root.settingsVm.bootstrap()
    component FilterButton: Button {
        id: filterButton
        required property bool activeState

        checkable: true
        checked: activeState
        hoverEnabled: true
        implicitHeight: 40
        implicitWidth: Math.max(root.filterButtonMinWidth, 112)
        horizontalPadding: 16

        background: Rectangle {
            radius: ThemeSystem.Theme.radiusMedium
            color: filterButton.checked
                   ? ThemeSystem.Theme.sidebarActiveFill
                   : (filterButton.hovered ? ThemeSystem.Theme.sidebarHoverFill : "#ffffff")
            border.width: 1
            border.color: filterButton.checked
                          ? "#9dc7f0"
                          : (filterButton.hovered ? ThemeSystem.Theme.lineColorStrong : ThemeSystem.Theme.cardBorder)

            Behavior on color {
                ColorAnimation { duration: ThemeSystem.Theme.fastDuration }
            }

        }

        contentItem: Text {
            text: filterButton.text
            color: filterButton.checked ? ThemeSystem.Theme.colorPrimary : ThemeSystem.Theme.textPrimary
            font.bold: filterButton.checked
            font.family: ThemeSystem.Theme.fontFamily
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }

    component SectionIntro: ColumnLayout {
        id: intro
        required property string eyebrow
        required property string title
        property string description: ""

        Layout.fillWidth: true
        spacing: 6

        Text {
            visible: intro.eyebrow.length > 0
            text: intro.eyebrow
            color: ThemeSystem.Theme.colorPrimary
            font.pixelSize: 12
            font.bold: true
            font.family: ThemeSystem.Theme.fontFamily
        }

        Text {
            Layout.fillWidth: true
            text: intro.title
            color: ThemeSystem.Theme.textPrimary
            font.pixelSize: 22
            font.bold: true
            wrapMode: Text.WordWrap
            font.family: ThemeSystem.Theme.fontFamily
        }

        Text {
            visible: intro.description.length > 0
            Layout.fillWidth: true
            text: intro.description
            color: ThemeSystem.Theme.textSecondary
            font.pixelSize: 14
            wrapMode: Text.WordWrap
            lineHeight: 1.25
            font.family: ThemeSystem.Theme.fontFamily
        }
    }

    component LabeledControl: ColumnLayout {
        id: labeledControl
        required property string label
        property string hint: ""
        default property alias contentData: fieldContent.data

        Layout.fillWidth: true
        spacing: 8

        Text {
            Layout.fillWidth: true
            text: labeledControl.label
            color: ThemeSystem.Theme.textPrimary
            font.pixelSize: 13
            font.bold: true
            wrapMode: Text.WordWrap
            font.family: ThemeSystem.Theme.fontFamily
        }

        ColumnLayout {
            id: fieldContent
            Layout.fillWidth: true
            spacing: 0
        }

        Text {
            visible: labeledControl.hint.length > 0
            Layout.fillWidth: true
            text: labeledControl.hint
            color: ThemeSystem.Theme.textTertiary
            font.pixelSize: 12
            wrapMode: Text.WordWrap
            font.family: ThemeSystem.Theme.fontFamily
        }
    }

    component ManagementMetricCard: GlassCard {
        id: metricCard
        required property string title
        required property string value
        required property string caption
        required property string tone
        required property real percent

        Layout.fillWidth: true
        backgroundColor: "#ffffff"
        borderColor: Qt.rgba(root.toneColor(metricCard.tone).r,
                             root.toneColor(metricCard.tone).g,
                             root.toneColor(metricCard.tone).b, 0.18)
        shadowOpacity: 0.08
        shadowOffsetY: 10
        shadowSpread: 20
        implicitHeight: metricContent.implicitHeight + padding * 2

        ColumnLayout {
            id: metricContent
            anchors.fill: parent
            spacing: 14

            RowLayout {
                Layout.fillWidth: true
                spacing: 10

                Rectangle {
                    Layout.preferredWidth: 38
                    Layout.preferredHeight: 38
                    radius: 12
                    color: root.toneSoftColor(metricCard.tone)

                    Rectangle {
                        anchors.centerIn: parent
                        width: 14
                        height: 14
                        radius: 7
                        color: root.toneColor(metricCard.tone)
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: metricCard.title
                    color: ThemeSystem.Theme.textSecondary
                    font.pixelSize: 14
                    wrapMode: Text.WordWrap
                    font.family: ThemeSystem.Theme.fontFamily
                }

                Text {
                    text: metricCard.value
                    color: root.toneColor(metricCard.tone)
                    font.pixelSize: 22
                    font.bold: true
                    font.family: ThemeSystem.Theme.fontFamily
                }
            }

            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 10
                radius: 5
                color: "#edf3fa"

                Rectangle {
                    width: parent.width * root.clampedRatio(metricCard.percent)
                    height: parent.height
                    radius: parent.radius
                    color: root.toneColor(metricCard.tone)
                }
            }

            Text {
                Layout.fillWidth: true
                text: metricCard.caption
                color: ThemeSystem.Theme.textSecondary
                font.pixelSize: 13
                wrapMode: Text.WordWrap
                font.family: ThemeSystem.Theme.fontFamily
            }
        }
    }

    component KeyValueRow: Rectangle {
        id: kvRow
        required property string label
        required property string value

        Layout.fillWidth: true
        radius: ThemeSystem.Theme.radiusMedium
        color: ThemeSystem.Theme.panelSurfaceSecondary
        border.width: 1
        border.color: ThemeSystem.Theme.cardBorder
        implicitHeight: kvContent.implicitHeight + 20

        ColumnLayout {
            id: kvContent
            anchors.fill: parent
            anchors.margins: 12
            spacing: 4

            Text {
                Layout.fillWidth: true
                text: kvRow.label
                color: ThemeSystem.Theme.textTertiary
                font.pixelSize: 12
                font.bold: true
                wrapMode: Text.WordWrap
                font.family: ThemeSystem.Theme.fontFamily
            }

            Text {
                Layout.fillWidth: true
                text: kvRow.value
                color: ThemeSystem.Theme.textPrimary
                font.pixelSize: 14
                font.bold: true
                wrapMode: Text.WordWrap
                font.family: ThemeSystem.Theme.fontFamily
            }
        }
    }

    component ConsoleArea: TextArea {
        readOnly: true
        wrapMode: TextArea.NoWrap
        font.family: "Consolas"
        color: "#e2e8f0"
        selectionColor: ThemeSystem.Theme.colorPrimary

        background: Rectangle {
            radius: ThemeSystem.Theme.radiusMedium
            color: "#0f172a"
            border.width: 1
            border.color: "#1e293b"
        }
    }

    FluentBanner {
        Layout.fillWidth: true
        visible: root.settingsVm.errorMessage.length > 0
        tone: "danger"
        title: "发生错误"
        description: root.settingsVm.errorMessage
    }

    Item {
        Layout.fillWidth: true
        implicitHeight: scopeLoader.implicitHeight

        Loader {
            id: scopeLoader
            width: parent.width
            sourceComponent: clientScope
        }
    }

    Component {
        id: clientScope

        ColumnLayout {
            width: root.contentFrameWidth
            spacing: root.sectionSpacing

            GlassCard {
                Layout.fillWidth: true
                backgroundColor: "#ffffff"
                implicitHeight: clientScopeContent.implicitHeight + padding * 2

                ColumnLayout {
                    id: clientScopeContent
                    anchors.fill: parent
                    spacing: 18

                    SectionIntro {
                        eyebrow: "CLIENT"
                        title: "客户端设置"
                        description: "连接地址、更新、代理与下载行为都在这里维护，页面结构已按常用操作重新分组。"
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: 10

                        FilterButton {
                            text: "连接"
                            activeState: root.clientTab === "connection"
                            onClicked: root.clientTab = "connection"
                        }

                        FilterButton {
                            text: "更新"
                            activeState: root.clientTab === "update"
                            onClicked: root.clientTab = "update"
                        }

                        FilterButton {
                            text: "代理"
                            activeState: root.clientTab === "proxy"
                            onClicked: root.clientTab = "proxy"
                        }

                        FilterButton {
                            text: "下载"
                            activeState: root.clientTab === "download"
                            onClicked: root.clientTab = "download"
                        }

                        FilterButton {
                            text: "\u7f13\u5b58"
                            activeState: root.clientTab === "cache"
                            onClicked: {
                                root.clientTab = "cache"
                                root.settingsVm.refreshCacheStats()
                            }
                        }
                    }

                    Loader {
                        Layout.fillWidth: true
                        sourceComponent: root.clientTab === "connection"
                                         ? clientConnectionTab
                                         : root.clientTab === "update"
                                           ? clientUpdateTab
                                           : root.clientTab === "proxy"
                                             ? clientProxyTab
                                             : root.clientTab === "download"
                                               ? clientDownloadTab
                                               : clientCacheTab
                    }
                }
            }
        }
    }

    Component {
        id: clientConnectionTab

        ColumnLayout {
            width: root.contentFrameWidth
            spacing: 16

            SectionIntro {
                eyebrow: "CONNECTION"
                title: "连接与地址"
                description: "配置 Qt 客户端要连接的服务端地址，不会修改服务器内部参数。"
            }

            LabeledControl {
                label: "服务端地址"

                AppTextField {
                    Layout.fillWidth: true
                    text: root.settingsVm.serverBaseUrl
                    placeholderText: "https://mistrelay.example.com"
                    onTextEdited: root.settingsVm.setServerBaseUrl(text)
                }
            }

            Rectangle {
                Layout.fillWidth: true
                radius: ThemeSystem.Theme.radiusMedium
                color: ThemeSystem.Theme.panelSurfaceSecondary
                border.width: 1
                border.color: ThemeSystem.Theme.cardBorder
                implicitHeight: currentServerText.implicitHeight + 20

                Text {
                    id: currentServerText
                    anchors.fill: parent
                    anchors.margins: 10
                    text: root.settingsVm.serverBaseUrl.length > 0
                          ? "当前地址：" + root.settingsVm.serverBaseUrl
                          : "尚未配置服务端地址。"
                    wrapMode: Text.WordWrap
                    color: ThemeSystem.Theme.textSecondary
                    font.family: ThemeSystem.Theme.fontFamily
                }
            }

            Flow {
                Layout.fillWidth: true
                spacing: 12

                PrimaryButton {
                    text: "保存连接配置"
                    onClicked: root.settingsVm.save()
                }
            }
        }
    }

    Component {
        id: clientUpdateTab

        ColumnLayout {
            width: root.contentFrameWidth
            spacing: 16

            SectionIntro {
                eyebrow: "UPDATE"
                title: "应用更新"
                description: "检查桌面端新版本、查看更新说明，并在可用时执行安装。"
            }

            Rectangle {
                Layout.fillWidth: true
                radius: ThemeSystem.Theme.radiusMedium
                color: ThemeSystem.Theme.panelSurfaceSecondary
                border.width: 1
                border.color: ThemeSystem.Theme.cardBorder
                implicitHeight: updateSummary.implicitHeight + 22

                ColumnLayout {
                    id: updateSummary
                    anchors.fill: parent
                    anchors.margins: 11
                    spacing: 4

                    Text {
                        text: "当前版本 v" + appVersion
                        color: ThemeSystem.Theme.textSecondary
                        font.pixelSize: 13
                        font.family: ThemeSystem.Theme.fontFamily
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.updateVm.updateState
                        color: ThemeSystem.Theme.textPrimary
                        wrapMode: Text.WordWrap
                        font.family: ThemeSystem.Theme.fontFamily
                    }
                }
            }

            ProgressBar {
                visible: root.updateVm.updateProgressPercent >= 0
                Layout.fillWidth: true
                from: 0
                to: 100
                value: root.updateVm.updateProgressPercent
            }

            Text {
                visible: root.updateVm.updateNotes.length > 0
                Layout.fillWidth: true
                text: root.updateVm.updateNotes
                wrapMode: Text.WordWrap
                color: ThemeSystem.Theme.textSecondary
                font.family: ThemeSystem.Theme.fontFamily
            }

            Flow {
                Layout.fillWidth: true
                spacing: 12

                PrimaryButton {
                    text: root.updateVm.busy ? "检查中..." : "检查更新"
                    enabled: !root.updateVm.busy
                    onClicked: root.updateVm.checkForUpdates()
                }

                PrimaryButton {
                    visible: root.updateVm.canInstallUpdate
                    text: "更新到 v" + root.updateVm.updateVersion
                    enabled: !root.updateVm.busy
                    onClicked: root.updateVm.installUpdate()
                }

                SecondaryButton {
                    visible: root.updateVm.manualUrl.length > 0 && !root.updateVm.canInstallUpdate
                    text: "手动下载安装"
                    tone: "primary"
                    onClicked: root.updateVm.openManualUpdateUrl()
                }
            }
        }
    }

    Component {
        id: clientProxyTab

        ColumnLayout {
            width: root.contentFrameWidth
            spacing: 16

            SectionIntro {
                eyebrow: "PROXY"
                title: "客户端代理"
                description: "为 Qt 客户端配置统一网络代理，支持 HTTP 和 SOCKS5。"
            }

            Rectangle {
                Layout.fillWidth: true
                radius: ThemeSystem.Theme.radiusMedium
                color: ThemeSystem.Theme.panelSurfaceSecondary
                border.width: 1
                border.color: ThemeSystem.Theme.cardBorder
                implicitHeight: proxyToggleLayout.implicitHeight + 20

                RowLayout {
                    id: proxyToggleLayout
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 12

                    Switch {
                        checked: root.settingsVm.proxyEnabled
                        onToggled: root.settingsVm.setProxyEnabled(checked)
                    }

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 2

                        Text {
                            text: "启用全局代理"
                            color: ThemeSystem.Theme.textPrimary
                            font.bold: true
                            font.family: ThemeSystem.Theme.fontFamily
                        }

                        Text {
                            Layout.fillWidth: true
                            text: root.settingsVm.proxyEnabled
                                  ? "代理已启用，下面的地址会用于客户端所有网络请求。"
                                  : "关闭后客户端将直接连接服务端。"
                            color: ThemeSystem.Theme.textSecondary
                            wrapMode: Text.WordWrap
                            font.family: ThemeSystem.Theme.fontFamily
                        }
                    }
                }
            }

            LabeledControl {
                label: "代理地址"
                hint: "支持 http://127.0.0.1:7890 和 socks5://127.0.0.1:1080。"

                AppTextField {
                    Layout.fillWidth: true
                    text: root.settingsVm.proxyUrl
                    enabled: root.settingsVm.proxyEnabled
                    placeholderText: "http://127.0.0.1:7890 或 socks5://127.0.0.1:1080"
                    onTextEdited: root.settingsVm.setProxyUrl(text)
                }
            }

            Flow {
                Layout.fillWidth: true
                spacing: 12

                PrimaryButton {
                    text: "保存代理配置"
                    onClicked: root.settingsVm.save()
                }
            }
        }
    }

    Component {
        id: clientDownloadTab

        ColumnLayout {
            width: root.contentFrameWidth
            spacing: 16

            SectionIntro {
                eyebrow: "DOWNLOAD"
                title: "下载配置"
                description: "设置默认下载目录和并发策略，让桌面端下载体验更稳定。"
            }

            LabeledControl {
                label: "下载目录"
                hint: "留空时会使用系统下载目录下的 MistRelay 文件夹。"

                GridLayout {
                    Layout.fillWidth: true
                    columns: root.compact ? 1 : 2
                    columnSpacing: 12
                    rowSpacing: 12

                    AppTextField {
                        Layout.fillWidth: true
                        text: root.settingsVm.downloadDir
                        placeholderText: "默认下载目录"
                        onTextEdited: root.settingsVm.setDownloadDir(text)
                    }

                    SecondaryButton {
                        text: "选择目录"
                        Layout.fillWidth: root.compact
                        tone: "primary"
                        onClicked: root.settingsVm.pickDownloadDir()
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: root.formColumns
                columnSpacing: 18
                rowSpacing: 18

                LabeledControl {
                    label: "最大并发下载"
                    hint: "同时下载的任务数量。"

                    SpinBox {
                        from: 1
                        to: 16
                        value: root.settingsVm.maxConcurrentDownloads
                        onValueModified: root.settingsVm.setMaxConcurrentDownloads(value)
                    }
                }

                LabeledControl {
                    label: "每任务线程数"
                    hint: "单个下载任务的并行线程数。"

                    SpinBox {
                        from: 1
                        to: 32
                        value: root.settingsVm.threadsPerDownload
                        onValueModified: root.settingsVm.setThreadsPerDownload(value)
                    }
                }
            }

            Flow {
                Layout.fillWidth: true
                spacing: 12

                PrimaryButton {
                    text: "保存下载配置"
                    onClicked: root.settingsVm.save()
                }
            }
        }
    }


    Component {
        id: clientCacheTab

        ColumnLayout {
            width: root.contentFrameWidth
            spacing: 16

            SectionIntro {
                eyebrow: "CACHE"
                title: "\u672c\u5730\u7f13\u5b58\u7ba1\u7406"
                description: "\u8bbe\u7f6e\u9884\u89c8\u7f13\u5b58\u4fdd\u5b58\u4f4d\u7f6e\uff0c\u67e5\u770b\u5f53\u524d\u5360\u7528\uff0c\u5e76\u5728\u9700\u8981\u65f6\u6e05\u7406\u672c\u5730\u7f13\u5b58\u6587\u4ef6\u3002"
            }

            LabeledControl {
                label: "\u7f13\u5b58\u76ee\u5f55"
                hint: "\u7559\u7a7a\u65f6\u4f7f\u7528\u7cfb\u7edf\u9ed8\u8ba4\u7f13\u5b58\u76ee\u5f55\uff1b\u4fee\u6539\u540e\u4f1a\u5f71\u54cd\u540e\u7eed\u9884\u89c8\u7f13\u5b58\u3002"

                GridLayout {
                    Layout.fillWidth: true
                    columns: root.compact ? 1 : 3
                    columnSpacing: 12
                    rowSpacing: 12

                    AppTextField {
                        Layout.fillWidth: true
                        text: root.settingsVm.cacheDir
                        placeholderText: "\u9ed8\u8ba4\u672c\u5730\u7f13\u5b58\u76ee\u5f55"
                        onTextEdited: root.settingsVm.setCacheDir(text)
                    }

                    SecondaryButton {
                        text: "\u9009\u62e9\u76ee\u5f55"
                        Layout.fillWidth: root.compact
                        tone: "primary"
                        onClicked: root.settingsVm.pickCacheDir()
                    }

                    SecondaryButton {
                        text: "\u6253\u5f00\u76ee\u5f55"
                        Layout.fillWidth: root.compact
                        onClicked: root.settingsVm.openCacheDir()
                    }
                }
            }

            GridLayout {
                Layout.fillWidth: true
                columns: root.compact ? 1 : 3
                columnSpacing: 14
                rowSpacing: 14

                KeyValueRow {
                    label: "\u7f13\u5b58\u5360\u7528"
                    value: root.settingsVm.cacheTotalSize
                }

                KeyValueRow {
                    label: "\u7f13\u5b58\u9879\u76ee"
                    value: root.settingsVm.cacheItemCount + " \u9879"
                }

                KeyValueRow {
                    label: "\u7f13\u5b58\u6587\u4ef6"
                    value: root.settingsVm.cacheFileCount + " \u4e2a"
                }
            }

            LabeledControl {
                label: "\u7f13\u5b58\u5185\u5bb9"
                hint: "\u663e\u793a\u6700\u8fd1\u7684\u524d 50 \u4e2a\u7f13\u5b58\u6587\u4ef6\u3002"

                ConsoleArea {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 220
                    text: root.settingsVm.cacheItemsText
                }
            }

            Flow {
                Layout.fillWidth: true
                spacing: 12

                PrimaryButton {
                    text: "\u4fdd\u5b58\u7f13\u5b58\u8bbe\u7f6e"
                    onClicked: root.settingsVm.saveCacheSettings()
                }

                SecondaryButton {
                    text: "\u5237\u65b0\u5217\u8868"
                    onClicked: root.settingsVm.refreshCacheStats()
                }

                SecondaryButton {
                    text: "\u6e05\u9664\u7f13\u5b58"
                    tone: "danger"
                    onClicked: root.settingsVm.clearCache()
                }
            }
        }
    }

}
