import QtQuick
import QtQuick.Layouts
import "../theme" as ThemeSystem

Flickable {
    id: root

    default property alias contentData: contentColumn.data

    property real pageMaxWidth: ThemeSystem.Theme.pageContentMaxWidth
    property real horizontalPadding: ThemeSystem.Theme.pagePadding
    property real verticalPadding: ThemeSystem.Theme.pagePadding
    property real sectionSpacing: ThemeSystem.Theme.pageSectionGap
    property real headerRevealProgress: 1.0
    property real headerRevealDistance: 76
    property real lastTrackedContentY: 0

    readonly property real frameWidth: Math.max(0, width - horizontalPadding * 2)
    readonly property real contentFrameWidth: Math.min(pageMaxWidth, frameWidth)
    readonly property bool compact: contentFrameWidth < ThemeSystem.Theme.compactBreakpoint
    readonly property bool wide: contentFrameWidth >= ThemeSystem.Theme.wideBreakpoint

    clip: true
    boundsBehavior: Flickable.StopAtBounds
    contentWidth: width
    contentHeight: contentColumn.implicitHeight + verticalPadding * 2

    function resetHeaderReveal() {
        headerRevealProgress = 1.0
        lastTrackedContentY = contentY
    }

    onVisibleChanged: {
        if (visible) {
            resetHeaderReveal()
        }
    }

    onContentYChanged: {
        var delta = contentY - lastTrackedContentY
        lastTrackedContentY = contentY

        if (contentY <= 0.5) {
            headerRevealProgress = 1.0
            return
        }

        if (Math.abs(delta) < 0.5) {
            return
        }

        headerRevealProgress = Math.max(0.0, Math.min(1.0, headerRevealProgress - delta / headerRevealDistance))
    }

    ColumnLayout {
        id: contentColumn

        x: root.horizontalPadding + Math.max(0, (root.frameWidth - width) / 2)
        y: root.verticalPadding
        width: root.contentFrameWidth
        spacing: root.sectionSpacing
    }
}
