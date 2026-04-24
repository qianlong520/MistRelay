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
        serverStatusMessage: "",
        serverCategories: [],
        serverFieldsModel: null,
        rcloneConfigPath: "",
        rcloneConfigText: "",
        rcloneRemotes: [],
        dockerLogLines: 200,
        dockerLogs: "",
        logFilesModel: null,
        logKeyword: "",
        logTailCount: 200,
        appLogSummary: "",
        appLogText: "",
        bootstrap: function() {},
        setServerBaseUrl: function() {},
        setProxyEnabled: function() {},
        setProxyUrl: function() {},
        setDownloadDir: function() {},
        pickDownloadDir: function() {},
        setMaxConcurrentDownloads: function() {},
        setThreadsPerDownload: function() {},
        save: function() {},
        loadServerCategory: function() {},
        reloadServerConfig: function() {},
        saveServerCategory: function() {},
        setServerField: function() {},
        setRcloneConfigText: function() {},
        saveRcloneConfigFile: function() {},
        loadRcloneConfigFile: function() {},
        restartDocker: function() {},
        setDockerLogLines: function() {},
        loadDockerLogs: function() {},
        clearDockerLogs: function() {},
        setSelectedLogFile: function() {},
        setLogLevel: function() {},
        setLogKeyword: function() {},
        setLogTailCount: function() {},
        loadAppLogs: function() {},
        downloadSelectedLogFile: function() {},
        clearAppLogDisplay: function() {}
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

    property string scope: "client"
    property string clientTab: "connection"
    property string serverCategory: "telegram"
    property string managementTab: "docker"
    readonly property int formColumns: compact ? 1 : 2
    readonly property int managementMetricColumns: compact ? 1 : 3
    readonly property int logFilterColumns: compact ? 1 : 2
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
    onServerCategoryChanged: {
        root.settingsVm.loadServerCategory(serverCategory)
        if (serverCategory === "rclone") {
            root.settingsVm.loadRcloneConfigFile()
        }
    }

    component ScopeButton: Button {
        id: scopeButton
        required property string buttonValue
        required property string buttonLabel

        text: buttonLabel
        checkable: true
        checked: root.scope === buttonValue
        hoverEnabled: true
        implicitHeight: 42
        horizontalPadding: 18
        onClicked: root.scope = buttonValue

        background: Rectangle {
            radius: ThemeSystem.Theme.radiusMedium
            color: scopeButton.checked
                   ? ThemeSystem.Theme.sidebarActiveFill
                   : (scopeButton.hovered ? ThemeSystem.Theme.sidebarHoverFill : "#ffffff")
            border.width: 1
            border.color: scopeButton.checked
                          ? "#9dc7f0"
                          : (scopeButton.hovered ? ThemeSystem.Theme.lineColorStrong : ThemeSystem.Theme.cardBorder)

            Behavior on color {
                ColorAnimation { duration: ThemeSystem.Theme.fastDuration }
            }

        }

        contentItem: Text {
            text: scopeButton.text
            color: scopeButton.checked ? ThemeSystem.Theme.colorPrimary : ThemeSystem.Theme.textPrimary
            font.bold: true
            font.family: ThemeSystem.Theme.fontFamily
            horizontalAlignment: Text.AlignHCenter
            verticalAlignment: Text.AlignVCenter
        }
    }

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

    GlassCard {
        Layout.fillWidth: true
        backgroundColor: "#fbfdff"
        borderColor: ThemeSystem.Theme.cardBorderStrong
        shadowOpacity: 0.1
        shadowOffsetY: 12
        shadowSpread: 22
        implicitHeight: headerContent.implicitHeight + padding * 2

        GridLayout {
            id: headerContent
            anchors.fill: parent
            columns: root.compact ? 1 : 2
            columnSpacing: 20
            rowSpacing: 16

            ColumnLayout {
                Layout.fillWidth: true
                spacing: 18

                FluentSectionHeader {
                    Layout.fillWidth: true
                    eyebrow: "SETTINGS"
                    title: "设置中心"
                    description: "客户端配置、服务端参数、资源监控、系统日志与更新入口统一收敛到 Qt 设置页，布局会根据窗口宽度自动调整。"
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 10

                    ScopeButton {
                        buttonValue: "client"
                        buttonLabel: "客户端设置"
                    }

                    ScopeButton {
                        buttonValue: "server"
                        buttonLabel: "服务端设置"
                    }

                    ScopeButton {
                        buttonValue: "management"
                        buttonLabel: "系统管理"
                    }
                }
            }

            Rectangle {
                visible: !root.compact
                Layout.fillWidth: true
                radius: ThemeSystem.Theme.radiusLarge
                color: ThemeSystem.Theme.panelSurfaceSecondary
                border.width: 1
                border.color: ThemeSystem.Theme.cardBorder
                implicitHeight: headerAside.implicitHeight + 24

                ColumnLayout {
                    id: headerAside
                    anchors.fill: parent
                    anchors.margins: 16
                    spacing: 10

                    Text {
                        text: "布局优化已启用"
                        color: ThemeSystem.Theme.colorPrimary
                        font.pixelSize: 12
                        font.bold: true
                        font.family: ThemeSystem.Theme.fontFamily
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "系统管理区现在保留 Docker 日志、系统日志和容器重启入口，操作更聚焦。"
                        color: ThemeSystem.Theme.textPrimary
                        font.pixelSize: 14
                        font.bold: true
                        wrapMode: Text.WordWrap
                        font.family: ThemeSystem.Theme.fontFamily
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "保持现有 PySide 状态层和接口不变，只整理视觉层级、文案和响应式布局。"
                        color: ThemeSystem.Theme.textSecondary
                        font.pixelSize: 13
                        wrapMode: Text.WordWrap
                        font.family: ThemeSystem.Theme.fontFamily
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: 8

                        Repeater {
                            model: ["响应式布局", "统一文案", "系统管理重构"]

                            delegate: Rectangle {
                                id: tagChip
                                required property string modelData

                                radius: 999
                                color: "#ffffff"
                                border.width: 1
                                border.color: ThemeSystem.Theme.cardBorder
                                implicitHeight: 30
                                implicitWidth: tagLabel.implicitWidth + 22

                                Text {
                                    id: tagLabel
                                    anchors.centerIn: parent
                                    text: tagChip.modelData
                                    color: ThemeSystem.Theme.textSecondary
                                    font.pixelSize: 12
                                    font.bold: true
                                    font.family: ThemeSystem.Theme.fontFamily
                                }
                            }
                        }
                    }
                }
            }
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
            sourceComponent: root.scope === "client"
                             ? clientScope
                             : root.scope === "server"
                               ? serverScope
                               : managementScope
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
                    }

                    Loader {
                        Layout.fillWidth: true
                        sourceComponent: root.clientTab === "connection"
                                         ? clientConnectionTab
                                         : root.clientTab === "update"
                                           ? clientUpdateTab
                                           : root.clientTab === "proxy"
                                             ? clientProxyTab
                                             : clientDownloadTab
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
        id: serverScope

        ColumnLayout {
            width: root.contentFrameWidth
            spacing: root.sectionSpacing

            GlassCard {
                Layout.fillWidth: true
                backgroundColor: "#ffffff"
                implicitHeight: serverOverviewContent.implicitHeight + padding * 2

                ColumnLayout {
                    id: serverOverviewContent
                    anchors.fill: parent
                    spacing: 18

                    SectionIntro {
                        eyebrow: "SERVER"
                        title: "服务端设置"
                        description: "按类别查看与编辑服务端配置，并支持重新读取或从 config.yml 导入。"
                    }

                    Text {
                        Layout.fillWidth: true
                        text: root.settingsVm.serverStatusMessage
                        wrapMode: Text.WordWrap
                        color: ThemeSystem.Theme.textSecondary
                        font.family: ThemeSystem.Theme.fontFamily
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: 10

                        Repeater {
                            model: root.settingsVm.serverCategories

                            delegate: FilterButton {
                                required property var modelData

                                text: modelData.label
                                activeState: root.serverCategory === modelData.key
                                onClicked: root.serverCategory = modelData.key
                            }
                        }
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: 12

                        PrimaryButton {
                            text: "保存当前分类"
                            onClicked: root.settingsVm.saveServerCategory(root.serverCategory)
                        }

                        SecondaryButton {
                            text: "重新读取"
                            tone: "primary"
                            onClicked: root.settingsVm.loadServerCategory(root.serverCategory)
                        }

                        SecondaryButton {
                            text: "从 config.yml 重新导入"
                            tone: "primary"
                            onClicked: root.settingsVm.reloadServerConfig(root.serverCategory)
                        }
                    }
                }
            }

            GlassCard {
                Layout.fillWidth: true
                backgroundColor: "#ffffff"
                implicitHeight: serverFieldsContent.implicitHeight + padding * 2

                ColumnLayout {
                    id: serverFieldsContent
                    anchors.fill: parent
                    spacing: 16

                    SectionIntro {
                        eyebrow: "DETAILS"
                        title: "配置字段"
                        description: "按当前分类展示可编辑字段，保存后会同步服务端配置。"
                    }

                    Repeater {
                        model: root.settingsVm.serverFieldsModel || []

                        delegate: ColumnLayout {
                            required property string key
                            required property string label
                            required property string fieldType
                            required property var value

                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                text: parent.label
                                color: ThemeSystem.Theme.textPrimary
                                font.bold: true
                                wrapMode: Text.WordWrap
                                font.family: ThemeSystem.Theme.fontFamily
                            }

                            Loader {
                                Layout.fillWidth: true
                                property string fieldKey: parent.key
                                property var fieldValue: parent.value
                                sourceComponent: parent.fieldType === "bool"
                                                 ? boolField
                                                 : parent.fieldType === "multiline"
                                                   ? multilineField
                                                   : parent.fieldType === "int"
                                                     ? intField
                                                     : parent.fieldType === "password"
                                                       ? passwordField
                                                       : textField
                            }
                        }
                    }
                }
            }

            GlassCard {
                visible: root.serverCategory === "rclone"
                Layout.fillWidth: true
                backgroundColor: "#ffffff"
                implicitHeight: rcloneContent.implicitHeight + padding * 2

                ColumnLayout {
                    id: rcloneContent
                    anchors.fill: parent
                    spacing: 14

                    SectionIntro {
                        eyebrow: "RCLONE"
                        title: "Rclone 配置文件"
                        description: "查看或编辑当前服务端的 Rclone 配置内容，并同步远端列表。"
                    }

                    Text {
                        Layout.fillWidth: true
                        text: "路径：" + root.settingsVm.rcloneConfigPath
                        wrapMode: Text.WordWrap
                        color: ThemeSystem.Theme.textSecondary
                        font.family: ThemeSystem.Theme.fontFamily
                    }

                    TextArea {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 260
                        text: root.settingsVm.rcloneConfigText
                        wrapMode: TextArea.NoWrap
                        font.family: "Consolas"
                        onTextChanged: if (activeFocus) root.settingsVm.setRcloneConfigText(text)

                        background: Rectangle {
                            radius: ThemeSystem.Theme.radiusMedium
                            color: "#0f172a"
                            border.width: 1
                            border.color: "#1e293b"
                        }

                        color: "#e2e8f0"
                        selectionColor: ThemeSystem.Theme.colorPrimary
                    }

                    Text {
                        visible: root.settingsVm.rcloneRemotes.length > 0
                        Layout.fillWidth: true
                        text: "已发现 Remotes：" + root.settingsVm.rcloneRemotes.map(function(item) {
                                  return item.name || item.remote || ""
                              }).filter(function(item) {
                                  return item.length > 0
                              }).join(", ")
                        wrapMode: Text.WordWrap
                        color: ThemeSystem.Theme.textSecondary
                        font.family: ThemeSystem.Theme.fontFamily
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: 12

                        PrimaryButton {
                            text: "保存 Rclone 配置"
                            onClicked: root.settingsVm.saveRcloneConfigFile()
                        }

                        SecondaryButton {
                            text: "重新读取"
                            tone: "primary"
                            onClicked: root.settingsVm.loadRcloneConfigFile()
                        }
                    }
                }
            }
        }
    }

    Component {
        id: managementScope

        ColumnLayout {
            width: root.contentFrameWidth
            spacing: root.sectionSpacing

            GlassCard {
                Layout.fillWidth: true
                backgroundColor: "#ffffff"
                implicitHeight: managementOverviewContent.implicitHeight + padding * 2

                ColumnLayout {
                    id: managementOverviewContent
                    anchors.fill: parent
                    spacing: 18

                    SectionIntro {
                        eyebrow: "MANAGEMENT"
                        title: "系统管理"
                        description: "集中查看 Docker 日志与系统日志，并提供容器重启操作。"
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: 10

                        FilterButton {
                            text: "Docker 日志"
                            activeState: root.managementTab === "docker"
                            onClicked: root.managementTab = "docker"
                        }

                        FilterButton {
                            text: "系统日志"
                            activeState: root.managementTab === "app-logs"
                            onClicked: root.managementTab = "app-logs"
                        }

                        PrimaryButton {
                            text: "重启容器"
                            onClicked: root.settingsVm.restartDocker()
                        }
                    }
                }
            }

            Loader {
                Layout.fillWidth: true
                sourceComponent: root.managementTab === "docker"
                                 ? dockerManagementTab
                                 : appLogsManagementTab
            }
        }
    }

    Component {
        id: dockerManagementTab

        ColumnLayout {
            width: root.contentFrameWidth
            spacing: root.sectionSpacing

            GlassCard {
                Layout.fillWidth: true
                backgroundColor: "#ffffff"
                implicitHeight: dockerLogsContent.implicitHeight + padding * 2

                ColumnLayout {
                    id: dockerLogsContent
                    anchors.fill: parent
                    spacing: 16

                    GridLayout {
                        Layout.fillWidth: true
                        columns: root.formColumns
                        columnSpacing: 18
                        rowSpacing: 12

                        SectionIntro {
                            eyebrow: "LOGS"
                            title: "Docker 日志"
                            description: "控制显示行数并独立查看容器日志输出，日志面板会保持稳定高度。"
                        }

                        LabeledControl {
                            label: "显示行数"
                            Layout.alignment: Qt.AlignTop

                            SpinBox {
                                from: 20
                                to: 500
                                value: root.settingsVm.dockerLogLines
                                onValueModified: root.settingsVm.setDockerLogLines(value)
                            }
                        }
                    }

                    ConsoleArea {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 360
                        text: root.settingsVm.dockerLogs
                    }

                    Text {
                        visible: root.settingsVm.dockerLogs.length === 0
                        Layout.fillWidth: true
                        text: "暂无日志内容，点击“刷新日志”获取最近输出。"
                        color: ThemeSystem.Theme.textTertiary
                        wrapMode: Text.WordWrap
                        font.family: ThemeSystem.Theme.fontFamily
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: 12

                        SecondaryButton {
                            text: "刷新日志"
                            tone: "primary"
                            onClicked: root.settingsVm.loadDockerLogs()
                        }

                        SecondaryButton {
                            text: "清空显示"
                            tone: "warning"
                            onClicked: root.settingsVm.clearDockerLogs()
                        }
                    }
                }
            }
        }
    }

    Component {
        id: appLogsManagementTab

        ColumnLayout {
            width: root.contentFrameWidth
            spacing: root.sectionSpacing

            GlassCard {
                Layout.fillWidth: true
                backgroundColor: "#ffffff"
                implicitHeight: appLogsContent.implicitHeight + padding * 2

                ColumnLayout {
                    id: appLogsContent
                    anchors.fill: parent
                    spacing: 18

                    SectionIntro {
                        eyebrow: "APP LOGS"
                        title: "系统日志"
                        description: "按日志文件、级别与关键词筛选系统日志，日志控制台保持独立区域显示。"
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: root.logFilterColumns
                        columnSpacing: 16
                        rowSpacing: 16

                        LabeledControl {
                            label: "日志文件"

                            ComboBox {
                                Layout.fillWidth: true
                                model: root.settingsVm.logFilesModel || []
                                textRole: "name"
                                onActivated: function(index) {
                                    var item = root.settingsVm.logFilesModel.get(index)
                                    root.settingsVm.setSelectedLogFile(item.name || "")
                                    root.settingsVm.loadAppLogs()
                                }
                            }
                        }

                        LabeledControl {
                            label: "日志级别"

                            ComboBox {
                                Layout.fillWidth: true
                                model: ["", "ERROR", "WARNING", "INFO", "DEBUG"]
                                onActivated: function(index) {
                                    root.settingsVm.setLogLevel(model[index])
                                    root.settingsVm.loadAppLogs()
                                }
                            }
                        }

                        LabeledControl {
                            label: "关键词"

                            AppTextField {
                                Layout.fillWidth: true
                                text: root.settingsVm.logKeyword
                                placeholderText: "输入关键词后回车搜索"
                                onTextEdited: root.settingsVm.setLogKeyword(text)
                                onAccepted: root.settingsVm.loadAppLogs()
                            }
                        }

                        LabeledControl {
                            label: "尾部行数"

                            SpinBox {
                                from: 50
                                to: 1000
                                stepSize: 50
                                value: root.settingsVm.logTailCount
                                onValueModified: root.settingsVm.setLogTailCount(value)
                            }
                        }
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: 12

                        PrimaryButton {
                            text: "刷新日志"
                            onClicked: root.settingsVm.loadAppLogs()
                        }

                        SecondaryButton {
                            text: "下载当前日志"
                            tone: "primary"
                            onClicked: root.settingsVm.downloadSelectedLogFile()
                        }

                        SecondaryButton {
                            text: "清空显示"
                            tone: "warning"
                            onClicked: root.settingsVm.clearAppLogDisplay()
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        radius: ThemeSystem.Theme.radiusMedium
                        color: ThemeSystem.Theme.panelSurfaceSecondary
                        border.width: 1
                        border.color: ThemeSystem.Theme.cardBorder
                        implicitHeight: logSummaryText.implicitHeight + 20

                        Text {
                            id: logSummaryText
                            anchors.fill: parent
                            anchors.margins: 10
                            text: root.settingsVm.appLogSummary
                            color: ThemeSystem.Theme.textSecondary
                            wrapMode: Text.WordWrap
                            font.family: ThemeSystem.Theme.fontFamily
                        }
                    }

                    ConsoleArea {
                        Layout.fillWidth: true
                        Layout.preferredHeight: 520
                        text: root.settingsVm.appLogText
                    }
                }
            }
        }
    }

    Component {
        id: textField

        AppTextField {
            Layout.fillWidth: true
            text: parent.fieldValue === undefined || parent.fieldValue === null ? "" : String(parent.fieldValue)
            onTextEdited: root.settingsVm.setServerField(root.serverCategory, parent.fieldKey, text)
        }
    }

    Component {
        id: passwordField

        AppTextField {
            Layout.fillWidth: true
            text: parent.fieldValue === undefined || parent.fieldValue === null ? "" : String(parent.fieldValue)
            echoMode: TextInput.Password
            onTextEdited: root.settingsVm.setServerField(root.serverCategory, parent.fieldKey, text)
        }
    }

    Component {
        id: multilineField

        TextArea {
            Layout.fillWidth: true
            Layout.preferredHeight: 120
            text: parent.fieldValue === undefined || parent.fieldValue === null ? "" : String(parent.fieldValue)
            wrapMode: TextArea.Wrap
            onTextChanged: if (activeFocus) root.settingsVm.setServerField(root.serverCategory, parent.fieldKey, text)

            background: Rectangle {
                radius: ThemeSystem.Theme.radiusMedium
                color: "#f8fafc"
                border.width: 1
                border.color: ThemeSystem.Theme.lineColor
            }

            color: ThemeSystem.Theme.textPrimary
            selectionColor: ThemeSystem.Theme.colorPrimary
        }
    }

    Component {
        id: intField

        SpinBox {
            from: -2147483647
            to: 2147483647
            value: Number(parent.fieldValue || 0)
            onValueModified: root.settingsVm.setServerField(root.serverCategory, parent.fieldKey, value)
        }
    }

    Component {
        id: boolField

        RowLayout {
            spacing: 12

            Switch {
                checked: Boolean(parent.fieldValue)
                onToggled: root.settingsVm.setServerField(root.serverCategory, parent.fieldKey, checked)
            }

            Text {
                text: Boolean(parent.fieldValue) ? "已启用" : "未启用"
                color: ThemeSystem.Theme.textSecondary
                font.family: ThemeSystem.Theme.fontFamily
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
