import QtQuick
import QtQuick.Controls
import "../theme" as ThemeSystem

Button {
    id: root

    property string tone: "neutral"

    function toneColor() {
        switch (tone) {
        case "danger":
            return ThemeSystem.Theme.colorDanger
        case "warning":
            return ThemeSystem.Theme.colorWarning
        case "success":
            return ThemeSystem.Theme.colorSuccess
        case "primary":
            return ThemeSystem.Theme.colorPrimary
        default:
            return ThemeSystem.Theme.textSecondary
        }
    }

    function toneFill(alphaValue) {
        var color = toneColor()
        return Qt.rgba(color.r, color.g, color.b, alphaValue)
    }

    implicitHeight: 34
    leftPadding: 14
    rightPadding: 14
    hoverEnabled: true

    font.family: ThemeSystem.Theme.fontFamily
    font.pixelSize: 13
    font.bold: true

    background: Rectangle {
        radius: height / 2
        color: !root.enabled
               ? "#f5f7fa"
               : root.down
                 ? root.toneFill(0.14)
                 : (root.hovered ? root.toneFill(0.08) : "transparent")
        border.width: 1
        border.color: !root.enabled
                      ? "#e5eaf1"
                      : (root.hovered || root.down ? root.toneFill(0.26) : "#d7e1ed")

        Behavior on color {
            ColorAnimation { duration: ThemeSystem.Theme.fastDuration }
        }
    }

    contentItem: Text {
        text: root.text
        font: root.font
        color: root.enabled ? root.toneColor() : ThemeSystem.Theme.textTertiary
        horizontalAlignment: Text.AlignHCenter
        verticalAlignment: Text.AlignVCenter
        elide: Text.ElideRight
    }
}
