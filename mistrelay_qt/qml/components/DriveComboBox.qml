import QtQuick
import QtQuick.Controls
import "../theme" as ThemeSystem

ComboBox {
    id: root

    function displayLabel(value) {
        if (value === undefined || value === null) {
            return ""
        }
        if (root.textRole && typeof value === "object") {
            return value[root.textRole] || ""
        }
        return String(value)
    }

    implicitHeight: 38
    implicitWidth: 168
    hoverEnabled: true

    font.family: ThemeSystem.Theme.fontFamily
    font.pixelSize: 13

    delegate: ItemDelegate {
        required property int index
        required property var modelData

        width: ListView.view ? ListView.view.width : root.width
        height: 36
        highlighted: root.highlightedIndex === index

        background: Rectangle {
            radius: 10
            color: parent.highlighted ? "#eef5ff" : (parent.hovered ? "#f7faff" : "transparent")
        }

        contentItem: Text {
            text: root.displayLabel(modelData)
            color: ThemeSystem.Theme.textPrimary
            font.family: ThemeSystem.Theme.fontFamily
            font.pixelSize: 13
            verticalAlignment: Text.AlignVCenter
            elide: Text.ElideRight
        }
    }

    contentItem: Text {
        leftPadding: 14
        rightPadding: 34
        text: root.displayText
        color: ThemeSystem.Theme.textPrimary
        font: root.font
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }

    indicator: Item {
        x: root.width - width - 12
        y: (root.height - height) / 2
        width: 16
        height: 16

        FluentNavIcon {
            anchors.centerIn: parent
            iconName: "chevron-down"
            iconColor: ThemeSystem.Theme.textSecondary
            iconSize: 14
            rotation: root.popup.visible ? 180 : 0

            Behavior on rotation {
                NumberAnimation { duration: ThemeSystem.Theme.fastDuration }
            }
        }
    }

    background: Rectangle {
        radius: 13
        color: !root.enabled
               ? "#f5f7fa"
               : root.pressed
                 ? "#f6faff"
                 : (root.hovered ? "#fbfdff" : "#ffffff")
        border.width: 1
        border.color: root.popup.visible ? "#9dc3f7" : "#d6e1ed"

        Behavior on color {
            ColorAnimation { duration: ThemeSystem.Theme.fastDuration }
        }
    }

    popup: Popup {
        y: root.height + 6
        width: root.width
        padding: 6

        background: Rectangle {
            radius: 14
            color: "#fcfdff"
            border.width: 1
            border.color: ThemeSystem.Theme.cardBorder
        }

        contentItem: ListView {
            clip: true
            implicitHeight: contentHeight
            model: root.delegateModel
            currentIndex: root.highlightedIndex
        }
    }
}
