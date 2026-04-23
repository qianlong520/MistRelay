import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import "../theme" as ThemeSystem

Item {
    id: root

    property var options: []
    property string currentValue: ""
    property int controlHeight: 36
    property int horizontalPadding: 16
    property int gap: 8
    property color activeFill: "#eaf2ff"
    property color activeBorder: "#bcd1ff"
    property color activeText: ThemeSystem.Theme.colorPrimary
    property color inactiveFill: "#f5f8fc"
    property color inactiveBorder: "#e0e7f0"
    property color inactiveText: ThemeSystem.Theme.textSecondary

    signal valueSelected(string value)

    implicitWidth: buttonFlow.implicitWidth
    implicitHeight: buttonFlow.implicitHeight

    Flow {
        id: buttonFlow

        anchors.fill: parent
        width: root.width > 0 ? root.width : implicitWidth
        spacing: root.gap

        Repeater {
            model: root.options

            delegate: Button {
                id: controlButton
                required property var modelData

                readonly property bool active: root.currentValue === modelData.value

                text: modelData.label
                implicitHeight: root.controlHeight
                leftPadding: root.horizontalPadding
                rightPadding: root.horizontalPadding
                hoverEnabled: true

                onClicked: root.valueSelected(modelData.value)

                background: Rectangle {
                    radius: height / 2
                    color: active ? root.activeFill : (controlButton.hovered ? "#edf3fb" : root.inactiveFill)
                    border.width: 1
                    border.color: active ? root.activeBorder : root.inactiveBorder

                    Behavior on color {
                        ColorAnimation { duration: ThemeSystem.Theme.fastDuration }
                    }
                }

                contentItem: Text {
                    text: controlButton.text
                    color: active ? root.activeText : root.inactiveText
                    horizontalAlignment: Text.AlignHCenter
                    verticalAlignment: Text.AlignVCenter
                    font.pixelSize: 13
                    font.bold: active
                    font.family: ThemeSystem.Theme.fontFamily
                }
            }
        }
    }
}
