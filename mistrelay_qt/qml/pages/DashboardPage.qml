pragma ComponentBehavior: Bound

import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme" as ThemeSystem
import "../components"

ResponsivePage {
    id: root

    horizontalPadding: 26
    verticalPadding: 24
    sectionSpacing: 24

    readonly property var statCards: dashboardViewModel.statCards
    readonly property var resourceCards: dashboardViewModel.resourceCards
    readonly property var trendPoints: dashboardViewModel.trendPoints
    readonly property var recentDownloads: dashboardViewModel.recentDownloads
    readonly property var systemInfo: dashboardViewModel.systemInfo
    readonly property var botLoadRows: dashboardViewModel.botLoadRows
    readonly property int resourceColumns: compact ? 1 : 3
    readonly property int topRowHeight: compact ? -1 : 436
    readonly property int secondRowHeight: compact ? -1 : 420
    readonly property real secondRowResolvedHeight: compact ? -1 : Math.max(secondRowHeight, downloadsCardLayout.implicitHeight, systemCardLayout.implicitHeight)
    readonly property real monitorMaxValue: root.resolveMonitorMaxValue()
    readonly property var monitorAxisRatios: [1.0, 0.8, 0.6, 0.4, 0.2, 0.0]

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

    function resolveMonitorMaxValue() {
        var points = root.trendPoints || []
        var maxValue = 1024
        for (var index = 0; index < points.length; ++index) {
            var point = points[index]
            maxValue = Math.max(
                maxValue,
                Number(point.upload || 0),
                Number(point.download || 0),
                Number(point.io || 0)
            )
        }
        return maxValue
    }

    function formatTrafficValue(value) {
        var amount = Number(value || 0)
        if (amount <= 0)
            return "0"
        if (amount < 1024)
            return Math.round(amount).toString()
        if (amount < 1024 * 1024)
            return (amount / 1024).toFixed(1) + " K"
        if (amount < 1024 * 1024 * 1024)
            return (amount / 1024 / 1024).toFixed(1) + " M"
        return (amount / 1024 / 1024 / 1024).toFixed(1) + " G"
    }

    function resourceAccentColor(card) {
        var percent = Number(card.percent || 0)
        if (card.title === "内存")
            return "#16c79a"
        if (card.title === "硬盘")
            return "#f59e0b"
        return percent <= 0.1 ? "#d7dee9" : "#84cc16"
    }

    function resourceBadgeBackground(card) {
        if (card.title === "硬盘")
            return "#fff3e3"
        return "#eef8e8"
    }

    function resourceDetailText(card) {
        var caption = String(card.caption || "")
        if (caption.indexOf("/") >= 0 || caption.indexOf("等待") >= 0)
            return caption
        return ""
    }

    function placeholderStatCards() {
        return [
            { "title": "完成", "value": "--", "caption": "已完成任务", "tone": "success" },
            { "title": "清理", "value": "--", "caption": "待处理任务", "tone": "info" },
            { "title": "失败", "value": "--", "caption": "异常任务", "tone": "danger" },
            { "title": "总计", "value": "--", "caption": "历史任务数", "tone": "primary" }
        ]
    }

    function placeholderRecentDownloads() {
        return [
            { "title": "等待获取下载记录", "status": "待同步", "statusTone": "info", "time": "--" },
            { "title": "首页会在刷新后展示最近任务", "status": "待同步", "statusTone": "primary", "time": "--" }
        ]
    }

    function placeholderSystemInfo() {
        return [
            { "label": "运行状态", "value": "等待同步", "tone": "info" },
            { "label": "运行时长", "value": "--", "tone": "primary" },
            { "label": "Telegram Bot", "value": "@unknown", "tone": "primary" },
            { "label": "已连接机器人", "value": "--", "tone": "primary" }
        ]
    }

    function placeholderBotLoadRows() {
        return [
            { "label": "bot-1", "value": "0", "percent": 0, "tone": "info" },
            { "label": "bot-2", "value": "0", "percent": 0, "tone": "info" }
        ]
    }

    Component.onCompleted: {
        if (!dashboardViewModel.busy
                && root.statCards.length === 0
                && root.resourceCards.length === 0
                && root.recentDownloads.length === 0) {
            dashboardViewModel.refresh()
        }
    }

    Timer {
        interval: 1000
        repeat: true
        running: root.visible && appViewModel.currentRoute === "dashboard"
        triggeredOnStart: false
        onTriggered: {
            if (!dashboardViewModel.busy)
                dashboardViewModel.refresh()
        }
    }

    onTrendPointsChanged: monitorCanvas.requestPaint()
    onMonitorMaxValueChanged: monitorCanvas.requestPaint()

    FluentBanner {
        Layout.fillWidth: true
        visible: dashboardViewModel.errorMessage.length > 0
        tone: "danger"
        title: "首页数据拉取失败"
        description: dashboardViewModel.errorMessage
    }

    GlassCard {
        Layout.fillWidth: true
        padding: 14
        backgroundColor: "#fbfdff"
        borderColor: ThemeSystem.Theme.cardBorder
        shadowOpacity: 0.04
        shadowOffsetY: 8
        shadowSpread: 14
        implicitHeight: 76

        RowLayout {
            anchors.fill: parent
            spacing: 8

            Repeater {
                model: root.statCards.length > 0 ? root.statCards : root.placeholderStatCards()

                delegate: Rectangle {
                    id: taskStatItem

                    required property var modelData

                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    radius: ThemeSystem.Theme.radiusLarge
                    color: root.toneSoftColor(taskStatItem.modelData.tone)
                    border.width: 1
                    border.color: Qt.rgba(root.toneColor(taskStatItem.modelData.tone).r,
                                           root.toneColor(taskStatItem.modelData.tone).g,
                                           root.toneColor(taskStatItem.modelData.tone).b, 0.16)

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 10

                        Text {
                            text: taskStatItem.modelData.title
                            color: ThemeSystem.Theme.textSecondary
                            font.pixelSize: 12
                            font.bold: true
                            font.family: ThemeSystem.Theme.fontFamily
                        }

                        Item {
                            Layout.fillWidth: true
                        }

                        Text {
                            text: taskStatItem.modelData.value
                            color: root.toneColor(taskStatItem.modelData.tone)
                            font.pixelSize: 24
                            font.bold: true
                            font.family: ThemeSystem.Theme.fontFamily
                        }
                    }
                }
            }
        }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: root.compact ? 1 : 6
        columnSpacing: 18
        rowSpacing: 18

        GlassCard {
            Layout.fillWidth: true
            Layout.columnSpan: root.compact ? 1 : 4
            Layout.preferredHeight: root.compact ? monitorCardLayout.implicitHeight + 24 : root.topRowHeight
            backgroundColor: "#fbfdff"
            borderColor: ThemeSystem.Theme.cardBorder
            shadowOpacity: 0.1
            shadowOffsetY: 12
            shadowSpread: 22
            padding: 0
            implicitHeight: root.compact ? monitorCardLayout.implicitHeight + 24 : root.topRowHeight

            ColumnLayout {
                id: monitorCardLayout

                anchors.fill: parent
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    Layout.leftMargin: 22
                    Layout.rightMargin: 22
                    Layout.topMargin: 20
                    Layout.bottomMargin: 18
                    text: "实时监控"
                    color: ThemeSystem.Theme.textPrimary
                    font.pixelSize: 20
                    font.bold: true
                    font.family: ThemeSystem.Theme.fontFamily
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: "#e4ebf4"
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.leftMargin: 18
                    Layout.rightMargin: 18
                    Layout.topMargin: 16
                    Layout.bottomMargin: 16
                    spacing: 12

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                        implicitHeight: 280

                        RowLayout {
                            anchors.fill: parent
                            spacing: 10

                            Item {
                                id: axisLabels

                                Layout.preferredWidth: 56
                                Layout.fillHeight: true

                                Repeater {
                                    model: root.monitorAxisRatios.length

                                    delegate: Text {
                                        required property int index

                                        width: axisLabels.width - 6
                                        horizontalAlignment: Text.AlignRight
                                        text: root.formatTrafficValue(root.monitorMaxValue * root.monitorAxisRatios[index])
                                        color: ThemeSystem.Theme.textSecondary
                                        font.pixelSize: 12
                                        font.family: ThemeSystem.Theme.fontFamily
                                        y: Math.max(0, Math.min(axisLabels.height - height, plotArea.topInset + index * plotArea.chartHeight / Math.max(1, root.monitorAxisRatios.length - 1) - height / 2))
                                    }
                                }
                            }

                            Item {
                                id: plotArea

                                Layout.fillWidth: true
                                Layout.fillHeight: true

                                property real topInset: 12
                                property real bottomInset: 30
                                property real chartHeight: Math.max(1, height - topInset - bottomInset)
                                property real chartWidth: Math.max(1, width)

                                Repeater {
                                    model: root.monitorAxisRatios.length

                                    delegate: Rectangle {
                                        required property int index

                                        x: 0
                                        y: plotArea.topInset + index * plotArea.chartHeight / Math.max(1, root.monitorAxisRatios.length - 1)
                                        width: plotArea.width
                                        height: 1
                                        color: "#dbe4ef"
                                    }
                                }

                                Canvas {
                                    id: monitorCanvas

                                    anchors.fill: parent
                                    antialiasing: true

                                    onPaint: {
                                        var ctx = getContext("2d")
                                        ctx.clearRect(0, 0, width, height)

                                        var points = root.trendPoints || []
                                        if (points.length === 0)
                                            return

                                        function drawSeries(key, color, lineWidth) {
                                            ctx.beginPath()
                                            for (var i = 0; i < points.length; ++i) {
                                                var point = points[i]
                                                var ratio = Math.max(0, Math.min(1, Number(point[key] || 0)))
                                                var x = points.length === 1 ? plotArea.chartWidth / 2 : (i / Math.max(1, points.length - 1)) * plotArea.chartWidth
                                                var y = plotArea.topInset + plotArea.chartHeight * (1 - ratio)
                                                if (i === 0)
                                                    ctx.moveTo(x, y)
                                                else
                                                    ctx.lineTo(x, y)
                                            }
                                            ctx.strokeStyle = color
                                            ctx.lineWidth = lineWidth
                                            ctx.lineJoin = "round"
                                            ctx.lineCap = "round"
                                            ctx.stroke()
                                        }

                                        drawSeries("uploadRatio", "#6d8df6", 2.2)
                                        drawSeries("downloadRatio", "#19c98a", 2.2)
                                        drawSeries("ioRatio", "#f59e0b", 2.2)
                                    }

                                    onWidthChanged: requestPaint()
                                    onHeightChanged: requestPaint()

                                    Component.onCompleted: requestPaint()
                                }

                                Item {
                                    anchors.fill: parent
                                    visible: root.trendPoints.length === 0

                                    Text {
                                        anchors.centerIn: parent
                                        text: "等待趋势数据"
                                        color: ThemeSystem.Theme.textSecondary
                                        font.pixelSize: 14
                                        font.family: ThemeSystem.Theme.fontFamily
                                    }
                                }

                                Repeater {
                                    id: trendLabelRepeater
                                    model: root.trendPoints

                                    delegate: Text {
                                        required property var modelData
                                        required property int index

                                        visible: index % Math.max(1, Math.ceil(trendLabelRepeater.count / 6)) === 0
                                                 || index === trendLabelRepeater.count - 1
                                        text: modelData.label
                                        color: ThemeSystem.Theme.textSecondary
                                        font.pixelSize: 11
                                        font.family: ThemeSystem.Theme.fontFamily
                                        y: plotArea.topInset + plotArea.chartHeight + 6
                                        x: Math.max(0, Math.min(plotArea.width - width,
                                                                (trendLabelRepeater.count === 1
                                                                 ? plotArea.chartWidth / 2
                                                                 : index * plotArea.chartWidth / Math.max(1, trendLabelRepeater.count - 1)) - width / 2))
                                    }
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignHCenter
                        spacing: 14

                        Repeater {
                            model: [
                                { "label": "上传速度", "color": "#6d8df6" },
                                { "label": "下载速度", "color": "#19c98a" },
                                { "label": "IO占用", "color": "#f59e0b" }
                            ]

                            delegate: RowLayout {
                                required property var modelData

                                spacing: 6

                                Item {
                                    Layout.preferredWidth: 22
                                    Layout.preferredHeight: 14

                                    Rectangle {
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.right: parent.right
                                        height: 2
                                        radius: 1
                                        color: modelData.color
                                    }

                                    Rectangle {
                                        anchors.centerIn: parent
                                        width: 10
                                        height: 10
                                        radius: 5
                                        color: "#ffffff"
                                        border.width: 2
                                        border.color: modelData.color
                                    }
                                }

                                Text {
                                    text: modelData.label
                                    color: ThemeSystem.Theme.textSecondary
                                    font.pixelSize: 12
                                    font.family: ThemeSystem.Theme.fontFamily
                                }
                            }
                        }
                    }
                }
            }
        }

        GlassCard {
            Layout.fillWidth: true
            Layout.columnSpan: root.compact ? 1 : 2
            Layout.preferredHeight: root.compact ? loadPanelLayout.implicitHeight + 24 : root.topRowHeight
            backgroundColor: "#fbfdff"
            borderColor: ThemeSystem.Theme.cardBorder
            shadowOpacity: 0.08
            shadowOffsetY: 10
            shadowSpread: 18
            padding: 0
            implicitHeight: root.compact ? loadPanelLayout.implicitHeight + 24 : root.topRowHeight

            ColumnLayout {
                id: loadPanelLayout

                anchors.fill: parent
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    Layout.leftMargin: 22
                    Layout.rightMargin: 22
                    Layout.topMargin: 20
                    Layout.bottomMargin: 18
                    text: "系统负载"
                    color: ThemeSystem.Theme.textPrimary
                    font.pixelSize: 20
                    font.bold: true
                    font.family: ThemeSystem.Theme.fontFamily
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: "#e4ebf4"
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    Layout.leftMargin: 18
                    Layout.rightMargin: 18
                    Layout.topMargin: 18
                    Layout.bottomMargin: 18
                    spacing: 14

                    Repeater {
                        model: root.resourceCards.length > 0 ? root.resourceCards : [
                            { "title": "CPU", "value": "--", "caption": "等待资源数据", "tone": "info", "percent": 0 },
                            { "title": "内存", "value": "--", "caption": "等待资源数据", "tone": "info", "percent": 0 },
                            { "title": "硬盘", "value": "--", "caption": "等待资源数据", "tone": "info", "percent": 0 }
                        ]

                        delegate: Rectangle {
                            id: loadGroup

                            required property var modelData

                            Layout.fillWidth: true
                            Layout.fillHeight: !root.compact
                            radius: ThemeSystem.Theme.radiusLarge
                            color: "#fbfcff"
                            border.width: 1
                            border.color: "#edf2f8"
                            implicitHeight: loadGroupLayout.implicitHeight + 22

                            ColumnLayout {
                                id: loadGroupLayout

                                anchors.fill: parent
                                anchors.margins: 14
                                spacing: 10

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Item {
                                        Layout.preferredWidth: 16
                                        Layout.preferredHeight: 16

                                        Rectangle {
                                            visible: loadGroup.modelData.title === "CPU"
                                            anchors.centerIn: parent
                                            width: 12
                                            height: 12
                                            radius: 3
                                            color: "transparent"
                                            border.width: 1
                                            border.color: "#475569"

                                            Rectangle {
                                                anchors.centerIn: parent
                                                width: 4
                                                height: 4
                                                radius: 1
                                                color: "#475569"
                                            }
                                        }

                                        Rectangle {
                                            visible: loadGroup.modelData.title === "内存"
                                            anchors.centerIn: parent
                                            width: 12
                                            height: 10
                                            radius: 2
                                            color: "transparent"
                                            border.width: 1
                                            border.color: "#475569"

                                            Rectangle {
                                                anchors.horizontalCenter: parent.horizontalCenter
                                                anchors.verticalCenter: parent.verticalCenter
                                                width: 8
                                                height: 1
                                                color: "#475569"
                                            }
                                        }

                                        Rectangle {
                                            visible: loadGroup.modelData.title === "硬盘"
                                            anchors.centerIn: parent
                                            width: 12
                                            height: 10
                                            radius: 2
                                            color: "transparent"
                                            border.width: 1
                                            border.color: "#475569"

                                            Rectangle {
                                                anchors.left: parent.left
                                                anchors.right: parent.right
                                                anchors.top: parent.top
                                                anchors.topMargin: 2
                                                height: 1
                                                color: "#475569"
                                            }
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: loadGroup.modelData.title
                                        color: ThemeSystem.Theme.textPrimary
                                        font.pixelSize: 13
                                        font.bold: true
                                        font.family: ThemeSystem.Theme.fontFamily
                                    }

                                    Rectangle {
                                        radius: 8
                                        color: root.resourceBadgeBackground(loadGroup.modelData)
                                        implicitHeight: 22
                                        implicitWidth: badgeText.implicitWidth + 14

                                        Text {
                                            id: badgeText
                                            anchors.centerIn: parent
                                            text: loadGroup.modelData.value
                                            color: root.resourceAccentColor(loadGroup.modelData)
                                            font.pixelSize: 11
                                            font.bold: true
                                            font.family: ThemeSystem.Theme.fontFamily
                                        }
                                    }
                                }

                                RowLayout {
                                    Layout.fillWidth: true
                                    spacing: 8

                                    Rectangle {
                                        Layout.fillWidth: true
                                        Layout.preferredHeight: 8
                                        radius: 4
                                        color: "#e8edf5"

                                        Rectangle {
                                            width: parent.width * Math.max(0, Math.min(1, (loadGroup.modelData.percent || 0) / 100))
                                            height: parent.height
                                            radius: parent.radius
                                            color: root.resourceAccentColor(loadGroup.modelData)
                                        }
                                    }

                                    Text {
                                        text: Math.round(loadGroup.modelData.percent || 0) + "%"
                                        color: ThemeSystem.Theme.textSecondary
                                        font.pixelSize: 12
                                        font.bold: true
                                        font.family: ThemeSystem.Theme.fontFamily
                                    }
                                }

                                Text {
                                    visible: root.resourceDetailText(loadGroup.modelData).length > 0
                                    text: root.resourceDetailText(loadGroup.modelData)
                                    color: ThemeSystem.Theme.textSecondary
                                    font.pixelSize: 12
                                    font.family: ThemeSystem.Theme.fontFamily
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    GridLayout {
        Layout.fillWidth: true
        columns: root.compact ? 1 : 2
        columnSpacing: 18
        rowSpacing: 18

        GlassCard {
            Layout.fillWidth: true
            Layout.preferredHeight: root.compact ? -1 : root.secondRowResolvedHeight
            backgroundColor: "#fbfdff"
            borderColor: ThemeSystem.Theme.cardBorder
            shadowOpacity: 0.08
            shadowOffsetY: 10
            shadowSpread: 18
            padding: 0
            implicitHeight: root.compact ? downloadsCardLayout.implicitHeight : root.secondRowResolvedHeight

            ColumnLayout {
                id: downloadsCardLayout

                anchors.fill: parent
                spacing: 0

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 24
                    Layout.rightMargin: 24
                    Layout.topMargin: 20
                    Layout.bottomMargin: 18

                    Text {
                        Layout.fillWidth: true
                        text: "最近下载"
                        color: ThemeSystem.Theme.textPrimary
                        font.pixelSize: 22
                        font.bold: true
                        font.family: ThemeSystem.Theme.fontFamily
                    }

                    Button {
                        id: viewAllButton

                        implicitHeight: 36
                        leftPadding: 14
                        rightPadding: 14
                        hoverEnabled: true

                        background: Rectangle {
                            radius: 10
                            color: viewAllButton.down ? "#eef2f7" : "#ffffff"
                            border.width: 1
                            border.color: "#d5deea"

                            Behavior on color {
                                ColorAnimation { duration: ThemeSystem.Theme.fastDuration }
                            }
                        }

                        contentItem: Text {
                            text: "查看全部"
                            color: ThemeSystem.Theme.textPrimary
                            font.pixelSize: 14
                            font.bold: true
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.family: ThemeSystem.Theme.fontFamily
                        }

                        onClicked: appViewModel.navigate("downloads")
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: "#e4ebf4"
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 24
                    Layout.rightMargin: 24
                    Layout.topMargin: 16
                    Layout.bottomMargin: 6
                    spacing: 10

                    Text {
                        Layout.fillWidth: true
                        text: "文件名"
                        color: ThemeSystem.Theme.textTertiary
                        font.pixelSize: 12
                        font.bold: true
                        font.family: ThemeSystem.Theme.fontFamily
                    }

                    Text {
                        Layout.preferredWidth: 92
                        horizontalAlignment: Text.AlignHCenter
                        text: "状态"
                        color: ThemeSystem.Theme.textTertiary
                        font.pixelSize: 12
                        font.bold: true
                        font.family: ThemeSystem.Theme.fontFamily
                    }

                    Text {
                        Layout.preferredWidth: 146
                        horizontalAlignment: Text.AlignRight
                        text: "时间"
                        color: ThemeSystem.Theme.textTertiary
                        font.pixelSize: 12
                        font.bold: true
                        font.family: ThemeSystem.Theme.fontFamily
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 24
                    Layout.rightMargin: 24
                    Layout.bottomMargin: 20
                    spacing: 0

                    Repeater {
                        model: root.recentDownloads.length > 0 ? root.recentDownloads : root.placeholderRecentDownloads()

                        delegate: Item {
                            id: downloadItem

                            required property var modelData

                            Layout.fillWidth: true
                            implicitHeight: 40

                            RowLayout {
                                anchors.fill: parent
                                spacing: 10

                                Text {
                                    Layout.fillWidth: true
                                    text: downloadItem.modelData.title
                                    color: ThemeSystem.Theme.textPrimary
                                    font.pixelSize: 12
                                    elide: Text.ElideRight
                                    verticalAlignment: Text.AlignVCenter
                                    font.family: ThemeSystem.Theme.fontFamily
                                }

                                Rectangle {
                                    Layout.preferredWidth: 92
                                    implicitHeight: 24
                                    radius: 8
                                    color: root.toneSoftColor(downloadItem.modelData.statusTone)

                                    Text {
                                        anchors.centerIn: parent
                                        text: downloadItem.modelData.status
                                        color: root.toneColor(downloadItem.modelData.statusTone)
                                        font.pixelSize: 11
                                        font.bold: true
                                        font.family: ThemeSystem.Theme.fontFamily
                                    }
                                }

                                Text {
                                    Layout.preferredWidth: 146
                                    horizontalAlignment: Text.AlignRight
                                    text: downloadItem.modelData.time
                                    color: ThemeSystem.Theme.textSecondary
                                    font.pixelSize: 12
                                    elide: Text.ElideLeft
                                    verticalAlignment: Text.AlignVCenter
                                    font.family: ThemeSystem.Theme.fontFamily
                                }
                            }

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 1
                                color: "#e8edf5"
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                }
            }
        }

        GlassCard {
            Layout.fillWidth: true
            Layout.preferredHeight: root.compact ? -1 : root.secondRowResolvedHeight
            backgroundColor: "#fbfdff"
            borderColor: ThemeSystem.Theme.cardBorder
            shadowOpacity: 0.08
            shadowOffsetY: 10
            shadowSpread: 18
            padding: 0
            implicitHeight: root.compact ? systemCardLayout.implicitHeight : root.secondRowResolvedHeight

            ColumnLayout {
                id: systemCardLayout

                anchors.fill: parent
                spacing: 0

                Text {
                    Layout.fillWidth: true
                    Layout.leftMargin: 24
                    Layout.rightMargin: 24
                    Layout.topMargin: 20
                    Layout.bottomMargin: 18
                    text: "系统信息"
                    color: ThemeSystem.Theme.textPrimary
                    font.pixelSize: 22
                    font.bold: true
                    font.family: ThemeSystem.Theme.fontFamily
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    color: "#e4ebf4"
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 24
                    Layout.rightMargin: 24
                    Layout.topMargin: 18
                    spacing: 0

                    Repeater {
                        model: root.systemInfo.length > 0 ? root.systemInfo : root.placeholderSystemInfo()

                        delegate: RowLayout {
                            id: systemInfoRow

                            required property var modelData

                            Layout.fillWidth: true
                            spacing: 0

                            Rectangle {
                                Layout.preferredWidth: root.compact ? 150 : 180
                                Layout.preferredHeight: 32
                                color: "#f3f6fb"
                                border.width: 1
                                border.color: "#dfe7f1"

                                Text {
                                    anchors.left: parent.left
                                    anchors.leftMargin: 8
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: systemInfoRow.modelData.label
                                    color: ThemeSystem.Theme.textPrimary
                                    font.pixelSize: 12
                                    font.bold: true
                                    font.family: ThemeSystem.Theme.fontFamily
                                }
                            }

                            Rectangle {
                                Layout.fillWidth: true
                                Layout.preferredHeight: 32
                                color: "#ffffff"
                                border.width: 1
                                border.color: "#dfe7f1"

                                Item {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10

                                    Rectangle {
                                        visible: systemInfoRow.modelData.label === "运行状态"
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        radius: 8
                                        color: root.toneSoftColor(systemInfoRow.modelData.tone)
                                        implicitHeight: 24
                                        implicitWidth: stateValue.implicitWidth + 16

                                        Text {
                                            id: stateValue
                                            anchors.centerIn: parent
                                            text: systemInfoRow.modelData.value
                                            color: root.toneColor(systemInfoRow.modelData.tone)
                                            font.pixelSize: 11
                                            font.bold: true
                                            font.family: ThemeSystem.Theme.fontFamily
                                        }
                                    }

                                    Text {
                                        visible: systemInfoRow.modelData.label !== "运行状态"
                                        anchors.left: parent.left
                                        anchors.verticalCenter: parent.verticalCenter
                                        text: systemInfoRow.modelData.value
                                        color: ThemeSystem.Theme.textPrimary
                                        font.pixelSize: 12
                                        font.family: ThemeSystem.Theme.fontFamily
                                    }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 1
                    Layout.topMargin: 18
                    color: "#e4ebf4"
                }

                Text {
                    Layout.fillWidth: true
                    Layout.leftMargin: 24
                    Layout.rightMargin: 24
                    Layout.topMargin: 16
                    Layout.bottomMargin: 14
                    text: "机器人负载"
                    color: ThemeSystem.Theme.textPrimary
                    font.pixelSize: 18
                    font.bold: true
                    font.family: ThemeSystem.Theme.fontFamily
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.leftMargin: 24
                    Layout.rightMargin: 24
                    Layout.bottomMargin: 20
                    spacing: 12

                    Repeater {
                        model: root.botLoadRows.length > 0 ? root.botLoadRows : root.placeholderBotLoadRows()

                        delegate: ColumnLayout {
                            id: botLoadItem

                            required property var modelData

                            Layout.fillWidth: true
                            spacing: 6

                            RowLayout {
                                Layout.fillWidth: true

                                Text {
                                    text: botLoadItem.modelData.label
                                    color: ThemeSystem.Theme.textPrimary
                                    font.pixelSize: 12
                                    font.bold: true
                                    font.family: ThemeSystem.Theme.fontFamily
                                }

                                Item {
                                    Layout.fillWidth: true
                                }

                                Rectangle {
                                    radius: 8
                                    color: root.toneSoftColor(botLoadItem.modelData.tone)
                                    implicitHeight: 22
                                    implicitWidth: loadValue.implicitWidth + 16

                                    Text {
                                        id: loadValue
                                        anchors.centerIn: parent
                                        text: botLoadItem.modelData.value
                                        color: root.toneColor(botLoadItem.modelData.tone)
                                        font.pixelSize: 11
                                        font.bold: true
                                        font.family: ThemeSystem.Theme.fontFamily
                                    }
                                }
                            }

                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 8

                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.preferredHeight: 6
                                    radius: 3
                                    color: "#e8edf5"

                                    Rectangle {
                                        width: parent.width * Math.max(0, Math.min(1, (botLoadItem.modelData.percent || 0) / 100))
                                        height: parent.height
                                        radius: parent.radius
                                        color: root.toneColor(botLoadItem.modelData.tone)
                                    }
                                }

                                Text {
                                    text: Math.round(botLoadItem.modelData.percent || 0) + "%"
                                    color: ThemeSystem.Theme.textSecondary
                                    font.pixelSize: 12
                                    font.bold: true
                                    font.family: ThemeSystem.Theme.fontFamily
                                }
                            }
                        }
                    }

                    Item {
                        Layout.fillWidth: true
                        Layout.fillHeight: true
                    }
                }
            }
        }
    }
}
