import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme" as ThemeSystem
import "../components"

ResponsivePage {
    id: root

    horizontalPadding: 24
    verticalPadding: 22
    sectionSpacing: 0

    Component.onCompleted: {
        if (!downloadsViewModel.busy) {
            downloadsViewModel.refresh()
        }
    }

    property var sectionOptions: [
        { label: "服务端下载", value: "server" },
        { label: "服务端热队列", value: "queue" },
        { label: "本地下载", value: "local" }
    ]
    property var unifiedFilterOptions: [
        { label: "全部", value: "all" },
        { label: "进行中", value: "active" },
        { label: "等待中", value: "waiting" },
        { label: "失败", value: "failed" },
        { label: "已完成", value: "completed" }
    ]
    property string expandedGroupKey: ""
    property var detailFile: ({})
    property string detailGroupTitle: ""

    readonly property bool hasRows: downloadsViewModel.visibleTaskFlowModel.count > 0
    readonly property string emptyDescription: {
        switch (downloadsViewModel.taskSection) {
        case "queue":
            return "队列为空"
        case "local":
            return "暂无本地下载"
        default:
            return "暂无服务端任务"
        }
    }

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
            return "#eef3ff"
        default:
            return ThemeSystem.Theme.infoSoft
        }
    }

    function displayValue(value) {
        if (value === undefined || value === null) {
            return "-"
        }
        var text = String(value)
        return text.length > 0 ? text : "-"
    }

    function joinedDisplayValue(values) {
        if (!values || values.length === 0) {
            return "-"
        }
        var parts = []
        for (var i = 0; i < values.length; i++) {
            var text = displayValue(values[i])
            if (text.length > 0) {
                parts.push(text)
            }
        }
        return parts.length > 0 ? parts.join("\n") : "-"
    }

    function toggleGroup(groupKey) {
        expandedGroupKey = expandedGroupKey === groupKey ? "" : groupKey
    }

    function openFileDetail(fileItem, groupTitle) {
        detailFile = fileItem || ({})
        detailGroupTitle = groupTitle || ""
        fileDetailDialog.open()
    }

    Component {
        id: inlineMessageBanner

        Rectangle {
            property string message: ""
            property string tone: "info"

            Layout.fillWidth: true
            radius: 16
            color: root.toneSoftColor(tone)
            border.width: 1
            border.color: Qt.rgba(root.toneColor(tone).r, root.toneColor(tone).g, root.toneColor(tone).b, 0.18)
            implicitHeight: bannerText.implicitHeight + 22

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: 14
                anchors.rightMargin: 14
                anchors.topMargin: 11
                anchors.bottomMargin: 11
                spacing: 10

                Rectangle {
                    Layout.preferredWidth: 8
                    Layout.preferredHeight: 8
                    radius: 4
                    color: root.toneColor(tone)
                }

                Text {
                    id: bannerText
                    Layout.fillWidth: true
                    text: message
                    wrapMode: Text.WordWrap
                    color: ThemeSystem.Theme.textPrimary
                    font.pixelSize: 13
                    font.family: ThemeSystem.Theme.fontFamily
                }
            }
        }
    }

    Component {
        id: emptyStateBlock

        Rectangle {
            property string description: "当前没有匹配内容"

            Layout.fillWidth: true
            radius: 22
            color: "#f9fbfe"
            border.width: 1
            border.color: "#e7edf4"
            implicitHeight: emptyText.implicitHeight + 54

            Text {
                id: emptyText
                anchors.centerIn: parent
                width: Math.min(parent.width - 48, 420)
                text: description
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                color: ThemeSystem.Theme.textSecondary
                font.pixelSize: 14
                font.family: ThemeSystem.Theme.fontFamily
            }
        }
    }

    Component {
        id: unifiedTaskRow

        Rectangle {
            id: rowRoot

            required property string rowType
            required property string typeLabel
            required property string title
            required property string subtitle
            required property string statusLabel
            required property string statusTone
            required property real progressPercent
            required property string sizeText
            required property string metaPrimary
            required property string metaSecondary
            required property string error
            property string gid: ""
            property int uploadId: 0
            property string transferId: ""
            property string localPath: ""
            property bool canRetry: false
            property bool canDelete: false
            property bool canCancel: false
            property bool canOpen: false
            property bool canReveal: false

            Layout.fillWidth: true
            color: rowMouse.containsMouse ? "#fafcff" : "#ffffff"
            implicitHeight: rowLayout.implicitHeight + 26

            Rectangle {
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.bottom: parent.bottom
                height: 1
                color: "#edf1f6"
            }

            MouseArea {
                id: rowMouse
                anchors.fill: parent
                hoverEnabled: true
                acceptedButtons: Qt.NoButton
            }

            ColumnLayout {
                id: rowLayout
                anchors.fill: parent
                anchors.leftMargin: 16
                anchors.rightMargin: 16
                anchors.topMargin: 13
                anchors.bottomMargin: 13
                spacing: 10

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 6

                        RowLayout {
                            spacing: 8

                            Rectangle {
                                radius: 999
                                color: "#f4f7fb"
                                border.width: 1
                                border.color: "#e5ebf3"
                                implicitWidth: typeText.implicitWidth + 14
                                implicitHeight: 24

                                Text {
                                    id: typeText
                                    anchors.centerIn: parent
                                    text: typeLabel
                                    color: ThemeSystem.Theme.textSecondary
                                    font.pixelSize: 11
                                    font.bold: true
                                    font.family: ThemeSystem.Theme.fontFamily
                                }
                            }

                            Rectangle {
                                radius: 999
                                color: root.toneSoftColor(statusTone)
                                border.width: 1
                                border.color: Qt.rgba(root.toneColor(statusTone).r, root.toneColor(statusTone).g, root.toneColor(statusTone).b, 0.22)
                                implicitWidth: statusText.implicitWidth + 14
                                implicitHeight: 24

                                Text {
                                    id: statusText
                                    anchors.centerIn: parent
                                    text: statusLabel
                                    color: root.toneColor(statusTone)
                                    font.pixelSize: 11
                                    font.bold: true
                                    font.family: ThemeSystem.Theme.fontFamily
                                }
                            }
                        }

                        Text {
                            Layout.fillWidth: true
                            text: title
                            color: ThemeSystem.Theme.textPrimary
                            font.pixelSize: 15
                            font.bold: true
                            font.family: ThemeSystem.Theme.fontFamily
                            wrapMode: Text.WordWrap
                            elide: Text.ElideRight
                        }

                        Text {
                            Layout.fillWidth: true
                            visible: subtitle.length > 0
                            text: subtitle
                            color: ThemeSystem.Theme.textSecondary
                            font.pixelSize: 13
                            font.family: ThemeSystem.Theme.fontFamily
                            wrapMode: Text.WordWrap
                            elide: Text.ElideMiddle
                        }
                    }

                    Flow {
                        Layout.alignment: Qt.AlignTop | Qt.AlignRight
                        spacing: 8

                        GhostPillButton {
                            visible: rowType === "download" && canRetry
                            text: "重试"
                            tone: "primary"
                            onClicked: downloadsViewModel.retryServerDownload(gid)
                        }

                        GhostPillButton {
                            visible: rowType === "download" && canDelete
                            text: "删除"
                            tone: "danger"
                            onClicked: downloadsViewModel.deleteServerDownload(gid)
                        }

                        GhostPillButton {
                            visible: rowType === "upload" && canRetry
                            text: "重试"
                            tone: "primary"
                            onClicked: downloadsViewModel.retryUpload(uploadId)
                        }

                        GhostPillButton {
                            visible: rowType === "upload" && canDelete
                            text: "删除"
                            tone: "danger"
                            onClicked: downloadsViewModel.deleteUpload(uploadId)
                        }

                        GhostPillButton {
                            visible: rowType === "local" && canCancel
                            text: "取消"
                            tone: "warning"
                            onClicked: downloadsViewModel.cancelLocalDownload(transferId)
                        }

                        GhostPillButton {
                            visible: rowType === "local" && canRetry
                            text: "重试"
                            tone: "primary"
                            onClicked: downloadsViewModel.retryLocalDownload(transferId)
                        }

                        GhostPillButton {
                            visible: rowType === "local" && canOpen
                            text: "打开文件"
                            tone: "primary"
                            onClicked: downloadsViewModel.openLocalFile(localPath)
                        }

                        GhostPillButton {
                            visible: rowType === "local" && canReveal
                            text: "打开目录"
                            tone: "neutral"
                            onClicked: downloadsViewModel.showLocalFileInFolder(localPath)
                        }

                        GhostPillButton {
                            visible: rowType === "local" && canDelete
                            text: "删除"
                            tone: "danger"
                            onClicked: downloadsViewModel.removeLocalDownload(transferId)
                        }
                    }
                }

                ProgressBar {
                    Layout.fillWidth: true
                    visible: progressPercent > 0 && progressPercent < 100
                    from: 0
                    to: 100
                    value: progressPercent
                }

                Flow {
                    Layout.fillWidth: true
                    spacing: 8

                    Repeater {
                        model: [
                            sizeText,
                            metaPrimary,
                            metaSecondary
                        ]

                        delegate: Rectangle {
                            required property string modelData

                            visible: modelData.length > 0
                            radius: 999
                            color: "#f7f9fc"
                            border.width: 1
                            border.color: "#ebeff4"
                            implicitWidth: chipLabel.implicitWidth + 16
                            implicitHeight: 26

                            Text {
                                id: chipLabel
                                anchors.centerIn: parent
                                text: modelData
                                color: ThemeSystem.Theme.textSecondary
                                font.pixelSize: 11
                                font.family: ThemeSystem.Theme.fontFamily
                            }
                        }
                    }
                }

                Text {
                    visible: error.length > 0
                    Layout.fillWidth: true
                    text: error
                    color: ThemeSystem.Theme.colorDanger
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                    font.family: ThemeSystem.Theme.fontFamily
                }
            }
        }
    }

    Component {
        id: groupRecordRow

        Rectangle {
            id: groupCard

            required property string groupKey
            required property string title
            required property string captionText
            required property string messageId
            required property string groupType
            required property string groupTypeLabel
            required property string statusLabel
            required property string statusTone
            required property string fileCountLabel
            required property string completedLabel
            required property string downloadingLabel
            required property string skippedLabel
            required property string failedLabel
            required property bool hasDownloading
            required property bool hasSkipped
            required property bool hasFailed
            required property string createdAtText
            required property string sizeText
            required property real progressPercent
            required property var files

            readonly property bool expanded: root.expandedGroupKey === groupKey
            readonly property bool hasCaption: captionText.length > 0

            Layout.fillWidth: true
            radius: 16
            color: "#ffffff"
            border.width: 1
            border.color: expanded ? "#d8e5fb" : "#e8eef5"
            implicitHeight: groupLayout.implicitHeight + 2

            ColumnLayout {
                id: groupLayout
                anchors.fill: parent
                spacing: 0

                Rectangle {
                    Layout.fillWidth: true
                    color: headerMouse.containsMouse ? "#fbfdff" : "#ffffff"
                    radius: groupCard.radius
                    implicitHeight: headerLayout.implicitHeight + 28

                    MouseArea {
                        id: headerMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        onClicked: root.toggleGroup(groupKey)
                    }

                    RowLayout {
                        id: headerLayout
                        anchors.fill: parent
                        anchors.leftMargin: 18
                        anchors.rightMargin: 18
                        anchors.topMargin: 14
                        anchors.bottomMargin: 14
                        spacing: 14

                        Item {
                            Layout.preferredWidth: 34
                            Layout.preferredHeight: 34
                            Layout.alignment: Qt.AlignTop

                            Rectangle {
                                x: 5
                                y: 13
                                width: 24
                                height: 15
                                radius: 4
                                color: "transparent"
                                border.width: 1
                                border.color: "#5c7cff"
                            }

                            Rectangle {
                                x: 8
                                y: 8
                                width: 13
                                height: 6
                                radius: 2
                                color: "#ffffff"
                                border.width: 1
                                border.color: "#5c7cff"
                            }
                        }

                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 8

                            Text {
                                Layout.fillWidth: true
                                text: hasCaption ? title : groupTypeLabel
                                color: ThemeSystem.Theme.textPrimary
                                font.pixelSize: 15
                                font.bold: true
                                font.family: ThemeSystem.Theme.fontFamily
                                elide: Text.ElideRight
                                maximumLineCount: 1
                            }

                            Flow {
                                Layout.fillWidth: true
                                spacing: 8

                                Rectangle {
                                    visible: hasCaption
                                    radius: 999
                                    color: "#f4f7fb"
                                    border.width: 1
                                    border.color: "#e5ebf3"
                                    implicitWidth: groupTypeText.implicitWidth + 14
                                    implicitHeight: 24

                                    Text {
                                        id: groupTypeText
                                        anchors.centerIn: parent
                                        text: groupTypeLabel
                                        color: ThemeSystem.Theme.textSecondary
                                        font.pixelSize: 11
                                        font.bold: true
                                        font.family: ThemeSystem.Theme.fontFamily
                                    }
                                }

                                Rectangle {
                                    radius: 999
                                    color: root.toneSoftColor(statusTone)
                                    border.width: 1
                                    border.color: Qt.rgba(root.toneColor(statusTone).r, root.toneColor(statusTone).g, root.toneColor(statusTone).b, 0.22)
                                    implicitWidth: groupStatusText.implicitWidth + 14
                                    implicitHeight: 24

                                    Text {
                                        id: groupStatusText
                                        anchors.centerIn: parent
                                        text: statusLabel
                                        color: root.toneColor(statusTone)
                                        font.pixelSize: 11
                                        font.bold: true
                                        font.family: ThemeSystem.Theme.fontFamily
                                    }
                                }

                                Repeater {
                                    model: [
                                        fileCountLabel,
                                        completedLabel,
                                        hasDownloading ? downloadingLabel : "",
                                        hasSkipped ? skippedLabel : "",
                                        hasFailed ? failedLabel : "",
                                        createdAtText
                                    ]

                                    delegate: Rectangle {
                                        required property string modelData

                                        visible: modelData.length > 0
                                        radius: 999
                                        color: "#f7f9fc"
                                        border.width: 1
                                        border.color: "#ebeff4"
                                        implicitWidth: chipLabel.implicitWidth + 14
                                        implicitHeight: 24

                                        Text {
                                            id: chipLabel
                                            anchors.centerIn: parent
                                            text: modelData
                                            color: ThemeSystem.Theme.textSecondary
                                            font.pixelSize: 11
                                            font.family: ThemeSystem.Theme.fontFamily
                                        }
                                    }
                                }
                            }
                        }

                        ColumnLayout {
                            spacing: 8
                            Layout.alignment: Qt.AlignTop

                            ProgressBar {
                                Layout.preferredWidth: root.compact ? 120 : 160
                                from: 0
                                to: 100
                                value: progressPercent
                            }

                            RowLayout {
                                Layout.alignment: Qt.AlignRight
                                spacing: 8

                                Text {
                                    text: sizeText
                                    color: ThemeSystem.Theme.textPrimary
                                    font.pixelSize: 13
                                    font.bold: true
                                    font.family: ThemeSystem.Theme.fontFamily
                                }

                                Text {
                                    text: expanded ? "v" : ">"
                                    color: ThemeSystem.Theme.textSecondary
                                    font.pixelSize: 14
                                    font.bold: true
                                    font.family: ThemeSystem.Theme.fontFamily
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    visible: expanded
                    Layout.fillWidth: true
                    height: 1
                    color: "#edf1f6"
                }

                ColumnLayout {
                    visible: expanded
                    Layout.fillWidth: true
                    spacing: 0

                    Rectangle {
                        Layout.fillWidth: true
                        color: "#fbfcfe"
                        implicitHeight: tableHeader.implicitHeight + 18

                        RowLayout {
                            id: tableHeader
                            anchors.fill: parent
                            anchors.leftMargin: 20
                            anchors.rightMargin: 20
                            anchors.topMargin: 9
                            anchors.bottomMargin: 9
                            spacing: 16

                            Text {
                                Layout.fillWidth: true
                                Layout.minimumWidth: 240
                                text: "文件名"
                                color: ThemeSystem.Theme.textSecondary
                                font.pixelSize: 12
                                font.bold: true
                                font.family: ThemeSystem.Theme.fontFamily
                            }

                            Text {
                                Layout.preferredWidth: 110
                                text: "大小"
                                color: ThemeSystem.Theme.textSecondary
                                font.pixelSize: 12
                                font.bold: true
                                font.family: ThemeSystem.Theme.fontFamily
                            }

                            Text {
                                Layout.preferredWidth: 110
                                text: "状态"
                                color: ThemeSystem.Theme.textSecondary
                                font.pixelSize: 12
                                font.bold: true
                                font.family: ThemeSystem.Theme.fontFamily
                            }

                            Text {
                                Layout.preferredWidth: root.compact ? 180 : 260
                                text: "远程路径"
                                color: ThemeSystem.Theme.textSecondary
                                font.pixelSize: 12
                                font.bold: true
                                font.family: ThemeSystem.Theme.fontFamily
                            }

                            Text {
                                Layout.preferredWidth: 156
                                text: "创建时间"
                                color: ThemeSystem.Theme.textSecondary
                                font.pixelSize: 12
                                font.bold: true
                                font.family: ThemeSystem.Theme.fontFamily
                            }

                            Text {
                                Layout.preferredWidth: 170
                                horizontalAlignment: Text.AlignRight
                                text: "操作"
                                color: ThemeSystem.Theme.textSecondary
                                font.pixelSize: 12
                                font.bold: true
                                font.family: ThemeSystem.Theme.fontFamily
                            }
                        }
                    }

                    Repeater {
                        model: files

                        delegate: Rectangle {
                            required property var modelData
                            property var fileItem: modelData

                            Layout.fillWidth: true
                            color: rowMouse.containsMouse ? "#fafcff" : "#ffffff"
                            implicitHeight: fileRow.implicitHeight + 18

                            Rectangle {
                                anchors.left: parent.left
                                anchors.right: parent.right
                                anchors.bottom: parent.bottom
                                height: 1
                                color: "#edf1f6"
                            }

                            MouseArea {
                                id: rowMouse
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: root.openFileDetail(fileItem, title)
                            }

                            RowLayout {
                                id: fileRow
                                anchors.fill: parent
                                anchors.leftMargin: 20
                                anchors.rightMargin: 20
                                anchors.topMargin: 9
                                anchors.bottomMargin: 9
                                spacing: 16

                                RowLayout {
                                    Layout.fillWidth: true
                                    Layout.minimumWidth: 240
                                    spacing: 8

                                    Rectangle {
                                        width: 26
                                        height: 26
                                        radius: 13
                                        color: "#f4f7fb"
                                        border.width: 1
                                        border.color: "#e5ebf3"

                                        Text {
                                            anchors.centerIn: parent
                                            text: "\u25a3"
                                            color: ThemeSystem.Theme.textSecondary
                                            font.pixelSize: 12
                                            font.family: ThemeSystem.Theme.fontFamily
                                        }
                                    }

                                    Text {
                                        Layout.fillWidth: true
                                        text: root.displayValue(fileItem.fileName)
                                        color: ThemeSystem.Theme.textPrimary
                                        font.pixelSize: 13
                                        font.family: ThemeSystem.Theme.fontFamily
                                        wrapMode: Text.NoWrap
                                        elide: Text.ElideRight
                                        maximumLineCount: 1
                                    }
                                }

                                Text {
                                    Layout.preferredWidth: 110
                                    text: root.displayValue(fileItem.fileSizeText)
                                    color: ThemeSystem.Theme.textPrimary
                                    font.pixelSize: 13
                                    font.family: ThemeSystem.Theme.fontFamily
                                }

                                Rectangle {
                                    Layout.preferredWidth: 110
                                    Layout.preferredHeight: 26
                                    radius: 999
                                    color: root.toneSoftColor(fileItem.statusTone)
                                    border.width: 1
                                    border.color: Qt.rgba(root.toneColor(fileItem.statusTone).r, root.toneColor(fileItem.statusTone).g, root.toneColor(fileItem.statusTone).b, 0.22)

                                    Text {
                                        anchors.centerIn: parent
                                        text: root.displayValue(fileItem.statusLabel)
                                        color: root.toneColor(fileItem.statusTone)
                                        font.pixelSize: 11
                                        font.bold: true
                                        font.family: ThemeSystem.Theme.fontFamily
                                    }
                                }

                                Text {
                                    Layout.preferredWidth: root.compact ? 180 : 260
                                    text: root.joinedDisplayValue(fileItem.remotePathEntries && fileItem.remotePathEntries.length > 0 ? fileItem.remotePathEntries : [fileItem.remotePath])
                                    color: text !== "-" ? "#1c8b56" : ThemeSystem.Theme.textSecondary
                                    font.pixelSize: 12
                                    font.family: ThemeSystem.Theme.fontFamily
                                    wrapMode: Text.WrapAnywhere
                                    elide: Text.ElideMiddle
                                    maximumLineCount: 3
                                }

                                Text {
                                    Layout.preferredWidth: 156
                                    text: root.displayValue(fileItem.createdAtText)
                                    color: ThemeSystem.Theme.textPrimary
                                    font.pixelSize: 12
                                    font.family: ThemeSystem.Theme.fontFamily
                                }

                                Item {
                                    Layout.preferredWidth: 170
                                    Layout.preferredHeight: actionsRow.implicitHeight

                                    MouseArea {
                                        anchors.fill: parent
                                        acceptedButtons: Qt.LeftButton
                                        onClicked: mouse.accepted = true
                                    }

                                    RowLayout {
                                        id: actionsRow
                                        anchors.right: parent.right
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 8

                                        GhostPillButton {
                                            text: "详情"
                                            tone: "neutral"
                                            onClicked: root.openFileDetail(fileItem, title)
                                        }

                                        GhostPillButton {
                                            visible: Boolean(fileItem.canRetry)
                                            text: "重试"
                                            tone: "primary"
                                            onClicked: downloadsViewModel.retryServerDownload(fileItem.gid)
                                        }

                                        GhostPillButton {
                                            visible: Boolean(fileItem.canDelete)
                                            text: "删除"
                                            tone: "danger"
                                            onClicked: downloadsViewModel.deleteServerDownload(fileItem.gid)
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Popup {
        id: fileDetailDialog

        parent: Overlay.overlay
        modal: true
        focus: true
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        padding: 0
        width: Math.max(680, Math.min(920, root.width - 40))
        height: Math.max(520, Math.min(720, root.height - 40))
        anchors.centerIn: Overlay.overlay

        Overlay.modal: Rectangle {
            color: "#55000000"
        }

        background: Rectangle {
            radius: 16
            color: "#ffffff"
            border.width: 1
            border.color: "#e3eaf3"
        }

        ColumnLayout {
            anchors.fill: parent
            spacing: 0

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: 74
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#6275ea" }
                    GradientStop { position: 1.0; color: "#4f8fd7" }
                }

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 22
                    anchors.rightMargin: 18
                    spacing: 12

                    Text {
                        Layout.fillWidth: true
                        text: "文件详情"
                        color: "#ffffff"
                        font.pixelSize: 18
                        font.bold: true
                        font.family: ThemeSystem.Theme.fontFamily
                    }

                    Button {
                        text: "x"
                        onClicked: fileDetailDialog.close()

                        background: Rectangle {
                            radius: width / 2
                            color: parent.down ? "#33ffffff" : (parent.hovered ? "#22ffffff" : "transparent")
                        }

                        contentItem: Text {
                            text: parent.text
                            color: "#ffffff"
                            font.pixelSize: 18
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                            font.family: ThemeSystem.Theme.fontFamily
                        }
                    }
                }
            }

            ScrollView {
                Layout.fillWidth: true
                Layout.fillHeight: true
                clip: true

                ColumnLayout {
                    width: fileDetailDialog.availableWidth
                    spacing: 0

                    Repeater {
                        model: [
                            { label: "文件名", value: root.displayValue(root.detailFile.fileName), link: "" },
                            { label: "文件大小", value: root.displayValue(root.detailFile.fileSizeText), link: "" },
                            { label: "文件类型", value: root.displayValue(root.detailFile.fileType), link: "" },
                            { label: "下载状态", value: root.displayValue(root.detailFile.statusLabel), link: "" },
                            { label: "远程路径", value: root.joinedDisplayValue(root.detailFile.remotePathEntries && root.detailFile.remotePathEntries.length > 0 ? root.detailFile.remotePathEntries : [root.detailFile.remotePath]), link: "" },
                            { label: "上传状态", value: "", link: "", uploads: root.detailFile.uploadItems || [] },
                            { label: "源 TG URL", value: root.displayValue(root.detailFile.sourceTgUrl), link: root.detailFile.sourceTgUrl || "" },
                            { label: "源 URL", value: root.displayValue(root.detailFile.sourceUrl), link: root.detailFile.sourceUrl || "" },
                            { label: "说明文本", value: root.displayValue(root.detailFile.captionText), link: "" },
                            { label: "创建时间", value: root.displayValue(root.detailFile.createdAtText), link: "" },
                            { label: "开始时间", value: root.displayValue(root.detailFile.startedAtText), link: "" },
                            { label: "完成时间", value: root.displayValue(root.detailFile.completedAtText), link: "" },
                            { label: "更新时间", value: root.displayValue(root.detailFile.updatedAtText), link: "" }
                        ]

                        delegate: Rectangle {
                            required property var modelData
                            required property int index

                            Layout.fillWidth: true
                            color: index % 2 === 0 ? "#ffffff" : "#fbfcfe"
                            border.width: 1
                            border.color: "#edf1f6"
                            implicitHeight: rowLayout.implicitHeight + 18

                            RowLayout {
                                id: rowLayout
                                anchors.fill: parent
                                anchors.leftMargin: 18
                                anchors.rightMargin: 18
                                anchors.topMargin: 9
                                anchors.bottomMargin: 9
                                spacing: 0

                                Rectangle {
                                    Layout.preferredWidth: 132
                                    Layout.fillHeight: true
                                    color: "transparent"

                                    Text {
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.leftMargin: 10
                                        text: modelData.label
                                        color: ThemeSystem.Theme.textPrimary
                                        font.pixelSize: 13
                                        font.bold: true
                                        font.family: ThemeSystem.Theme.fontFamily
                                    }
                                }

                                Item {
                                    Layout.fillWidth: true
                                    Layout.fillHeight: true

                                    Text {
                                        visible: !modelData.link && !modelData.uploads
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.leftMargin: 12
                                        anchors.right: parent.right
                                        anchors.rightMargin: 10
                                        text: modelData.value
                                        color: ThemeSystem.Theme.textSecondary
                                        font.pixelSize: 13
                                        font.family: ThemeSystem.Theme.fontFamily
                                        wrapMode: Text.WrapAnywhere
                                    }

                                    Text {
                                        visible: Boolean(modelData.link)
                                        anchors.verticalCenter: parent.verticalCenter
                                        anchors.left: parent.left
                                        anchors.leftMargin: 12
                                        anchors.right: parent.right
                                        anchors.rightMargin: 10
                                        text: modelData.value
                                        color: ThemeSystem.Theme.colorPrimary
                                        font.pixelSize: 13
                                        font.family: ThemeSystem.Theme.fontFamily
                                        wrapMode: Text.WrapAnywhere

                                        MouseArea {
                                            anchors.fill: parent
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: Qt.openUrlExternally(modelData.link)
                                        }
                                    }

                                    ColumnLayout {
                                        visible: Boolean(modelData.uploads)
                                        anchors.left: parent.left
                                        anchors.leftMargin: 12
                                        anchors.right: parent.right
                                        anchors.rightMargin: 10
                                        anchors.verticalCenter: parent.verticalCenter
                                        spacing: 8

                                        Text {
                                            visible: (modelData.uploads || []).length === 0
                                            Layout.fillWidth: true
                                            text: "-"
                                            color: ThemeSystem.Theme.textSecondary
                                            font.pixelSize: 13
                                            font.family: ThemeSystem.Theme.fontFamily
                                        }

                                        Repeater {
                                            model: modelData.uploads || []

                                            delegate: ColumnLayout {
                                                required property var modelData

                                                Layout.fillWidth: true
                                                spacing: 4

                                                RowLayout {
                                                    Layout.fillWidth: true
                                                    spacing: 8

                                                    Rectangle {
                                                        radius: 999
                                                        color: "#eef3ff"
                                                        border.width: 1
                                                        border.color: "#c8d8ff"
                                                        implicitWidth: uploadTargetText.implicitWidth + 14
                                                        implicitHeight: 24

                                                        Text {
                                                            id: uploadTargetText
                                                            anchors.centerIn: parent
                                                            text: root.displayValue(modelData.targetLabel)
                                                            color: ThemeSystem.Theme.colorPrimary
                                                            font.pixelSize: 11
                                                            font.bold: true
                                                            font.family: ThemeSystem.Theme.fontFamily
                                                        }
                                                    }

                                                    Rectangle {
                                                        radius: 999
                                                        color: root.toneSoftColor(modelData.statusTone)
                                                        border.width: 1
                                                        border.color: Qt.rgba(root.toneColor(modelData.statusTone).r, root.toneColor(modelData.statusTone).g, root.toneColor(modelData.statusTone).b, 0.22)
                                                        implicitWidth: uploadStatusText.implicitWidth + 14
                                                        implicitHeight: 24

                                                        Text {
                                                            id: uploadStatusText
                                                            anchors.centerIn: parent
                                                            text: root.displayValue(modelData.statusLabel)
                                                            color: root.toneColor(modelData.statusTone)
                                                            font.pixelSize: 11
                                                            font.bold: true
                                                            font.family: ThemeSystem.Theme.fontFamily
                                                        }
                                                    }

                                                    Text {
                                                        visible: modelData.completedAtText.length > 0
                                                        Layout.fillWidth: true
                                                        text: "完成: " + modelData.completedAtText
                                                        color: ThemeSystem.Theme.textTertiary
                                                        font.pixelSize: 12
                                                        font.family: ThemeSystem.Theme.fontFamily
                                                        elide: Text.ElideRight
                                                    }
                                                }

                                                Text {
                                                    visible: modelData.error.length > 0
                                                    Layout.fillWidth: true
                                                    text: "错误: " + modelData.error
                                                    color: ThemeSystem.Theme.colorDanger
                                                    font.pixelSize: 12
                                                    font.family: ThemeSystem.Theme.fontFamily
                                                    wrapMode: Text.WrapAnywhere
                                                }
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillWidth: true
                implicitHeight: footerLayout.implicitHeight + 26
                color: "#ffffff"
                border.width: 1
                border.color: "#edf1f6"

                RowLayout {
                    id: footerLayout
                    anchors.fill: parent
                    anchors.leftMargin: 18
                    anchors.rightMargin: 18
                    anchors.topMargin: 13
                    anchors.bottomMargin: 13
                    spacing: 10

                    Text {
                        Layout.fillWidth: true
                        text: detailGroupTitle.length > 0 ? detailGroupTitle : ""
                        color: ThemeSystem.Theme.textTertiary
                        font.pixelSize: 12
                        font.family: ThemeSystem.Theme.fontFamily
                        elide: Text.ElideRight
                    }

                    PrimaryButton {
                        text: "关闭"
                        onClicked: fileDetailDialog.close()
                    }
                }
            }
        }
    }

    GlassCard {
        Layout.fillWidth: true
        backgroundColor: "#ffffff"
        borderColor: "#e4ebf3"
        shadowOpacity: 0.06
        shadowOffsetY: 18
        shadowSpread: 28
        implicitHeight: shellContent.implicitHeight + padding * 2

        ColumnLayout {
            id: shellContent
            anchors.fill: parent
            spacing: 14

            Rectangle {
                Layout.fillWidth: true
                radius: 20
                color: "#f8fbfe"
                border.width: 1
                border.color: "#e8eef5"
                implicitHeight: toolbarLayout.implicitHeight + 28

                ColumnLayout {
                    id: toolbarLayout
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 12

                    TaskSegmentedControl {
                        Layout.fillWidth: true
                        options: root.sectionOptions
                        currentValue: downloadsViewModel.taskSection
                        onValueSelected: downloadsViewModel.setTaskSection(value)
                    }

                    GridLayout {
                        Layout.fillWidth: true
                        columns: root.compact ? 1 : 3
                        columnSpacing: 12
                        rowSpacing: 12

                        AppTextField {
                            Layout.fillWidth: true
                            text: downloadsViewModel.unifiedKeyword
                            placeholderText: "搜索任务、文件名、状态或路径"
                            onTextEdited: downloadsViewModel.setUnifiedKeyword(text)
                        }

                        TaskSegmentedControl {
                            Layout.fillWidth: true
                            options: root.unifiedFilterOptions
                            currentValue: downloadsViewModel.unifiedStatusFilter
                            onValueSelected: downloadsViewModel.setUnifiedStatusFilter(value)
                        }

                        PrimaryButton {
                            Layout.fillWidth: root.compact
                            Layout.alignment: root.compact ? Qt.AlignLeft : Qt.AlignRight
                            text: downloadsViewModel.busy ? "刷新中..." : "刷新"
                            enabled: !downloadsViewModel.busy
                            onClicked: downloadsViewModel.refresh()
                        }
                    }
                }
            }

            Loader {
                active: downloadsViewModel.infoMessage.length > 0
                sourceComponent: inlineMessageBanner

                onLoaded: {
                    item.message = Qt.binding(function() {
                        return downloadsViewModel.infoMessage
                    })
                    item.tone = "success"
                }
            }

            Loader {
                active: downloadsViewModel.errorMessage.length > 0
                sourceComponent: inlineMessageBanner

                onLoaded: {
                    item.message = Qt.binding(function() {
                        return downloadsViewModel.errorMessage
                    })
                    item.tone = "danger"
                }
            }

            Loader {
                active: downloadsViewModel.taskSection === "queue"
                        && downloadsViewModel.queueFloodWaitText.length > 0
                sourceComponent: inlineMessageBanner

                onLoaded: {
                    item.message = Qt.binding(function() {
                        return downloadsViewModel.queueFloodWaitText
                    })
                    item.tone = "warning"
                }
            }

            Rectangle {
                Layout.fillWidth: true
                radius: 22
                color: "#ffffff"
                border.width: 1
                border.color: "#edf1f6"
                implicitHeight: contentLayout.implicitHeight + 8

                ColumnLayout {
                    id: contentLayout
                    anchors.fill: parent
                    anchors.topMargin: 4
                    anchors.bottomMargin: 4
                    spacing: 0

                    Repeater {
                        model: downloadsViewModel.visibleTaskFlowModel

                        delegate: Item {
                            id: taskFlowDelegate

                            required property string rowType
                            required property string typeLabel
                            required property string title
                            required property string subtitle
                            required property string statusLabel
                            required property string statusTone
                            required property real progressPercent
                            required property string sizeText
                            required property string metaPrimary
                            required property string metaSecondary
                            required property string error
                            property string gid: ""
                            property int uploadId: 0
                            property string transferId: ""
                            property string localPath: ""
                            property bool canRetry: false
                            property bool canDelete: false
                            property bool canCancel: false
                            property bool canOpen: false
                            property bool canReveal: false
                            property string groupKey: ""
                            property string captionText: ""
                            property string messageId: ""
                            property string groupType: ""
                            property string groupTypeLabel: ""
                            property string fileCountLabel: ""
                            property string completedLabel: ""
                            property string downloadingLabel: ""
                            property string skippedLabel: ""
                            property string failedLabel: ""
                            property bool hasDownloading: false
                            property bool hasSkipped: false
                            property bool hasFailed: false
                            property string createdAtText: ""
                            property var files: []
                            property Item currentItem: null

                            Layout.fillWidth: true
                            implicitHeight: currentItem ? currentItem.implicitHeight : 0

                            Item {
                                id: delegateHost
                                anchors.fill: parent
                            }

                            function createDelegate() {
                                var component = rowType === "group" ? groupRecordRow : unifiedTaskRow
                                var props

                                if (currentItem) {
                                    currentItem.destroy()
                                    currentItem = null
                                }

                                if (rowType === "group") {
                                    props = {
                                        groupKey: groupKey,
                                        title: title,
                                        captionText: captionText,
                                        messageId: messageId,
                                        groupType: groupType,
                                        groupTypeLabel: groupTypeLabel,
                                        statusLabel: statusLabel,
                                        statusTone: statusTone,
                                        fileCountLabel: fileCountLabel,
                                        completedLabel: completedLabel,
                                        downloadingLabel: downloadingLabel,
                                        skippedLabel: skippedLabel,
                                        failedLabel: failedLabel,
                                        hasDownloading: hasDownloading,
                                        hasSkipped: hasSkipped,
                                        hasFailed: hasFailed,
                                        createdAtText: createdAtText,
                                        sizeText: sizeText,
                                        progressPercent: progressPercent,
                                        files: files
                                    }
                                } else {
                                    props = {
                                        rowType: rowType,
                                        typeLabel: typeLabel,
                                        title: title,
                                        subtitle: subtitle,
                                        statusLabel: statusLabel,
                                        statusTone: statusTone,
                                        progressPercent: progressPercent,
                                        sizeText: sizeText,
                                        metaPrimary: metaPrimary,
                                        metaSecondary: metaSecondary,
                                        error: error,
                                        gid: gid,
                                        uploadId: uploadId,
                                        transferId: transferId,
                                        localPath: localPath,
                                        canRetry: canRetry,
                                        canDelete: canDelete,
                                        canCancel: canCancel,
                                        canOpen: canOpen,
                                        canReveal: canReveal
                                    }
                                }

                                currentItem = component.createObject(delegateHost, props)
                                if (currentItem) {
                                    currentItem.width = taskFlowDelegate.width
                                }
                            }

                            Component.onCompleted: createDelegate()

                            onWidthChanged: {
                                if (currentItem) {
                                    currentItem.width = width
                                }
                            }
                        }
                    }

                    Loader {
                        active: !root.hasRows
                        Layout.fillWidth: true
                        sourceComponent: emptyStateBlock

                        onLoaded: {
                            item.description = root.emptyDescription
                        }
                    }
                }
            }
        }
    }
}
