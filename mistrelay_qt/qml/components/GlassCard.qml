import QtQuick
import "../theme" as ThemeSystem

Rectangle {
    id: root

    default property alias contentData: contentRoot.data
    property int padding: ThemeSystem.Theme.cardPadding
    property color backgroundColor: ThemeSystem.Theme.cardBackground
    property color borderColor: ThemeSystem.Theme.cardBorder
    property real shadowOpacity: 0.12
    property int shadowOffsetY: 12
    property int shadowSpread: 22
    property color shadowColor: ThemeSystem.Theme.shadowColor

    radius: ThemeSystem.Theme.radiusXLarge
    color: backgroundColor
    border.width: 1
    border.color: borderColor
    antialiasing: true

    layer.enabled: true
    layer.smooth: true

    Rectangle {
        visible: root.shadowOpacity > 0
        x: root.shadowSpread / 2
        y: root.shadowOffsetY
        width: Math.max(0, parent.width - root.shadowSpread)
        height: parent.height
        radius: root.radius + 8
        color: root.shadowColor
        opacity: root.shadowOpacity
        z: -2
    }

    Rectangle {
        visible: root.shadowOpacity > 0
        x: root.shadowSpread / 4
        y: Math.max(4, root.shadowOffsetY / 2)
        width: Math.max(0, parent.width - root.shadowSpread / 2)
        height: Math.max(0, parent.height - 2)
        radius: root.radius + 4
        color: root.shadowColor
        opacity: root.shadowOpacity * 0.42
        z: -1
    }

    Rectangle {
        anchors.fill: parent
        anchors.topMargin: 1
        radius: root.radius
        color: "transparent"
        border.width: 1
        border.color: "#66ffffff"
        opacity: 0.28
    }

    Item {
        id: contentRoot
        anchors.fill: parent
        anchors.margins: root.padding
    }
}
