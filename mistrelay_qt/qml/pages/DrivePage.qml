import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme" as ThemeSystem
import "../components"

ResponsivePage {
    id: root

    readonly property var driveVm: driveViewModel || ({
        channelStats: ({}),
        sidebarSection: "all",
        hasSelection: false,
        selectedPaths: [],
        itemsModel: null,
        viewMode: "grid",
        busy: false,
        errorMessage: "",
        channelSummary: "",
        searchKeyword: "",
        canNavigateUp: false,
        workspaceTitle: "",
        breadcrumbText: "",
        filterSummary: "",
        selectionSummary: "",
        openEnabled: false,
        batchDownloadEnabled: false,
        batchDeleteEnabled: false,
        emptyState: "",
        pageSummary: "",
        currentPage: 1,
        totalPages: 1,
        canPreviousPage: false,
        canNextPage: false,
        pageSize: 30,
        sortOption: "time_desc",
        setSidebarSection: function() {},
        refresh: function() {},
        setSearchKeyword: function() {},
        commitSearch: function() {},
        setViewMode: function() {},
        openSelection: function() {},
        batchDownloadSelected: function() {},
        batchDeleteSelected: function() {},
        clearSelection: function() {},
        activateItem: function() {},
        selectItem: function() {},
        toggleSelection: function() {},
        openPreview: function() {},
        downloadItem: function() {},
        deleteItem: function() {},
        deleteSelected: function() {},
        navigateUp: function() {},
        previousPage: function() {},
        nextPage: function() {},
        setPageSize: function() {},
        setSortOption: function() {}
    })

    horizontalPadding: 24
    verticalPadding: 22
    sectionSpacing: 16

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
    property bool contextTargetsSelection: false
    property int contextSelectionCount: 0
    property real contextClickSceneX: 0
    property real contextClickSceneY: 0
    property real contextAnchorSceneX: 0
    property real contextAnchorSceneY: 0
    property real contextAnchorWidth: 0
    property real contextAnchorHeight: 0
    readonly property int contextMenuMargin: 12
    property var contextMenuActions: [
        { key: "open" },
        { key: "preview" },
        { key: "download" },
        { key: "delete", separatorBefore: true },
        { key: "clearSelection", separatorBefore: true }
    ]

    Component.onCompleted: {
        if (!root.driveVm.busy && root.driveVm.itemsModel.count === 0) {
            root.driveVm.refresh()
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
        var stats = root.driveVm.channelStats || {}
        return stats[key] !== undefined ? stats[key] : 0
    }

    function prepareContext(path, isDir, canPreview, canDownload, canDelete) {
        var selectedPaths = root.driveVm.selectedPaths || []
        var targetInSelection = selectedPaths.indexOf(path) >= 0
        contextTargetsSelection = targetInSelection && selectedPaths.length > 1
        contextSelectionCount = contextTargetsSelection ? selectedPaths.length : 1

        if (!targetInSelection) {
            root.driveVm.selectItem(path)
        }
        contextPath = path
        contextIsDir = isDir
        contextCanPreview = canPreview
        contextCanDownload = canDownload
        contextCanDelete = canDelete
    }

    function contextItemName() {
        if (root.contextPath.length === 0) {
            return ""
        }
        var normalizedPath = root.contextPath.replace(/\\/g, "/")
        var parts = normalizedPath.split("/")
        return parts.length > 0 ? parts[parts.length - 1] : root.contextPath
    }

    function contextMenuTitle() {
        if (root.contextTargetsSelection) {
            return "已选择 " + root.contextSelectionCount + " 项"
        }
        return root.contextItemName()
    }

    function contextMenuSubtitle() {
        if (root.contextTargetsSelection) {
            return "右键项位于当前选区内"
        }
        return root.contextIsDir ? "媒体组操作" : "文件操作"
    }

    function contextMenuWidth() {
        return contextMenuPopup.width > 0 ? contextMenuPopup.width : 224
    }

    function contextMenuHeight() {
        if (contextMenuPopup.implicitHeight > 0) {
            return contextMenuPopup.implicitHeight
        }
        return contextMenuPopup.contentItem
               ? contextMenuPopup.contentItem.implicitHeight + contextMenuPopup.topPadding + contextMenuPopup.bottomPadding
               : 260
    }

    function positionContextMenu() {
        var popupParent = contextMenuPopup.parent || root
        if (!popupParent || popupParent.width <= 0 || popupParent.height <= 0) {
            return
        }
        var menuWidth = root.contextMenuWidth()
        var menuHeight = root.contextMenuHeight()
        var margin = root.contextMenuMargin
        if (menuWidth <= 0 || menuHeight <= 0) {
            return
        }
        var anchorRight = root.contextAnchorSceneX + root.contextAnchorWidth
        var anchorBottom = root.contextAnchorSceneY + root.contextAnchorHeight
        var desiredX = root.contextClickSceneX + 8
        var desiredY = root.contextClickSceneY + 8

        if (desiredX + menuWidth > popupParent.width - margin) {
            desiredX = Math.max(root.contextAnchorSceneX, root.contextClickSceneX - menuWidth - 8)
        }
        if (desiredY + menuHeight > popupParent.height - margin) {
            desiredY = Math.max(root.contextAnchorSceneY, root.contextClickSceneY - menuHeight - 8)
        }

        var nearMinX = Math.max(margin, root.contextAnchorSceneX - menuWidth - margin)
        var nearMaxX = Math.min(popupParent.width - menuWidth - margin, anchorRight + margin)
        var nearMinY = Math.max(margin, root.contextAnchorSceneY - menuHeight - margin)
        var nearMaxY = Math.min(popupParent.height - menuHeight - margin, anchorBottom + margin)

        if (nearMaxX >= nearMinX) {
            desiredX = Math.max(nearMinX, Math.min(nearMaxX, desiredX))
        }
        if (nearMaxY >= nearMinY) {
            desiredY = Math.max(nearMinY, Math.min(nearMaxY, desiredY))
        }

        var maxX = Math.max(margin, popupParent.width - menuWidth - margin)
        var maxY = Math.max(margin, popupParent.height - menuHeight - margin)
        contextMenuPopup.x = Math.max(margin, Math.min(maxX, desiredX))
        contextMenuPopup.y = Math.max(margin, Math.min(maxY, desiredY))
    }

    function openContextMenu(path, isDir, canPreview, canDownload, canDelete, x, y, sourceItem) {
        if (!contextMenuPopup.parent) {
            contextMenuPopup.parent = root
        }
        var popupParent = contextMenuPopup.parent || root
        var clickPoint = sourceItem.mapToItem(popupParent, x, y)
        var anchorPoint = sourceItem.mapToItem(popupParent, 0, 0)
        contextClickSceneX = clickPoint.x
        contextClickSceneY = clickPoint.y
        contextAnchorSceneX = anchorPoint.x
        contextAnchorSceneY = anchorPoint.y
        contextAnchorWidth = sourceItem.width
        contextAnchorHeight = sourceItem.height

        prepareContext(path, isDir, canPreview, canDownload, canDelete)

        if (contextMenuPopup.opened) {
            contextMenuPopup.close()
        }

        contextMenuPopup.x = root.contextMenuMargin
        contextMenuPopup.y = root.contextMenuMargin
        contextMenuPopup.open()
        Qt.callLater(root.positionContextMenu)
        Qt.callLater(function() { root.positionContextMenu() })
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
            return root.contextTargetsSelection ? "打开选中项" : (root.contextIsDir ? "打开媒体组" : "打开")
        case "preview":
            return "预览"
        case "download":
            return root.contextTargetsSelection ? "下载 " + root.contextSelectionCount + " 项" : (root.contextIsDir ? "下载整组" : "下载")
        case "delete":
            return root.contextTargetsSelection ? "删除 " + root.contextSelectionCount + " 项" : (root.contextIsDir ? "删除媒体组" : "删除")
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
        case "open":
            return !root.contextTargetsSelection && root.contextPath.length > 0
        case "preview":
            return !root.contextTargetsSelection && root.contextCanPreview
        case "download":
            return root.contextTargetsSelection ? root.driveVm.batchDownloadEnabled : root.contextCanDownload
        case "delete":
            return root.contextTargetsSelection ? root.driveVm.batchDeleteEnabled : root.contextCanDelete
        case "clearSelection":
            return root.driveVm.hasSelection
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
            return pressed ? ThemeSystem.Theme.dangerSoft : (hovered ? ThemeSystem.Theme.dangerSoft : "transparent")
        }
        return pressed ? ThemeSystem.Theme.sidebarHoverFill : (hovered ? ThemeSystem.Theme.infoSoft : "transparent")
    }

    function contextMenuActionBorder(actionKey, hovered, pressed, enabled) {
        if (!enabled || (!hovered && !pressed)) {
            return "transparent"
        }
        if (root.contextMenuActionTone(actionKey) === "danger") {
            return ThemeSystem.Theme.cardBorderStrong
        }
        return ThemeSystem.Theme.cardBorderStrong
    }

    function triggerContextMenuAction(actionKey) {
        contextMenuPopup.close()
        switch (actionKey) {
        case "open":
            if (root.contextTargetsSelection) {
                root.driveVm.openSelection()
            } else {
                root.driveVm.activateItem(root.contextPath)
            }
            break
        case "preview":
            root.driveVm.openPreview(root.contextPath)
            break
        case "download":
            if (root.contextTargetsSelection) {
                root.driveVm.batchDownloadSelected()
            } else {
                root.driveVm.downloadItem(root.contextPath)
            }
            break
        case "delete":
            if (root.contextTargetsSelection) {
                root.driveVm.batchDeleteSelected()
            } else {
                root.driveVm.deleteItem(root.contextPath)
            }
            break
        case "clearSelection":
            root.driveVm.clearSelection()
            break
        default:
            break
        }
    }


    Popup {
        id: contextMenuPopup

        width: 224
        modal: false
        focus: true
        padding: 10
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
                x: 6
                y: 10
                width: Math.max(0, parent.width - 12)
                height: parent.height
                radius: parent.radius + 6
                color: ThemeSystem.Theme.shadowColorStrong
                opacity: 0.24
                z: -2
            }

            Rectangle {
                x: 3
                y: 5
                width: Math.max(0, parent.width - 6)
                height: Math.max(0, parent.height - 1)
                radius: parent.radius + 3
                color: ThemeSystem.Theme.shadowColor
                opacity: 0.32
                z: -1
            }

            Rectangle {
                anchors.fill: parent
                anchors.topMargin: 1
                radius: parent.radius
                color: "transparent"
                border.width: 1
                border.color: ThemeSystem.Theme.micaTint
                opacity: 0.28
            }
        }

        contentItem: ColumnLayout {
            spacing: 6

            ColumnLayout {
                Layout.fillWidth: true
                Layout.leftMargin: 6
                Layout.rightMargin: 6
                Layout.bottomMargin: 2
                spacing: 2

                Text {
                    Layout.fillWidth: true
                    text: root.contextMenuTitle()
                    color: ThemeSystem.Theme.textPrimary
                    font.pixelSize: 13
                    font.bold: true
                    maximumLineCount: 1
                    elide: Text.ElideRight
                    font.family: ThemeSystem.Theme.fontFamily
                }

                Text {
                    Layout.fillWidth: true
                    text: root.contextMenuSubtitle()
                    color: ThemeSystem.Theme.textTertiary
                    font.pixelSize: 11
                    maximumLineCount: 1
                    elide: Text.ElideMiddle
                    visible: text.length > 0
                    font.family: ThemeSystem.Theme.fontFamily
                }
            }

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
                        implicitHeight: 42
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

                            Rectangle {
                                width: 3
                                height: parent.height - 14
                                radius: 2
                                anchors.left: parent.left
                                anchors.leftMargin: 4
                                anchors.verticalCenter: parent.verticalCenter
                                visible: menuActionButton.enabled && menuActionButton.hovered
                                color: root.contextMenuActionTone(modelData.key) === "danger"
                                       ? ThemeSystem.Theme.colorDanger
                                       : ThemeSystem.Theme.colorPrimary
                            }

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
                                font.bold: menuActionButton.hovered && modelData.key === "delete"
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
                onTriggered: root.driveVm.toggleSelection(cardRoot.path)
            }

            MouseArea {
                id: fileCardMouseArea

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
                                             fileCardMouseArea)
                        return
                    }
                    clickTimer.restart()
                }

                onDoubleClicked: function(mouse) {
                    if (mouse.button !== Qt.LeftButton) {
                        return
                    }
                    clickTimer.stop()
                    root.driveVm.activateItem(cardRoot.path)
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
                onTriggered: root.driveVm.toggleSelection(rowRoot.path)
            }

            MouseArea {
                id: listRowMouseArea

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
                                             listRowMouseArea)
                        return
                    }
                    rowClickTimer.restart()
                }

                onDoubleClicked: function(mouse) {
                    if (mouse.button !== Qt.LeftButton) {
                        return
                    }
                    rowClickTimer.stop()
                    root.driveVm.activateItem(rowRoot.path)
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
                        onClicked: rowRoot.isDir ? root.driveVm.activateItem(rowRoot.path) : root.driveVm.openPreview(rowRoot.path)
                    }

                    DriveActionButton {
                        text: "下载"
                        iconName: "download"
                        tone: "neutral"
                        compact: true
                        onClicked: root.driveVm.downloadItem(rowRoot.path)
                    }
                }
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

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 10

                            DriveIconButton {
                                visible: root.driveVm.canNavigateUp
                                iconName: "back-up"
                                tone: "neutral"
                                toolTipText: "返回上级"
                                onClicked: root.driveVm.navigateUp()
                            }

                            ColumnLayout {
                                Layout.fillWidth: true
                                spacing: 4

                                Text {
                                    text: root.driveVm.workspaceTitle
                                    color: ThemeSystem.Theme.textPrimary
                                    font.pixelSize: 18
                                    font.bold: true
                                    font.family: ThemeSystem.Theme.fontFamily
                                }

                                Text {
                                    Layout.fillWidth: true
                                    text: root.driveVm.breadcrumbText
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
                                    active: root.driveVm.sidebarSection === modelData.key
                                    onClicked: root.driveVm.setSidebarSection(modelData.key)
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
                                    selected: root.driveVm.viewMode === "grid"
                                    onClicked: root.driveVm.setViewMode("grid")
                                }

                                DriveSegmentButton {
                                    Layout.fillWidth: true
                                    text: "列表"
                                    iconName: "list"
                                    selected: root.driveVm.viewMode === "list"
                                    onClicked: root.driveVm.setViewMode("list")
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
                                    if (root.sortOptions[i].value === root.driveVm.sortOption) {
                                        currentIndex = i
                                        break
                                    }
                                }
                            }

                            onActivated: root.driveVm.setSortOption(root.sortOptions[currentIndex].value)
                        }

                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: root.driveVm.filterSummary
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
                            text: root.driveVm.selectionSummary
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
                            enabled: root.driveVm.openEnabled
                            onClicked: root.driveVm.openSelection()
                        }

                        DriveActionButton {
                            text: "批量下载"
                            iconName: "download"
                            tone: "neutral"
                            compact: true
                            enabled: root.driveVm.batchDownloadEnabled
                            onClicked: root.driveVm.batchDownloadSelected()
                        }

                        DriveActionButton {
                            text: "批量删除"
                            iconName: "trash"
                            tone: "danger"
                            compact: true
                            enabled: root.driveVm.batchDeleteEnabled
                            onClicked: root.driveVm.batchDeleteSelected()
                        }

                        DriveActionButton {
                            text: "清除选择"
                            iconName: "clear"
                            tone: "warning"
                            compact: true
                            enabled: root.driveVm.hasSelection
                            onClicked: root.driveVm.clearSelection()
                        }
                    }
                }

                Rectangle {
                    Layout.fillWidth: true
                    radius: 20
                    color: "#ffffff"
                    border.width: 1
                    border.color: "#eef2f6"
                    implicitHeight: root.driveVm.itemsModel.count === 0
                                    ? 330
                                    : (root.driveVm.viewMode === "grid" ? gridFlow.implicitHeight + 88 : listColumn.implicitHeight + 88)

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
                            visible: root.driveVm.viewMode === "grid" && root.driveVm.itemsModel.count > 0

                            Repeater {
                                model: root.driveVm.itemsModel || []
                                delegate: fileCardDelegate
                            }
                        }

                        Column {
                            id: listColumn
                            width: parent.width
                            spacing: 10
                            visible: root.driveVm.viewMode === "list" && root.driveVm.itemsModel.count > 0

                            Repeater {
                                model: root.driveVm.itemsModel || []
                                delegate: listRowDelegate
                            }
                        }

                        Rectangle {
                            width: parent.width
                            height: 220
                            radius: 18
                            visible: root.driveVm.itemsModel.count === 0
                            color: "#f9fbfe"
                            border.width: 1
                            border.color: "#e7edf4"

                            Column {
                                anchors.centerIn: parent
                                width: Math.min(parent.width - 48, 420)
                                spacing: 8

                                Text {
                                    width: parent.width
                                    text: root.driveVm.emptyState
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
                                    text: root.driveVm.pageSummary
                                    color: ThemeSystem.Theme.textSecondary
                                    font.pixelSize: 12
                                    wrapMode: Text.WordWrap
                                    font.family: ThemeSystem.Theme.fontFamily
                                }

                                RowLayout {
                                    visible: !root.driveVm.canNavigateUp
                                    spacing: 8

                                    DriveActionButton {
                                        text: "上一页"
                                        tone: "neutral"
                                        compact: true
                                        enabled: root.driveVm.canPreviousPage
                                        onClicked: root.driveVm.previousPage()
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
                                            text: root.driveVm.currentPage + " / " + root.driveVm.totalPages
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
                                        enabled: root.driveVm.canNextPage
                                        onClicked: root.driveVm.nextPage()
                                    }
                                }

                                DriveComboBox {
                                    id: pageSizeCombo
                                    visible: !root.driveVm.canNavigateUp
                                    implicitWidth: 110
                                    model: root.pageSizeOptions

                                    Component.onCompleted: {
                                        currentIndex = Math.max(0, root.pageSizeOptions.indexOf(root.driveVm.pageSize))
                                    }

                                    Connections {
                                        target: driveViewModel || null
                                        ignoreUnknownSignals: true

                                        function onPaginationChanged() {
                                            pageSizeCombo.currentIndex = Math.max(0, root.pageSizeOptions.indexOf(root.driveVm.pageSize))
                                        }
                                    }

                                    onActivated: root.driveVm.setPageSize(root.pageSizeOptions[currentIndex])
                                }
                            }
                        }
                    }
                }
            }
        }

    }


