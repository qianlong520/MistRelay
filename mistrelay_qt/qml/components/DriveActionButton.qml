import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme" as ThemeSystem

Button {
    id: root

    property string iconName: ""
    property string tone: "neutral"
    property bool active: false
    property bool compact: false

    function accentColor() {
        switch (tone) {
        case "danger":
            return ThemeSystem.Theme.colorDanger
        case "warning":
            return ThemeSystem.Theme.colorWarning
        case "success":
            return ThemeSystem.Theme.colorSuccess
        case "primary":
            return ThemeSystem.Theme.colorPrimary
        case "info":
            return ThemeSystem.Theme.colorInfo
        default:
            return ThemeSystem.Theme.textSecondary
        }
    }

    function accentFill(alphaValue) {
        var color = accentColor()
        return Qt.rgba(color.r, color.g, color.b, alphaValue)
    }

    function resolvedBackground() {
        if (!enabled) {
            return active ? "#edf2f8" : "#f4f7fa"
        }
        if (tone === "neutral") {
            if (down) {
                return active ? "#e7f0fd" : "#eef3f7"
            }
            if (hovered) {
                return active ? "#edf5ff" : "#f8fbfd"
            }
            return active ? "#edf5ff" : "#ffffff"
        }
        if (down) {
            return accentFill(active ? 0.22 : 0.16)
        }
        if (hovered) {
            return accentFill(active ? 0.16 : 0.10)
        }
        return active ? accentFill(0.12) : "#ffffff"
    }

    function resolvedBorder() {
        if (!enabled) {
            return "#e1e8f0"
        }
        if (tone === "neutral") {
            return active ? "#bdd6fb" : "#d7e1ed"
        }
        return accentFill(active ? 0.34 : (hovered || down ? 0.30 : 0.22))
    }

    function resolvedForeground() {
        if (!enabled) {
            return ThemeSystem.Theme.textTertiary
        }
        if (tone === "neutral") {
            return active ? ThemeSystem.Theme.colorPrimary : ThemeSystem.Theme.textPrimary
        }
        return accentColor()
    }

    implicitHeight: compact ? 34 : 38
    implicitWidth: contentRow.implicitWidth + (iconName.length > 0 ? 30 : 26)
    leftPadding: 0
    rightPadding: 0
    hoverEnabled: true

    font.family: ThemeSystem.Theme.fontFamily
    font.pixelSize: compact ? 12 : 13
    font.bold: true

    background: Rectangle {
        radius: root.compact ? 11 : 13
        color: root.resolvedBackground()
        border.width: 1
        border.color: root.resolvedBorder()

        Behavior on color {
            ColorAnimation { duration: ThemeSystem.Theme.fastDuration }
        }
    }

    contentItem: Item {
        implicitWidth: contentRow.implicitWidth
        implicitHeight: contentRow.implicitHeight

        RowLayout {
            id: contentRow
            anchors.centerIn: parent
            spacing: root.compact ? 6 : 8

            FluentNavIcon {
                visible: root.iconName.length > 0
                iconName: root.iconName
                iconColor: root.resolvedForeground()
                iconSize: root.compact ? 14 : 16
                Layout.alignment: Qt.AlignVCenter
            }

            Text {
                visible: root.text.length > 0
                text: root.text
                color: root.resolvedForeground()
                font: root.font
                elide: Text.ElideRight
                horizontalAlignment: Text.AlignHCenter
                verticalAlignment: Text.AlignVCenter
                Layout.alignment: Qt.AlignVCenter
            }
        }
    }
}
