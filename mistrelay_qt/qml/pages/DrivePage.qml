import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import QtMultimedia
import "../theme" as ThemeSystem
import "../components"

ResponsivePage {
    id: root

    horizontalPadding: 24
    verticalPadding: 22
    sectionSpacing: 16

    readonly property bool showWideDetail: driveViewModel.detailPanelVisible && contentFrameWidth >= 1380

    property var sectionOptions: [
        { key: "all", label: "全部" },
        { key: "videos", label: "视频" },
        { key: "images", label: "图片" },
        { key: "documents", label: "文档" },
        { key: "flows", label: "全部流" },
        { key: "recent", label: "最近" }
    ]
    property var sortOptions: [
        { value: "time_desc", label: "时间（新到旧）" },
        { value: "time_asc", label: "时间（旧到新）" },
        { value: "size_desc", label: "体积（大到小）" },
        { value: "name_asc", label: "名称（A-Z）" }
    ]
    property var pageSizeOptions: [10, 30, 60, 100, 200]

    property string contextPath: ""
    property bool contextIsDir: false
    property bool contextCanPreview: false
    property bool contextCanDownload: false
    property bool contextCanDelete: false
    property var contextMenuActions: [
        { key: "open" },
        { key: "preview" },
        { key: "download" },
        { key: "delete" },
        { key: "clearSelection", separatorBefore: true }
    ]

    Component.onCompleted: {
        if (!driveViewModel.busy && driveViewModel.itemsModel.count === 0) {
            driveViewModel.refresh()
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

    function countFor(key) {
        switch (key) {
        case "all":
            return root.summaryValue("totalCount")
        case "videos":
            return root.summaryValue("videos")
        case "images":
            return root.summaryValue("images")
        case "documents":
            return root.summaryValue("documents")
        default:
            return -1
        }
    }

    function sectionChipText(key, label) {
        var count = root.countFor(key)
        return count >= 0 ? label + " " + count : label
    }

    function summaryValue(key) {
        var stats = driveViewModel.channelStats || {}
        return stats[key] !== undefined ? stats[key] : 0
    }

    function prepareContext(path, isDir, canPreview, canDownload, canDelete) {
        if (driveViewModel.selectedPaths.indexOf(path) < 0) {
            driveViewModel.selectItem(path)
        }
        contextPath = path
        contextIsDir = isDir
        contextCanPreview = canPreview
        contextCanDownload = canDownload
        contextCanDelete = canDelete
    }

    function openContextMenu(path, isDir, canPreview, canDownload, canDelete, x, y, sourceItem) {
        prepareContext(path, isDir, canPreview, canDownload, canDelete)
        var overlay = Overlay.overlay || root
        var point = sourceItem.mapToItem(overlay, x, y)
        var desiredX = point.x + 8
        var desiredY = point.y + 8
        var menuWidth = contextMenuPopup.width > 0 ? contextMenuPopup.width : contextMenuPopup.implicitWidth
        var menuHeight = contextMenuPopup.implicitHeight > 0
                         ? contextMenuPopup.implicitHeight
                         : (contextMenuPopup.contentItem
                            ? contextMenuPopup.contentItem.implicitHeight + contextMenuPopup.topPadding + contextMenuPopup.bottomPadding
                            : 220)
        var menuMargin = 12
        var maxX = Math.max(menuMargin, overlay.width - menuWidth - menuMargin)
        var maxY = Math.max(menuMargin, overlay.height - menuHeight - menuMargin)

        if (contextMenuPopup.opened) {
            contextMenuPopup.close()
        }

        contextMenuPopup.x = Math.max(menuMargin, Math.min(maxX, desiredX))
        contextMenuPopup.y = Math.max(menuMargin, Math.min(maxY, desiredY))
        contextMenuPopup.open()
    }

    function itemSubtitle(item) {
        if (!item) {
            return ""
        }
        if (item.subtitle && item.subtitle.length > 0) {
            return item.subtitle
        }
        return item.kindLabel || ""
    }

    function listSingleLineText(value, fallback) {
        var text = value && value.length > 0 ? value : (fallback || "")
        return text.replace(/[\r\n\t]+/g, " ").replace(/\s+/g, " ").trim()
    }

    function contextMenuActionText(actionKey) {
        switch (actionKey) {
        case "open":
            return root.contextIsDir ? "打开媒体组" : "打开"
        case "preview":
            return "预览"
        case "download":
            return root.contextIsDir ? "下载整组" : "下载"
        case "delete":
            return root.contextIsDir ? "删除媒体组" : "删除"
        case "clearSelection":
            return "清除选择"
        default:
            return ""
        }
    }

    function contextMenuActionIcon(actionKey) {
        switch (actionKey) {
        case "open":
            return "open"
        case "preview":
            return "eye"
        case "download":
            return "download"
        case "delete":
            return "trash"
        case "clearSelection":
            return "clear"
        default:
            return "open"
        }
    }

    function contextMenuActionTone(actionKey) {
        switch (actionKey) {
        case "open":
        case "preview":
            return "primary"
        case "delete":
            return "danger"
        default:
            return "neutral"
        }
    }

    function contextMenuActionEnabled(actionKey) {
        switch (actionKey) {
        case "preview":
            return root.contextCanPreview
        case "download":
            return root.contextCanDownload
        case "delete":
            return root.contextCanDelete
        case "clearSelection":
            return driveViewModel.hasSelection
        default:
            return root.contextPath.length > 0
        }
    }

    function contextMenuActionColor(actionKey, enabled) {
        if (!enabled) {
            return ThemeSystem.Theme.textTertiary
        }
        switch (root.contextMenuActionTone(actionKey)) {
        case "primary":
            return ThemeSystem.Theme.colorPrimary
        case "danger":
            return ThemeSystem.Theme.colorDanger
        default:
            return ThemeSystem.Theme.textPrimary
        }
    }

    function contextMenuActionBackground(actionKey, hovered, pressed, enabled) {
        if (!enabled) {
            return "transparent"
        }
        if (root.contextMenuActionTone(actionKey) === "danger") {
            return pressed ? "#f7d6db" : (hovered ? ThemeSystem.Theme.dangerSoft : "transparent")
        }
        return pressed ? "#dcecff" : (hovered ? ThemeSystem.Theme.infoSoft : "transparent")
    }

    function contextMenuActionBorder(actionKey, hovered, pressed, enabled) {
        if (!enabled || (!hovered && !pressed)) {
            return "transparent"
        }
        if (root.contextMenuActionTone(actionKey) === "danger") {
            return "#efc0c7"
        }
        return "#cfe0f5"
    }

    function triggerContextMenuAction(actionKey) {
        contextMenuPopup.close()
        switch (actionKey) {
        case "open":
            driveViewModel.activateItem(root.contextPath)
            break
        case "preview":
            driveViewModel.openPreview(root.contextPath)
            break
        case "download":
            driveViewModel.downloadItem(root.contextPath)
            break
        case "delete":
            driveViewModel.deleteItem(root.contextPath)
            break
        case "clearSelection":
            driveViewModel.clearSelection()
            break
        default:
            break
        }
    }

    Component {
        id: previewPlayerComponent

        MediaPlayer {
            autoPlay: true
            audioOutput: AudioOutput { }
            videoOutput: detailVideoOutput
            source: driveViewModel.previewState.source
        }
    }

    Loader {
        visible: false
        active: driveViewModel.previewState.mode === "video" && driveViewModel.previewState.source.length > 0
        sourceComponent: previewPlayerComponent
    }

    Popup {
        id: contextMenuPopup

        parent: Overlay.overlay ? Overlay.overlay : root
        width: 206
        modal: false
        focus: true
        padding: 8
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside

        enter: Transition {
            NumberAnimation { property: "opacity"; from: 0.0; to: 1.0; duration: ThemeSystem.Theme.fastDuration }
            NumberAnimation { property: "scale"; from: 0.96; to: 1.0; duration: ThemeSystem.Theme.fastDuration }
        }

        exit: Transition {
            NumberAnimation { property: "opacity"; from: 1.0; to: 0.0; duration: 90 }
            NumberAnimation { property: "scale"; from: 1.0; to: 0.98; duration: 90 }
        }

        background: Rectangle {
            radius: ThemeSystem.Theme.radiusLarge
            color: ThemeSystem.Theme.acrylicFill
            border.width: 1
            border.color: ThemeSystem.Theme.cardBorder

            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: parent.radius - 1
                color: "#ffffff66"
            }
        }

        contentItem: ColumnLayout {
            spacing: 4

            Repeater {
                model: root.contextMenuActions

                delegate: ColumnLayout {
                    required property var modelData

                    Layout.fillWidth: true
                    spacing: 4

                    Rectangle {
                        Layout.fillWidth: true
                        Layout.leftMargin: 6
                        Layout.rightMargin: 6
                        visible: modelData.separatorBefore === true
                        implicitHeight: 1
                        color: ThemeSystem.Theme.cardBorder
                    }

                    Button {
                        id: menuActionButton

                        Layout.fillWidth: true
                        implicitHeight: 38
                        enabled: root.contextMenuActionEnabled(modelData.key)
                        hoverEnabled: true
                        opacity: enabled ? 1.0 : 0.48

                        background: Rectangle {
                            radius: 12
                            color: root.contextMenuActionBackground(modelData.key,
                                                                    menuActionButton.hovered,
                                                                    menuActionButton.down,
                                                                    menuActionButton.enabled)
                            border.width: 1
                            border.color: root.contextMenuActionBorder(modelData.key,
                                                                       menuActionButton.hovered,
                                                                       menuActionButton.down,
                                                                       menuActionButton.enabled)

                            Behavior on color {
                                ColorAnimation { duration: ThemeSystem.Theme.fastDuration }
                            }
                        }

                        contentItem: RowLayout {
                            spacing: 10

                            FluentNavIcon {
                                Layout.preferredWidth: 18
                                Layout.preferredHeight: 18
                                iconName: root.contextMenuActionIcon(modelData.key)
                                iconColor: root.contextMenuActionColor(modelData.key, menuActionButton.enabled)
                                iconSize: 16
                            }

                            Text {
                                Layout.fillWidth: true
                                text: root.contextMenuActionText(modelData.key)
                                color: root.contextMenuActionColor(modelData.key, menuActionButton.enabled)
                                font.pixelSize: 13
                                font.bold: modelData.key === "delete"
                                elide: Text.ElideRight
                                verticalAlignment: Text.AlignVCenter
                                font.family: ThemeSystem.Theme.fontFamily
                            }
                        }

                        onClicked: root.triggerContextMenuAction(modelData.key)
                    }
                }
            }
        }
    }

    Component {
        id: selectionTag

        Rectangle {
            property string text: ""
            property string tone: "info"

            radius: 999
            color: root.toneSoftColor(tone)
            border.width: 1
            border.color: Qt.rgba(root.toneColor(tone).r, root.toneColor(tone).g, root.toneColor(tone).b, 0.20)
            implicitHeight: 28
            implicitWidth: tagLabel.implicitWidth + 18

            Text {
                id: tagLabel
                anchors.centerIn: parent
                text: parent.text
                color: root.toneColor(parent.tone)
                font.pixelSize: 12
                font.bold: true
                font.family: ThemeSystem.Theme.fontFamily
            }
        }
    }

    Component {
        id: fileCardDelegate

        Rectangle {
            id: cardRoot

            required property string path
            required property string title
            required property string subtitle
            required property string kind
            required property string tone
            required property string badgeText
            required property string thumbnailUrl
            required property var thumbnailItems
            required property bool isDir
            required property bool selected
            required property int selectionOrder
            required property bool canPreview
            required property bool canDownload
            required property bool canDelete
            required property string sizeText
            required property string timeText
            required property string cardMode
            required property string streamTag
            required property string cacheTag
            required property string recentTag
            required property string countText

            property real cardWidth: gridFlow.cardWidth

            width: cardWidth
            radius: 20
            color: "#ffffff"
            border.width: selected ? 2 : 1
            border.color: selected ? ThemeSystem.Theme.colorPrimary : ThemeSystem.Theme.cardBorder
            implicitHeight: 250

            Rectangle {
                anchors.fill: parent
                radius: parent.radius
                color: selected ? "#f7fbff" : "transparent"
            }

            Timer {
                id: clickTimer
                interval: 220
                repeat: false
                onTriggered: driveViewModel.toggleSelection(cardRoot.path)
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: function(mouse) {
                    if (mouse.button === Qt.RightButton) {
                        clickTimer.stop()
                        root.openContextMenu(cardRoot.path,
                                             cardRoot.isDir,
                                             cardRoot.canPreview,
                                             cardRoot.canDownload,
                                             cardRoot.canDelete,
                                             mouse.x,
                                             mouse.y,
                                             cardRoot)
                        return
                    }
                    clickTimer.restart()
                }

                onDoubleClicked: function(mouse) {
                    if (mouse.button !== Qt.LeftButton) {
                        return
                    }
                    clickTimer.stop()
                    driveViewModel.activateItem(cardRoot.path)
                }
            }

            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 10

                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 148
                    radius: 16
                    color: cardRoot.isDir ? "#d9e9ff" : ThemeSystem.Theme.panelSurfaceSecondary
                    clip: true

                    Image {
                        anchors.fill: parent
                        visible: cardRoot.thumbnailUrl.length > 0
                        source: cardRoot.thumbnailUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: false
                    }

                    Rectangle {
                        anchors.fill: parent
                        visible: cardRoot.cardMode === "video" && cardRoot.thumbnailUrl.length === 0
                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop { position: 0.0; color: "#7186ef" }
                            GradientStop { position: 1.0; color: "#6f43c7" }
                        }
                    }

                    Rectangle {
                        anchors.fill: parent
                        visible: cardRoot.cardMode === "document" && cardRoot.thumbnailUrl.length === 0
                        gradient: Gradient {
                            orientation: Gradient.Vertical
                            GradientStop { position: 0.0; color: "#edf4ff" }
                            GradientStop { position: 1.0; color: "#d8e7fb" }
                        }
                    }

                    GridLayout {
                        anchors.fill: parent
                        anchors.margins: 10
                        columns: 2
                        columnSpacing: 8
                        rowSpacing: 8
                        visible: cardRoot.isDir

                        Repeater {
                            model: Math.min(4, cardRoot.thumbnailItems.length)

                            delegate: Rectangle {
                                required property int index

                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                radius: 12
                                color: "#ffffffd9"
                                clip: true

                                property var thumb: cardRoot.thumbnailItems[index] || ({})

                                Image {
                                    anchors.fill: parent
                                    visible: thumb.thumbnailUrl && thumb.thumbnailUrl.length > 0
                                    source: thumb.thumbnailUrl || ""
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: false
                                }

                                Text {
                                    anchors.centerIn: parent
                                    visible: !thumb.thumbnailUrl || thumb.thumbnailUrl.length === 0
                                    text: thumb.kind === "video" ? "▶" : (thumb.kind === "image" ? "图" : "文")
                                    color: ThemeSystem.Theme.colorPrimary
                                    font.pixelSize: 18
                                    font.bold: true
                                    font.family: ThemeSystem.Theme.fontFamily
                                }
                            }
                        }
                    }

                    Item {
                        anchors.centerIn: parent
                        visible: !cardRoot.isDir && cardRoot.cardMode === "video" && cardRoot.thumbnailUrl.length === 0
                        width: 64
                        height: 64

                        Rectangle {
                            anchors.centerIn: parent
                            width: 64
                            height: 64
                            radius: 32
                            color: "transparent"
                            border.width: 3
                            border.color: "#ffffff"
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "▶"
                            color: "#ffffff"
                            font.pixelSize: 24
                            font.bold: true
                            font.family: ThemeSystem.Theme.fontFamily
                        }
                    }

                    Item {
                        anchors.centerIn: parent
                        visible: !cardRoot.isDir && cardRoot.cardMode === "document" && cardRoot.thumbnailUrl.length === 0
                        width: 52
                        height: 52

                        Rectangle {
                            anchors.fill: parent
                            radius: 14
                            color: "#ffffffcc"
                        }

                        Text {
                            anchors.centerIn: parent
                            text: "文"
                            color: ThemeSystem.Theme.colorPrimary
                            font.pixelSize: 20
                            font.bold: true
                            font.family: ThemeSystem.Theme.fontFamily
                        }
                    }

                    Rectangle {
                        anchors.left: parent.left
                        anchors.bottom: parent.bottom
                        anchors.margins: 10
                        radius: 10
                        color: "#24324bcc"
                        implicitHeight: 24
                        implicitWidth: badgeLabel.implicitWidth + 14

                        Text {
                            id: badgeLabel
                            anchors.centerIn: parent
                            text: cardRoot.badgeText.length > 0 ? cardRoot.badgeText : cardRoot.countText
                            color: "#ffffff"
                            font.pixelSize: 11
                            font.bold: true
                            font.family: ThemeSystem.Theme.fontFamily
                        }
                    }

                    Rectangle {
                        visible: cardRoot.selectionOrder > 0
                        anchors.top: parent.top
                        anchors.right: parent.right
                        anchors.margins: 10
                        width: 28
                        height: 28
                        radius: 14
                        color: ThemeSystem.Theme.colorPrimary

                        Text {
                            anchors.centerIn: parent
                            text: cardRoot.selectionOrder
                            color: "#ffffff"
                            font.pixelSize: 12
                            font.bold: true
                            font.family: ThemeSystem.Theme.fontFamily
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: title
                    color: ThemeSystem.Theme.textPrimary
                    font.pixelSize: 14
                    font.bold: true
                    wrapMode: Text.WordWrap
                    maximumLineCount: 2
                    elide: Text.ElideRight
                    font.family: ThemeSystem.Theme.fontFamily
                }

                Text {
                    Layout.fillWidth: true
                    text: sizeText
                    color: ThemeSystem.Theme.textSecondary
                    font.pixelSize: 13
                    font.family: ThemeSystem.Theme.fontFamily
                }
            }
        }
    }

    Component {
        id: listRowDelegate

        Rectangle {
            id: rowRoot

            required property string path
            required property string title
            required property string subtitle
            required property string kind
            required property string tone
            required property string badgeText
            required property string thumbnailUrl
            required property var thumbnailItems
            required property bool isDir
            required property bool selected
            required property int selectionOrder
            required property bool canPreview
            required property bool canDownload
            required property bool canDelete
            required property string sizeText
            required property string timeText
            required property string cardMode
            required property string streamTag
            required property string cacheTag
            required property string recentTag

            width: listColumn.width
            radius: 18
            color: selected ? "#f7fbff" : "#ffffff"
            border.width: 1
            border.color: selected ? ThemeSystem.Theme.colorPrimary : ThemeSystem.Theme.cardBorder
            implicitHeight: 96

            Timer {
                id: rowClickTimer
                interval: 220
                repeat: false
                onTriggered: driveViewModel.toggleSelection(rowRoot.path)
            }

            MouseArea {
                anchors.fill: parent
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor

                onClicked: function(mouse) {
                    if (mouse.button === Qt.RightButton) {
                        rowClickTimer.stop()
                        root.openContextMenu(rowRoot.path,
                                             rowRoot.isDir,
                                             rowRoot.canPreview,
                                             rowRoot.canDownload,
                                             rowRoot.canDelete,
                                             mouse.x,
                                             mouse.y,
                                             rowRoot)
                        return
                    }
                    rowClickTimer.restart()
                }

                onDoubleClicked: function(mouse) {
                    if (mouse.button !== Qt.LeftButton) {
                        return
                    }
                    rowClickTimer.stop()
                    driveViewModel.activateItem(rowRoot.path)
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 12
                spacing: 12

                Rectangle {
                    Layout.preferredWidth: 72
                    Layout.preferredHeight: 72
                    radius: 16
                    color: rowRoot.cardMode === "video" ? "#7359dd" : "#edf4ff"
                    clip: true

                    Image {
                        anchors.fill: parent
                        visible: rowRoot.thumbnailUrl.length > 0
                        source: rowRoot.thumbnailUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: false
                    }

                    Text {
                        anchors.centerIn: parent
                        visible: rowRoot.thumbnailUrl.length === 0
                        text: rowRoot.isDir ? "组" : (rowRoot.cardMode === "video" ? "▶" : (rowRoot.cardMode === "document" ? "文" : "图"))
                        color: rowRoot.cardMode === "video" ? "#ffffff" : ThemeSystem.Theme.colorPrimary
                        font.pixelSize: 18
                        font.bold: true
                        font.family: ThemeSystem.Theme.fontFamily
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.minimumWidth: 0
                    spacing: 5

                    RowLayout {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        spacing: 8

                        Text {
                            Layout.fillWidth: true
                            Layout.minimumWidth: 0
                            text: rowRoot.title
                            color: ThemeSystem.Theme.textPrimary
                            font.pixelSize: 14
                            font.bold: true
                            maximumLineCount: 1
                            wrapMode: Text.NoWrap
                            elide: Text.ElideRight
                            clip: true
                            font.family: ThemeSystem.Theme.fontFamily
                        }

                        Rectangle {
                            radius: 999
                            color: root.toneSoftColor(rowRoot.tone)
                            border.width: 1
                            border.color: Qt.rgba(root.toneColor(rowRoot.tone).r, root.toneColor(rowRoot.tone).g, root.toneColor(rowRoot.tone).b, 0.25)
                            implicitHeight: 24
                            implicitWidth: typeText.implicitWidth + 14

                            Text {
                                id: typeText
                                anchors.centerIn: parent
                                text: rowRoot.badgeText
                                color: root.toneColor(rowRoot.tone)
                                font.pixelSize: 11
                                font.bold: true
                                font.family: ThemeSystem.Theme.fontFamily
                            }
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        text: root.listSingleLineText(rowRoot.subtitle, rowRoot.badgeText)
                        color: ThemeSystem.Theme.textSecondary
                        font.pixelSize: 12
                        maximumLineCount: 1
                        wrapMode: Text.NoWrap
                        elide: Text.ElideRight
                        clip: true
                        font.family: ThemeSystem.Theme.fontFamily
                    }

                    Text {
                        Layout.fillWidth: true
                        Layout.minimumWidth: 0
                        text: rowRoot.sizeText + " · " + rowRoot.timeText
                        color: ThemeSystem.Theme.textTertiary
                        font.pixelSize: 12
                        maximumLineCount: 1
                        wrapMode: Text.NoWrap
                        elide: Text.ElideRight
                        clip: true
                        font.family: ThemeSystem.Theme.fontFamily
                    }
                }

                RowLayout {
                    Layout.alignment: Qt.AlignVCenter
                    spacing: 8

                    DriveActionButton {
                        text: rowRoot.isDir ? "打开" : "预览"
                        iconName: rowRoot.isDir ? "open" : "eye"
                        tone: "primary"
                        compact: true
                        onClicked: rowRoot.isDir ? driveViewModel.activateItem(rowRoot.path) : driveViewModel.openPreview(rowRoot.path)
                    }

                    DriveActionButton {
                        text: "下载"
                        iconName: "download"
                        tone: "neutral"
                        compact: true
                        onClicked: driveViewModel.downloadItem(rowRoot.path)
                    }
                }
            }
        }
    }

    Component {
        id: detailPaneComponent

        GlassCard {
            padding: 18
            backgroundColor: "#ffffff"
            borderColor: ThemeSystem.Theme.cardBorder
            shadowOpacity: 0.08
            implicitHeight: detailColumn.implicitHeight + 36

            ColumnLayout {
                id: detailColumn
                anchors.fill: parent
                spacing: 14

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        Text {
                            Layout.fillWidth: true
                            text: driveViewModel.selectedItem.hasSelection
                                  ? driveViewModel.selectedItem.title
                                  : "未选择内容"
                            color: ThemeSystem.Theme.textPrimary
                            font.pixelSize: 16
                            font.bold: true
                            wrapMode: Text.WordWrap
                            font.family: ThemeSystem.Theme.fontFamily
                        }

                        Text {
                            Layout.fillWidth: true
                            text: driveViewModel.selectedItem.hasMultiple
                                  ? driveViewModel.selectionSummary
                                  : root.itemSubtitle(driveViewModel.selectedItem)
                            color: ThemeSystem.Theme.textSecondary
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                            font.family: ThemeSystem.Theme.fontFamily
                        }
                    }

                    Rectangle {
                        visible: driveViewModel.selectedItem.kindLabel && driveViewModel.selectedItem.kindLabel.length > 0
                        radius: 999
                        color: ThemeSystem.Theme.infoSoft
                        border.width: 1
                        border.color: "#cfe2ff"
                        implicitHeight: 28
                        implicitWidth: detailKindText.implicitWidth + 16

                        Text {
                            id: detailKindText
                            anchors.centerIn: parent
                            text: driveViewModel.selectedItem.kindLabel
                            color: ThemeSystem.Theme.colorPrimary
                            font.pixelSize: 11
                            font.bold: true
                            font.family: ThemeSystem.Theme.fontFamily
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: 18
                    color: "#f5f8fc"
                    border.width: 1
                    border.color: ThemeSystem.Theme.cardBorder
                    implicitHeight: 240
                    clip: true

                    Item {
                        anchors.fill: parent

                        Image {
                            anchors.fill: parent
                            anchors.margins: 10
                            visible: driveViewModel.previewState.mode === "image" && driveViewModel.previewState.source.length > 0
                            source: driveViewModel.previewState.source
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            cache: false
                        }

                        Image {
                            anchors.fill: parent
                            anchors.margins: 10
                            visible: driveViewModel.previewState.mode === "none"
                                     && driveViewModel.selectedItem.thumbnailUrl
                                     && driveViewModel.selectedItem.thumbnailUrl.length > 0
                            source: driveViewModel.selectedItem.thumbnailUrl || ""
                            fillMode: Image.PreserveAspectFit
                            asynchronous: true
                            cache: false
                        }

                        VideoOutput {
                            id: detailVideoOutput
                            anchors.fill: parent
                            anchors.margins: 10
                            visible: driveViewModel.previewState.mode === "video" && driveViewModel.previewState.source.length > 0
                            fillMode: VideoOutput.PreserveAspectFit
                        }

                        GridLayout {
                            anchors.fill: parent
                            anchors.margins: 12
                            columns: 2
                            columnSpacing: 8
                            rowSpacing: 8
                            visible: driveViewModel.previewState.mode === "none"
                                     && driveViewModel.selectedItem.isDir
                                     && driveViewModel.selectedItem.thumbnailItems
                                     && driveViewModel.selectedItem.thumbnailItems.length > 0

                            Repeater {
                                model: Math.min(4, driveViewModel.selectedItem.thumbnailItems ? driveViewModel.selectedItem.thumbnailItems.length : 0)

                                delegate: Rectangle {
                                    required property int index

                                    Layout.fillWidth: true
                                    Layout.fillHeight: true
                                    radius: 12
                                    color: "#ffffffd9"
                                    clip: true

                                    property var thumb: driveViewModel.selectedItem.thumbnailItems[index] || ({})

                                    Image {
                                        anchors.fill: parent
                                        visible: thumb.thumbnailUrl && thumb.thumbnailUrl.length > 0
                                        source: thumb.thumbnailUrl || ""
                                        fillMode: Image.PreserveAspectCrop
                                        asynchronous: true
                                        cache: false
                                    }

                                    Text {
                                        anchors.centerIn: parent
                                        visible: !thumb.thumbnailUrl || thumb.thumbnailUrl.length === 0
                                        text: thumb.kind === "video" ? "▶" : (thumb.kind === "image" ? "图" : "文")
                                        color: ThemeSystem.Theme.colorPrimary
                                        font.pixelSize: 18
                                        font.bold: true
                                        font.family: ThemeSystem.Theme.fontFamily
                                    }
                                }
                            }
                        }

                        Rectangle {
                            anchors.fill: parent
                            visible: driveViewModel.previewState.mode === "none"
                                     && (!driveViewModel.selectedItem.hasSelection
                                         || (!driveViewModel.selectedItem.thumbnailUrl
                                             && (!driveViewModel.selectedItem.thumbnailItems
                                                 || driveViewModel.selectedItem.thumbnailItems.length === 0)))
                            color: "transparent"

                            Column {
                                anchors.centerIn: parent
                                width: parent.width - 40
                                spacing: 8

                                Text {
                                    width: parent.width
                                    text: driveViewModel.previewState.status
                                    horizontalAlignment: Text.AlignHCenter
                                    color: ThemeSystem.Theme.textSecondary
                                    font.pixelSize: 14
                                    font.bold: true
                                    wrapMode: Text.WordWrap
                                    font.family: ThemeSystem.Theme.fontFamily
                                }

                                Text {
                                    width: parent.width
                                    text: driveViewModel.previewState.info
                                    horizontalAlignment: Text.AlignHCenter
                                    color: ThemeSystem.Theme.textTertiary
                                    font.pixelSize: 12
                                    wrapMode: Text.WordWrap
                                    font.family: ThemeSystem.Theme.fontFamily
                                }
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 10

                    Rectangle {
                        Layout.fillWidth: true
                        radius: 16
                        color: ThemeSystem.Theme.panelSurfaceSecondary
                        border.width: 1
                        border.color: ThemeSystem.Theme.cardBorder
                        implicitHeight: 72

                        Column {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 4

                            Text {
                                text: "大小"
                                color: ThemeSystem.Theme.textTertiary
                                font.pixelSize: 11
                                font.family: ThemeSystem.Theme.fontFamily
                            }

                            Text {
                                text: driveViewModel.selectedItem.metaPrimary
                                color: ThemeSystem.Theme.textPrimary
                                font.pixelSize: 14
                                font.bold: true
                                wrapMode: Text.WordWrap
                                font.family: ThemeSystem.Theme.fontFamily
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        radius: 16
                        color: ThemeSystem.Theme.panelSurfaceSecondary
                        border.width: 1
                        border.color: ThemeSystem.Theme.cardBorder
                        implicitHeight: 72

                        Column {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 4

                            Text {
                                text: "时间"
                                color: ThemeSystem.Theme.textTertiary
                                font.pixelSize: 11
                                font.family: ThemeSystem.Theme.fontFamily
                            }

                            Text {
                                text: driveViewModel.selectedItem.metaSecondary
                                color: ThemeSystem.Theme.textPrimary
                                font.pixelSize: 14
                                font.bold: true
                                wrapMode: Text.WordWrap
                                font.family: ThemeSystem.Theme.fontFamily
                            }
                        }
                    }
                }

                Flow {
                    Layout.fillWidth: true
                    width: parent.width
                    spacing: 8

                    DriveActionButton {
                        visible: driveViewModel.selectedItem.canPreview
                        text: "预览"
                        iconName: "eye"
                        tone: "primary"
                        onClicked: driveViewModel.openPreview(driveViewModel.selectedItem.path)
                    }

                    DriveActionButton {
                        visible: driveViewModel.selectedItem.canDownload
                        text: driveViewModel.selectedItem.isDir ? "下载整组" : "下载"
                        iconName: "download"
                        tone: "neutral"
                        onClicked: driveViewModel.downloadItem(driveViewModel.selectedItem.path)
                    }

                    DriveActionButton {
                        visible: driveViewModel.selectedItem.canDelete
                        text: driveViewModel.selectedItem.isDir ? "删除媒体组" : "删除"
                        iconName: "trash"
                        tone: "danger"
                        onClicked: driveViewModel.deleteSelected()
                    }

                    DriveActionButton {
                        visible: driveViewModel.previewState.mode !== "none"
                        text: "关闭预览"
                        iconName: "close"
                        tone: "neutral"
                        onClicked: driveViewModel.closePreview()
                    }
                }
            }
        }
    }

    GlassCard {
        id: summaryCard

        Layout.fillWidth: true
        padding: 16
        backgroundColor: "#f8fbff"
        borderColor: "#dbe7f3"
        shadowOpacity: 0.04
        implicitHeight: summaryRow.implicitHeight + padding * 2

        RowLayout {
            id: summaryRow
            anchors.fill: parent
            spacing: 16

            Text {
                Layout.fillWidth: true
                Layout.alignment: Qt.AlignVCenter
                text: driveViewModel.channelSummary
                color: ThemeSystem.Theme.textPrimary
                font.pixelSize: 15
                font.bold: true
                font.family: ThemeSystem.Theme.fontFamily
                elide: Text.ElideRight
            }

            RowLayout {
                Layout.alignment: Qt.AlignVCenter
                spacing: 8

                AppTextField {
                    Layout.preferredWidth: Math.max(240, Math.min(360, summaryCard.width * 0.24))
                    text: driveViewModel.searchKeyword
                    placeholderText: "搜索文件名、媒体组标题或说明"
                    onTextEdited: driveViewModel.setSearchKeyword(text)
                    onAccepted: driveViewModel.commitSearch()
                }

                DriveIconButton {
                    iconName: "refresh"
                    tone: "primary"
                    enabled: !driveViewModel.busy
                    spinning: driveViewModel.busy
                    toolTipText: driveViewModel.busy ? "刷新中..." : "刷新"
                    onClicked: driveViewModel.refresh()
                }
            }
        }
    }

    FluentBanner {
        Layout.fillWidth: true
        visible: driveViewModel.errorMessage.length > 0
        tone: "danger"
        title: ""
        description: driveViewModel.errorMessage
    }

    RowLayout {
        Layout.fillWidth: true
        Layout.alignment: Qt.AlignTop
        spacing: 18

        GlassCard {
            id: workspaceCard

            Layout.fillWidth: true
            Layout.alignment: Qt.AlignTop
            padding: 18
            backgroundColor: "#ffffff"
            borderColor: ThemeSystem.Theme.cardBorder
            shadowOpacity: 0.06
            implicitHeight: workspaceColumn.implicitHeight + 36

            property real contentWidth: width - 36

            ColumnLayout {
                id: workspaceColumn
                anchors.fill: parent
                spacing: 16

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 16

                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 4

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            DriveIconButton {
                                visible: driveViewModel.canNavigateUp
                                iconName: "back-up"
                                tone: "neutral"
                                toolTipText: "返回上级"
                                onClicked: driveViewModel.navigateUp()
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Text {
                                    text: driveViewModel.workspaceTitle
                                    color: ThemeSystem.Theme.textPrimary
                                    font.pixelSize: 18
                                    font.bold: true
                                    font.family: ThemeSystem.Theme.fontFamily
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: driveViewModel.breadcrumbText
                                    color: ThemeSystem.Theme.textSecondary
                                    font.pixelSize: 12
                                    wrapMode: Text.WordWrap
                                    font.family: ThemeSystem.Theme.fontFamily
                                }
                            }
                        }
                    }

                    RowLayout {
                        Layout.alignment: Qt.AlignTop
                        spacing: 8

                        Rectangle {
                            radius: 999
                            color: root.toneSoftColor("primary")
                            border.width: 1
                            border.color: Qt.rgba(root.toneColor("primary").r, root.toneColor("primary").g, root.toneColor("primary").b, 0.20)
                            implicitHeight: 28
                            implicitWidth: hintChipText.implicitWidth + 18

                            Text {
                                id: hintChipText
                                anchors.centerIn: parent
                                text: "单击选择，双击打开，右键操作"
                                color: root.toneColor("primary")
                                font.pixelSize: 12
                                font.bold: true
                                font.family: ThemeSystem.Theme.fontFamily
                            }
                        }

                        Rectangle {
                            radius: 999
                            color: root.toneSoftColor("info")
                            border.width: 1
                            border.color: Qt.rgba(root.toneColor("info").r, root.toneColor("info").g, root.toneColor("info").b, 0.20)
                            implicitHeight: 28
                            implicitWidth: styleChipText.implicitWidth + 18

                            Text {
                                id: styleChipText
                                anchors.centerIn: parent
                                text: "PikPak 风格工作区"
                                color: root.toneColor("info")
                                font.pixelSize: 12
                                font.bold: true
                                font.family: ThemeSystem.Theme.fontFamily
                            }
                        }
                    }
                }

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 12

                    Flow {
                        Layout.fillWidth: true
                        width: Math.max(0, workspaceCard.contentWidth - 356)
                        spacing: 8

                        Repeater {
                            model: root.sectionOptions

                            delegate: Item {
                                required property var modelData

                                implicitHeight: 34
                                implicitWidth: chipButton.implicitWidth

                                FluentChip {
                                    id: chipButton

                                    text: root.sectionChipText(modelData.key, modelData.label)
                                    active: driveViewModel.sidebarSection === modelData.key
                                    onClicked: driveViewModel.setSidebarSection(modelData.key)
                                }
                            }
                        }
                    }

                    RowLayout {
                        spacing: 8

                        Rectangle {
                            radius: 16
                            color: "#f4f7fb"
                            border.width: 1
                            border.color: ThemeSystem.Theme.cardBorder
                            implicitHeight: 38
                            implicitWidth: 132

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 4
                                spacing: 4

                                DriveSegmentButton {
                                    Layout.fillWidth: true
                                    text: "网格"
                                    iconName: "grid"
                                    selected: driveViewModel.viewMode === "grid"
                                    onClicked: driveViewModel.setViewMode("grid")
                                }

                                DriveSegmentButton {
                                    Layout.fillWidth: true
                                    text: "列表"
                                    iconName: "list"
                                    selected: driveViewModel.viewMode === "list"
                                    onClicked: driveViewModel.setViewMode("list")
                                }
                            }
                        }

                        DriveComboBox {
                            id: sortCombo
                            model: root.sortOptions
                            textRole: "label"
                            implicitWidth: 168

                            Component.onCompleted: {
                                for (var i = 0; i < root.sortOptions.length; i += 1) {
                                    if (root.sortOptions[i].value === driveViewModel.sortOption) {
                                        currentIndex = i
                                        break
                                    }
                                }
                            }

                            onActivated: driveViewModel.setSortOption(root.sortOptions[currentIndex].value)
                        }

                        DriveActionButton {
                            text: driveViewModel.detailPanelVisible ? "隐藏详情" : "显示详情"
                            iconName: "detail"
                            tone: driveViewModel.detailPanelVisible ? "info" : "neutral"
                            onClicked: driveViewModel.toggleDetailPanel()
                        }

                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: driveViewModel.filterSummary
                    color: ThemeSystem.Theme.textSecondary
                    font.pixelSize: 12
                    wrapMode: Text.WordWrap
                    font.family: ThemeSystem.Theme.fontFamily
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: 18
                    color: "#f6faff"
                    border.width: 1
                    border.color: "#dce9f8"
                    implicitHeight: 48

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 14
                        anchors.rightMargin: 14
                        spacing: 12

                        Text {
                            Layout.fillWidth: true
                            text: driveViewModel.selectionSummary
                            color: ThemeSystem.Theme.colorPrimary
                            font.pixelSize: 13
                            font.bold: true
                            font.family: ThemeSystem.Theme.fontFamily
                        }

                        DriveActionButton {
                            text: "打开"
                            iconName: "open"
                            tone: "primary"
                            compact: true
                            enabled: driveViewModel.openEnabled
                            onClicked: driveViewModel.openSelection()
                        }

                        DriveActionButton {
                            text: "批量下载"
                            iconName: "download"
                            tone: "neutral"
                            compact: true
                            enabled: driveViewModel.batchDownloadEnabled
                            onClicked: driveViewModel.batchDownloadSelected()
                        }

                        DriveActionButton {
                            text: "批量删除"
                            iconName: "trash"
                            tone: "danger"
                            compact: true
                            enabled: driveViewModel.batchDeleteEnabled
                            onClicked: driveViewModel.batchDeleteSelected()
                        }

                        DriveActionButton {
                            text: "清除选择"
                            iconName: "clear"
                            tone: "warning"
                            compact: true
                            enabled: driveViewModel.hasSelection
                            onClicked: driveViewModel.clearSelection()
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: 20
                    color: "#ffffff"
                    border.width: 1
                    border.color: "#eef2f6"
                    implicitHeight: driveViewModel.itemsModel.count === 0
                                    ? 330
                                    : (driveViewModel.viewMode === "grid" ? gridFlow.implicitHeight + 88 : listColumn.implicitHeight + 88)

                    Column {
                        anchors.fill: parent
                        anchors.margins: 12
                        spacing: 12

                        Flow {
                            id: gridFlow

                            readonly property real cardSpacing: 18
                            readonly property int gridColumns: Math.max(1, Math.floor((width + cardSpacing) / 220))
                            readonly property real cardWidth: Math.max(180, Math.floor((width - (gridColumns - 1) * cardSpacing) / gridColumns))

                            width: parent.width
                            spacing: cardSpacing
                            visible: driveViewModel.viewMode === "grid" && driveViewModel.itemsModel.count > 0

                            Repeater {
                                model: driveViewModel.itemsModel
                                delegate: fileCardDelegate
                            }
                        }

                        Column {
                            id: listColumn
                            width: parent.width
                            spacing: 10
                            visible: driveViewModel.viewMode === "list" && driveViewModel.itemsModel.count > 0

                            Repeater {
                                model: driveViewModel.itemsModel
                                delegate: listRowDelegate
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 220
                            radius: 18
                            visible: driveViewModel.itemsModel.count === 0
                            color: "#f9fbfe"
                            border.width: 1
                            border.color: "#e7edf4"

                            Column {
                                anchors.centerIn: parent
                                width: Math.min(parent.width - 48, 420)
                                spacing: 8

                                Text {
                                    width: parent.width
                                    text: driveViewModel.emptyState
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.WordWrap
                                    color: ThemeSystem.Theme.textPrimary
                                    font.pixelSize: 14
                                    font.bold: true
                                    font.family: ThemeSystem.Theme.fontFamily
                                }

                                Text {
                                    width: parent.width
                                    text: "试试切换筛选、返回上级，或刷新一次。"
                                    horizontalAlignment: Text.AlignHCenter
                                    wrapMode: Text.WordWrap
                                    color: ThemeSystem.Theme.textTertiary
                                    font.pixelSize: 12
                                    font.family: ThemeSystem.Theme.fontFamily
                                }
                            }
                        }

                        Rectangle {
                            width: parent.width
                            radius: 16
                            color: "#f8fbff"
                            border.width: 1
                            border.color: "#dce9f8"
                            implicitHeight: pagerRow.implicitHeight + 24

                            RowLayout {
                                id: pagerRow

                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 12

                                Text {
                                    Layout.fillWidth: true
                                    text: driveViewModel.pageSummary
                                    color: ThemeSystem.Theme.textSecondary
                                    font.pixelSize: 12
                                    wrapMode: Text.WordWrap
                                    font.family: ThemeSystem.Theme.fontFamily
                                }

                                RowLayout {
                                    visible: !driveViewModel.canNavigateUp
                                    spacing: 8

                                    DriveActionButton {
                                        text: "上一页"
                                        tone: "neutral"
                                        compact: true
                                        enabled: driveViewModel.canPreviousPage
                                        onClicked: driveViewModel.previousPage()
                                    }

                                    Rectangle {
                                        radius: 999
                                        color: "#ffffff"
                                        border.width: 1
                                        border.color: "#cfe2ff"
                                        implicitHeight: 34
                                        implicitWidth: pageText.implicitWidth + 22

                                        Text {
                                            id: pageText
                                            anchors.centerIn: parent
                                            text: driveViewModel.currentPage + " / " + driveViewModel.totalPages
                                            color: ThemeSystem.Theme.colorPrimary
                                            font.pixelSize: 12
                                            font.bold: true
                                            font.family: ThemeSystem.Theme.fontFamily
                                        }
                                    }

                                    DriveActionButton {
                                        text: "下一页"
                                        tone: "primary"
                                        compact: true
                                        enabled: driveViewModel.canNextPage
                                        onClicked: driveViewModel.nextPage()
                                    }
                                }

                                DriveComboBox {
                                    id: pageSizeCombo
                                    visible: !driveViewModel.canNavigateUp
                                    implicitWidth: 110
                                    model: root.pageSizeOptions

                                    Component.onCompleted: {
                                        currentIndex = Math.max(0, root.pageSizeOptions.indexOf(driveViewModel.pageSize))
                                    }

                                    Connections {
                                        target: driveViewModel

                                        function onPaginationChanged() {
                                            pageSizeCombo.currentIndex = Math.max(0, root.pageSizeOptions.indexOf(driveViewModel.pageSize))
                                        }
                                    }

                                    onActivated: driveViewModel.setPageSize(root.pageSizeOptions[currentIndex])
                                }
                            }
                        }
                    }
                }
            }
        }

        Loader {
            visible: root.showWideDetail
            active: visible
            Layout.preferredWidth: 332
            Layout.alignment: Qt.AlignTop
            sourceComponent: detailPaneComponent
        }
    }

    Loader {
        visible: driveViewModel.detailPanelVisible && !root.showWideDetail
        active: visible
        Layout.fillWidth: true
        sourceComponent: detailPaneComponent
    }
}
