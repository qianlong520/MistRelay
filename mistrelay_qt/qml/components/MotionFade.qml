import QtQuick
import "../theme" as ThemeSystem

Item {
    id: root

    default property alias contentData: contentRoot.data
    property bool shown: true
    property real travelY: 10

    opacity: shown ? 1 : 0
    y: shown ? 0 : travelY

    Behavior on opacity {
        NumberAnimation { duration: ThemeSystem.Theme.mediumDuration }
    }

    Behavior on y {
        NumberAnimation { duration: ThemeSystem.Theme.mediumDuration }
    }

    Item {
        id: contentRoot
        anchors.fill: parent
    }
}
