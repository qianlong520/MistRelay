import QtQuick
import QtQuick.Controls
import "../theme" as ThemeSystem

Button {
    id: root

    property string iconName: ""
    property string tone: "primary"
    property bool active: false
    property bool spinning: false
    property string toolTipText: ""

    function accentColor() {
        switch (tone) {
        case "danger":
            return ThemeSystem.Theme.colorDanger
        case "warning":
            return ThemeSystem.Theme.colorWarning
        case "success":
            return ThemeSystem.Theme.colorSuccess
        case "info":
            return ThemeSystem.Theme.colorInfo
        case "neutral":
            return ThemeSystem.Theme.textPrimary
        default:
            return ThemeSystem.Theme.colorPrimary
        }
    }

    function accentFill(alphaValue) {
        var color = accentColor()
        return Qt.rgba(color.r, color.g, color.b, alphaValue)
    }

    implicitWidth: 40
    implicitHeight: 40
    leftPadding: 0
    rightPadding: 0
    hoverEnabled: true

    ToolTip.visible: toolTipText.length > 0 && hovered
    ToolTip.text: toolTipText
    ToolTip.delay: 250

    background: Rectangle {
        radius: 14
        color: !root.enabled
               ? "#f3f6fa"
               : root.down
                 ? root.accentFill(root.active ? 0.24 : 0.18)
                 : root.hovered
                   ? root.accentFill(root.active ? 0.18 : 0.10)
                   : (root.active ? root.accentFill(0.12) : "#ffffff")
        border.width: 1
        border.color: !root.enabled
                      ? "#dfe7f0"
                      : root.accentFill(root.active ? 0.32 : (root.hovered || root.down ? 0.28 : 0.18))

        Behavior on color {
            ColorAnimation { duration: ThemeSystem.Theme.fastDuration }
        }
    }

    contentItem: Item {
        FluentNavIcon {
            id: iconGlyph
            anchors.centerIn: parent
            iconName: root.iconName
            iconColor: root.enabled ? root.accentColor() : ThemeSystem.Theme.textTertiary
            iconSize: 18

            NumberAnimation on rotation {
                running: root.spinning
                loops: Animation.Infinite
                from: 0
                to: 360
                duration: 900
            }
        }
    }
}
