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

    property var browseItems: [
        { key: "all", title: "全部", hint: "频道中的所有媒体文件", icon: "drive" },
        { key: "videos", title: "视频", hint: "在线播放和本地缓存优先", icon: "downloads" },
        { key: "images", title: "图片", hint: "快速预览图片资源", icon: "dashboard" },
        { key: "documents", title: "文档", hint: "压缩包、PDF 和普通文件", icon: "settings" }
    ]
    property var smartItems: [
        { key: "flows", title: "全部流", hint: "当前筛选下的完整文件流", icon: "dashboard" },
        { key: "recent", title: "最近", hint: "近 7 天新增或更新的内容", icon: "downloads" }
    ]
    property var sortOptions: [
        { value: "time_desc", label: "时间（新到旧）" },
        { value: "time_asc", label: "时间（旧到新）" },
        { value: "size_desc", label: "体积（大到小）" },
        { value: "name_asc", label: "名称（A-Z）" }
    ]
    property var filterOptions: [
        { value: "all", label: "全部" },
        { value: "videos", label: "视频" },
        { value: "images", label: "图片" },
        { value: "documents", label: "文档" }
    ]
    property var pageSizeOptions: [10, 30, 60, 100, 200]

    property string contextPath: ""
    property bool contextIsDir: false
    property bool contextCanPreview: false
    property bool contextCanDownload: false
    property bool contextCanDelete: false

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
        var stats = driveViewModel.sidebarStats || {}
        return stats[key] !== undefined ? stats[key] : 0
    }

    function summaryValue(key) {
        var stats = driveViewModel.channelStats || {}
        return stats[key] !== undefined ? stats[key] : 0
    }

    function sortLabel(value) {
        for (var i = 0; i < root.sortOptions.length; i += 1) {
            if (root.sortOptions[i].value === value) {
                return root.sortOptions[i].label
            }
        }
        return "时间（新到旧）"
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
        var point = sourceItem.mapToItem(root, x, y)
        contextMenu.x = point.x
        contextMenu.y = point.y
        contextMenu.open()
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
        active: driveViewModel.previewState.mode === "video" && driveViewModel.previewState.source.length > 0
        sourceComponent: previewPlayerComponent
    }

    Menu {
        id: contextMenu

        MenuItem {
            text: root.contextIsDir ? "打开媒体组" : "打开"
            onTriggered: driveViewModel.activateItem(root.contextPath)
        }

        MenuItem {
            text: "预览"
            enabled: root.contextCanPreview
            onTriggered: driveViewModel.openPreview(root.contextPath)
        }

        MenuItem {
            text: root.contextIsDir ? "下载整组" : "下载"
            enabled: root.contextCanDownload
            onTriggered: driveViewModel.downloadItem(root.contextPath)
        }

        MenuItem {
            text: root.contextIsDir ? "删除媒体组" : "删除"
            enabled: root.contextCanDelete
            onTriggered: driveViewModel.deleteItem(root.contextPath)
        }

        MenuSeparator { }

        MenuItem {
            text: "清除选择"
            enabled: driveViewModel.hasSelection
            onTriggered: driveViewModel.clearSelection()
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
        id: navEntryDelegate

        Rectangle {
            required property var modelData

            Layout.fillWidth: true
            radius: 22
            color: driveViewModel.sidebarSection === modelData.key
                   ? "#dcecff"
                   : "#ffffff"
            border.width: 1
            border.color: driveViewModel.sidebarSection === modelData.key
                          ? "#a7c8ff"
                          : ThemeSystem.Theme.cardBorder
            implicitHeight: 94

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: driveViewModel.setSidebarSection(modelData.key)
            }

            RowLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 14

                Rectangle {
                    Layout.preferredWidth: 38
                    Layout.preferredHeight: 38
                    radius: 14
                    color: driveViewModel.sidebarSection === modelData.key
                           ? "#ffffff"
                           : ThemeSystem.Theme.sidebarHoverFill

                    FluentNavIcon {
                        anchors.centerIn: parent
                        iconName: modelData.icon
                        iconColor: driveViewModel.sidebarSection === modelData.key
                                   ? ThemeSystem.Theme.colorPrimary
                                   : ThemeSystem.Theme.sidebarTextMuted
                        iconSize: 18
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            Layout.fillWidth: true
                            text: modelData.title
                            color: ThemeSystem.Theme.textPrimary
                            font.pixelSize: 15
                            font.bold: true
                            font.family: ThemeSystem.Theme.fontFamily
                        }

                        Text {
                            text: root.countFor(modelData.key)
                            color: ThemeSystem.Theme.colorPrimary
                            font.pixelSize: 15
                            font.bold: true
                            font.family: ThemeSystem.Theme.fontFamily
                        }
                    }

                    Text {
                        Layout.fillWidth: true
                        text: modelData.hint
                        color: ThemeSystem.Theme.textTertiary
                        font.pixelSize: 12
                        wrapMode: Text.WordWrap
                        font.family: ThemeSystem.Theme.fontFamily
                    }
                }
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

            Layout.fillWidth: true
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
                    spacing: 5

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        Text {
                            Layout.fillWidth: true
                            text: rowRoot.title
                            color: ThemeSystem.Theme.textPrimary
                            font.pixelSize: 14
                            font.bold: true
                            elide: Text.ElideRight
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
                        text: rowRoot.subtitle
                        color: ThemeSystem.Theme.textSecondary
                        font.pixelSize: 12
                        elide: Text.ElideRight
                        font.family: ThemeSystem.Theme.fontFamily
                    }

                    Text {
                        Layout.fillWidth: true
                        text: rowRoot.sizeText + " · " + rowRoot.timeText
                        color: ThemeSystem.Theme.textTertiary
                        font.pixelSize: 12
                        font.family: ThemeSystem.Theme.fontFamily
                    }
                }

                RowLayout {
                    spacing: 8

                    Button {
                        text: rowRoot.isDir ? "打开" : "预览"
                        onClicked: rowRoot.isDir ? driveViewModel.activateItem(rowRoot.path) : driveViewModel.openPreview(rowRoot.path)
                    }

                    Button {
                        text: "下载"
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

                    Button {
                        visible: driveViewModel.selectedItem.canPreview
                        text: "预览"
                        onClicked: driveViewModel.openPreview(driveViewModel.selectedItem.path)
                    }

                    Button {
                        visible: driveViewModel.selectedItem.canDownload
                        text: driveViewModel.selectedItem.isDir ? "下载整组" : "下载"
                        onClicked: driveViewModel.downloadItem(driveViewModel.selectedItem.path)
                    }

                    Button {
                        visible: driveViewModel.selectedItem.canDelete
                        text: driveViewModel.selectedItem.isDir ? "删除媒体组" : "删除"
                        onClicked: driveViewModel.deleteSelected()
                    }

                    Button {
                        visible: driveViewModel.previewState.mode !== "none"
                        text: "关闭预览"
                        onClicked: driveViewModel.closePreview()
                    }
                }
            }
        }
    }

    GlassCard {
        Layout.fillWidth: true
        padding: 16
        backgroundColor: "#f8fbff"
        borderColor: "#dbe7f3"
        shadowOpacity: 0.04

        RowLayout {
            anchors.fill: parent
            spacing: 12

            Text {
                text: driveViewModel.channelSummary
                color: ThemeSystem.Theme.textPrimary
                font.pixelSize: 15
                font.bold: true
                font.family: ThemeSystem.Theme.fontFamily
            }

            Text {
                text: driveViewModel.usageSummary
                color: ThemeSystem.Theme.textSecondary
                font.pixelSize: 13
                font.family: ThemeSystem.Theme.fontFamily
            }

            Rectangle {
                radius: 999
                color: "#ffffff"
                border.width: 1
                border.color: "#cfe2ff"
                implicitHeight: 28
                implicitWidth: videoCountLabel.implicitWidth + 18

                Text {
                    id: videoCountLabel
                    anchors.centerIn: parent
                    text: root.summaryValue("videos") + " 视频"
                    color: ThemeSystem.Theme.colorPrimary
                    font.pixelSize: 12
                    font.family: ThemeSystem.Theme.fontFamily
                }
            }

            Rectangle {
                radius: 999
                color: "#ffffff"
                border.width: 1
                border.color: "#cfe2ff"
                implicitHeight: 28
                implicitWidth: imageCountLabel.implicitWidth + 18

                Text {
                    id: imageCountLabel
                    anchors.centerIn: parent
                    text: root.summaryValue("images") + " 图片"
                    color: ThemeSystem.Theme.colorPrimary
                    font.pixelSize: 12
                    font.family: ThemeSystem.Theme.fontFamily
                }
            }

            Item {
                Layout.fillWidth: true
            }

            Button {
                text: driveViewModel.busy ? "刷新中..." : "刷新"
                enabled: !driveViewModel.busy
                onClicked: driveViewModel.refresh()
            }
        }
    }

    GlassCard {
        Layout.fillWidth: true
        padding: 14
        backgroundColor: "#ffffff"
        borderColor: ThemeSystem.Theme.cardBorder
        shadowOpacity: 0.05

        RowLayout {
            anchors.fill: parent
            spacing: 12

            Button {
                text: "返回上级"
                enabled: driveViewModel.canNavigateUp
                onClicked: driveViewModel.navigateUp()
            }

            Text {
                text: "⌂"
                color: ThemeSystem.Theme.textTertiary
                font.pixelSize: 14
                font.family: ThemeSystem.Theme.fontFamily
            }

            Text {
                Layout.fillWidth: true
                text: driveViewModel.breadcrumbText
                color: ThemeSystem.Theme.textPrimary
                font.pixelSize: 14
                elide: Text.ElideRight
                font.family: ThemeSystem.Theme.fontFamily
            }

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

                    Button {
                        Layout.fillWidth: true
                        text: "网格"
                        flat: true
                        highlighted: driveViewModel.viewMode === "grid"
                        onClicked: driveViewModel.setViewMode("grid")
                    }

                    Button {
                        Layout.fillWidth: true
                        text: "列表"
                        flat: true
                        highlighted: driveViewModel.viewMode === "list"
                        onClicked: driveViewModel.setViewMode("list")
                    }
                }
            }

            ComboBox {
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

            Button {
                text: driveViewModel.detailPanelVisible ? "隐藏详情" : "显示详情"
                onClicked: driveViewModel.toggleDetailPanel()
            }

            Rectangle {
                radius: ThemeSystem.Theme.radiusMedium
                color: "#fff5f5"
                border.width: 1
                border.color: "#f3d2d2"
                implicitHeight: 38
                implicitWidth: clearText.implicitWidth + 20

                Text {
                    id: clearText
                    anchors.centerIn: parent
                    text: "清空 Telegram"
                    color: "#b42318"
                    font.pixelSize: 12
                    font.bold: true
                    font.family: ThemeSystem.Theme.fontFamily
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: driveViewModel.clearTelegramMedia()
                }
            }
        }
    }

    FluentBanner {
        Layout.fillWidth: true
        visible: driveViewModel.busy
        tone: "info"
        title: ""
        description: "正在刷新 Telegram 网盘内容..."
    }

    FluentBanner {
        Layout.fillWidth: true
        visible: driveViewModel.infoMessage.length > 0
        tone: "success"
        title: ""
        description: driveViewModel.infoMessage
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
            Layout.preferredWidth: root.compact ? root.contentFrameWidth : 222
            Layout.fillWidth: root.compact
            Layout.alignment: Qt.AlignTop
            padding: 18
            backgroundColor: "#ffffff"
            borderColor: ThemeSystem.Theme.cardBorder
            shadowOpacity: 0.06
            implicitHeight: navColumn.implicitHeight + 36

            ColumnLayout {
                id: navColumn
                anchors.fill: parent
                spacing: 14

                Rectangle {
                    Layout.fillWidth: true
                    radius: 22
                    gradient: Gradient {
                        orientation: Gradient.Vertical
                        GradientStop { position: 0.0; color: "#eef6ff" }
                        GradientStop { position: 1.0; color: "#f7fbff" }
                    }
                    border.width: 1
                    border.color: "#cfe2ff"
                    implicitHeight: 152

                    Column {
                        anchors.fill: parent
                        anchors.margins: 18
                        spacing: 8

                        Text {
                            text: "我的网盘"
                            color: ThemeSystem.Theme.textSecondary
                            font.pixelSize: 14
                            font.bold: true
                            font.family: ThemeSystem.Theme.fontFamily
                        }

                        Text {
                            text: root.summaryValue("totalSize")
                            color: ThemeSystem.Theme.textPrimary
                            font.pixelSize: 18
                            font.bold: true
                            font.family: ThemeSystem.Theme.fontFamily
                        }

                        Text {
                            text: root.summaryValue("totalCount") + " 个文件"
                            color: ThemeSystem.Theme.textSecondary
                            font.pixelSize: 13
                            font.family: ThemeSystem.Theme.fontFamily
                        }

                        Row {
                            spacing: 8

                            Rectangle {
                                radius: 999
                                color: root.toneSoftColor(driveViewModel.sidebarSection === "streaming" ? "primary" : "info")
                                border.width: 1
                                border.color: Qt.rgba(root.toneColor(driveViewModel.sidebarSection === "streaming" ? "primary" : "info").r,
                                                       root.toneColor(driveViewModel.sidebarSection === "streaming" ? "primary" : "info").g,
                                                       root.toneColor(driveViewModel.sidebarSection === "streaming" ? "primary" : "info").b, 0.20)
                                implicitHeight: 28
                                implicitWidth: streamChipText.implicitWidth + 18

                                Text {
                                    id: streamChipText
                                    anchors.centerIn: parent
                                    text: "在线播放"
                                    color: root.toneColor(driveViewModel.sidebarSection === "streaming" ? "primary" : "info")
                                    font.pixelSize: 12
                                    font.bold: true
                                    font.family: ThemeSystem.Theme.fontFamily
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: driveViewModel.setSidebarSection("streaming")
                                }
                            }

                            Rectangle {
                                radius: 999
                                color: root.toneSoftColor(driveViewModel.sidebarSection === "cached" ? "success" : "primary")
                                border.width: 1
                                border.color: Qt.rgba(root.toneColor(driveViewModel.sidebarSection === "cached" ? "success" : "primary").r,
                                                       root.toneColor(driveViewModel.sidebarSection === "cached" ? "success" : "primary").g,
                                                       root.toneColor(driveViewModel.sidebarSection === "cached" ? "success" : "primary").b, 0.20)
                                implicitHeight: 28
                                implicitWidth: cacheChipText.implicitWidth + 18

                                Text {
                                    id: cacheChipText
                                    anchors.centerIn: parent
                                    text: "本地缓存"
                                    color: root.toneColor(driveViewModel.sidebarSection === "cached" ? "success" : "primary")
                                    font.pixelSize: 12
                                    font.bold: true
                                    font.family: ThemeSystem.Theme.fontFamily
                                }

                                MouseArea {
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: driveViewModel.setSidebarSection("cached")
                                }
                            }
                        }
                    }
                }

                Text {
                    text: "浏览"
                    color: ThemeSystem.Theme.textSecondary
                    font.pixelSize: 13
                    font.bold: true
                    font.family: ThemeSystem.Theme.fontFamily
                }

                Repeater {
                    model: root.browseItems
                    delegate: navEntryDelegate
                }

                Text {
                    text: "智能视图"
                    color: ThemeSystem.Theme.textSecondary
                    font.pixelSize: 13
                    font.bold: true
                    font.family: ThemeSystem.Theme.fontFamily
                }

                Repeater {
                    model: root.smartItems
                    delegate: navEntryDelegate
                }
            }
        }

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

                        Text {
                            text: driveViewModel.workspaceTitle
                            color: ThemeSystem.Theme.textPrimary
                            font.pixelSize: 18
                            font.bold: true
                            font.family: ThemeSystem.Theme.fontFamily
                        }

                        Text {
                            Layout.fillWidth: true
                            text: driveViewModel.filterSummary
                            color: ThemeSystem.Theme.textSecondary
                            font.pixelSize: 12
                            wrapMode: Text.WordWrap
                            font.family: ThemeSystem.Theme.fontFamily
                        }
                    }

                    Row {
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

                AppTextField {
                    Layout.fillWidth: true
                    text: driveViewModel.searchKeyword
                    placeholderText: "搜索文件名、媒体组标题或说明"
                    onTextEdited: driveViewModel.setSearchKeyword(text)
                    onAccepted: driveViewModel.commitSearch()
                }

                Flow {
                    Layout.fillWidth: true
                    width: parent.width
                    spacing: 8
                    visible: driveViewModel.showFilesChips

                    Repeater {
                        model: root.filterOptions

                        delegate: FluentChip {
                            required property var modelData

                            text: modelData.label
                            active: driveViewModel.currentFilter === modelData.value
                            onClicked: driveViewModel.setCurrentFilter(modelData.value)
                        }
                    }
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

                        Button {
                            text: "打开"
                            enabled: driveViewModel.openEnabled
                            onClicked: driveViewModel.openSelection()
                        }

                        Button {
                            text: "批量下载"
                            enabled: driveViewModel.batchDownloadEnabled
                            onClicked: driveViewModel.batchDownloadSelected()
                        }

                        Button {
                            text: "批量删除"
                            enabled: driveViewModel.batchDeleteEnabled
                            onClicked: driveViewModel.batchDeleteSelected()
                        }

                        Button {
                            text: "清除选择"
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

                                    Button {
                                        text: "上一页"
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

                                    Button {
                                        text: "下一页"
                                        enabled: driveViewModel.canNextPage
                                        onClicked: driveViewModel.nextPage()
                                    }
                                }

                                ComboBox {
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
