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

    implicitHeight: ThemeSystem.Theme.controlHeight
    implicitWidth: 132
    leftPadding: 16
    rightPadding: 16
    hoverEnabled: true

    font.family: ThemeSystem.Theme.fontFamily
    font.pixelSize: 14
    font.bold: true

    background: Rectangle {
        radius: ThemeSystem.Theme.radiusMedium
        color: !root.enabled
               ? ThemeSystem.Theme.panelSurfaceSecondary
               : root.down
                 ? root.toneFill(root.tone === "neutral" ? 0.08 : 0.14)
                 : (root.hovered
                    ? root.toneFill(root.tone === "neutral" ? 0.05 : 0.10)
                    : "#ffffff")
        border.width: 1
        border.color: !root.enabled
                      ? ThemeSystem.Theme.cardBorder
                      : (root.hovered || root.down
                         ? root.toneFill(root.tone === "neutral" ? 0.18 : 0.30)
                         : ThemeSystem.Theme.cardBorder)

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
