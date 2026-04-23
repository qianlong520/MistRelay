pragma ComponentBehavior: Bound

import QtQuick
import "../theme" as ThemeSystem

Item {
    id: root

    property string iconName: ""
    property color iconColor: ThemeSystem.Theme.sidebarTextMuted
    property real iconSize: 18
    property real strokeWidth: Math.max(1.4, iconSize * 0.1)

    implicitWidth: iconSize
    implicitHeight: iconSize
    width: iconSize
    height: iconSize

    Item {
        anchors.fill: parent
        visible: root.iconName === "home"

        Rectangle {
            x: root.width * 0.20
            y: root.height * 0.18
            width: root.width * 0.60
            height: root.width * 0.60
            rotation: 45
            radius: root.width * 0.08
            color: root.iconColor
            transformOrigin: Item.Center
        }

        Rectangle {
            x: root.width * 0.22
            y: root.height * 0.44
            width: root.width * 0.56
            height: root.height * 0.34
            radius: root.width * 0.08
            color: root.iconColor
        }

        Rectangle {
            x: root.width * 0.44
            y: root.height * 0.52
            width: root.width * 0.14
            height: root.height * 0.26
            radius: root.width * 0.05
            color: "#ffffff"
            opacity: 0.22
        }
    }

    Item {
        anchors.fill: parent
        visible: root.iconName === "dashboard"

        Repeater {
            model: [
                { "x": 0.06, "y": 0.06 },
                { "x": 0.56, "y": 0.06 },
                { "x": 0.06, "y": 0.56 },
                { "x": 0.56, "y": 0.56 }
            ]

            delegate: Rectangle {
                required property var modelData
                required property int index

                x: modelData.x * root.width
                y: modelData.y * root.height
                width: root.width * 0.38
                height: root.height * 0.38
                radius: width * 0.26
                color: root.iconColor
                opacity: index === 0 ? 1.0 : 0.92
            }
        }
    }

    Item {
        anchors.fill: parent
        visible: root.iconName === "downloads"

        Repeater {
            model: 3

            delegate: Item {
                id: taskRow

                required property int index

                readonly property real rowTop: root.height * (0.14 + taskRow.index * 0.29)

                Rectangle {
                    x: root.width * 0.04
                    y: parent.rowTop
                    width: root.width * 0.18
                    height: root.height * 0.18
                    radius: height * 0.5
                    color: root.iconColor
                    opacity: 0.96
                }

                Rectangle {
                    x: root.width * 0.30
                    y: parent.rowTop + root.height * 0.02
                    width: root.width * 0.60
                    height: root.strokeWidth
                    radius: height * 0.5
                    color: root.iconColor
                }

                Rectangle {
                    x: root.width * 0.30
                    y: parent.rowTop + root.height * 0.12
                    width: root.width * (taskRow.index === 1 ? 0.42 : 0.52)
                    height: root.strokeWidth
                    radius: height * 0.5
                    color: root.iconColor
                    opacity: 0.72
                }
            }
        }
    }

    Item {
        anchors.fill: parent
        visible: root.iconName === "drive"

        Rectangle {
            x: root.width * 0.08
            y: root.height * 0.28
            width: root.width * 0.84
            height: root.height * 0.52
            radius: root.width * 0.16
            color: root.iconColor
        }

        Rectangle {
            x: root.width * 0.14
            y: root.height * 0.14
            width: root.width * 0.34
            height: root.height * 0.22
            radius: root.width * 0.12
            color: root.iconColor
        }

        Rectangle {
            x: root.width * 0.12
            y: root.height * 0.38
            width: root.width * 0.76
            height: root.strokeWidth
            radius: height * 0.5
            color: "#ffffff"
            opacity: 0.28
        }
    }

    Item {
        anchors.fill: parent
        visible: root.iconName === "settings"

        Repeater {
            model: [
                { "y": 0.22, "knob": 0.66 },
                { "y": 0.50, "knob": 0.34 },
                { "y": 0.78, "knob": 0.58 }
            ]

            delegate: Item {
                required property var modelData
                id: sliderRow

                Rectangle {
                    x: root.width * 0.10
                    y: sliderRow.modelData.y * root.height
                    width: root.width * 0.80
                    height: root.strokeWidth
                    radius: height * 0.5
                    color: root.iconColor
                }

                Rectangle {
                    x: sliderRow.modelData.knob * root.width - width * 0.5
                    y: sliderRow.modelData.y * root.height - height * 0.5 + root.strokeWidth * 0.5
                    width: root.width * 0.20
                    height: root.width * 0.20
                    radius: width * 0.5
                    color: root.iconColor
                }
            }
        }
    }

    Item {
        anchors.fill: parent
        visible: root.iconName === "logout"

        Rectangle {
            x: root.width * 0.14
            y: root.height * 0.20
            width: root.width * 0.18
            height: root.height * 0.60
            radius: root.width * 0.08
            color: root.iconColor
            opacity: 0.9
        }

        Rectangle {
            x: root.width * 0.22
            y: root.height * 0.46
            width: root.width * 0.46
            height: root.strokeWidth
            radius: height * 0.5
            color: root.iconColor
        }

        Rectangle {
            x: root.width * 0.52
            y: root.height * 0.32
            width: root.strokeWidth
            height: root.height * 0.18
            rotation: -45
            radius: width * 0.5
            color: root.iconColor
            transformOrigin: Item.Top
        }

        Rectangle {
            x: root.width * 0.52
            y: root.height * 0.50
            width: root.strokeWidth
            height: root.height * 0.18
            rotation: 45
            radius: width * 0.5
            color: root.iconColor
            transformOrigin: Item.Bottom
        }
    }

    Item {
        anchors.fill: parent
        visible: root.iconName === "refresh"

        Rectangle {
            x: root.width * 0.20
            y: root.height * 0.18
            width: root.width * 0.58
            height: root.height * 0.58
            radius: width * 0.5
            color: "transparent"
            border.width: root.strokeWidth
            border.color: root.iconColor
            opacity: 0.92
        }

        Rectangle {
            x: root.width * 0.54
            y: root.height * 0.08
            width: root.strokeWidth
            height: root.height * 0.22
            rotation: -42
            radius: width * 0.5
            color: root.iconColor
        }

        Rectangle {
            x: root.width * 0.64
            y: root.height * 0.16
            width: root.strokeWidth
            height: root.height * 0.22
            rotation: 46
            radius: width * 0.5
            color: root.iconColor
        }

        Rectangle {
            x: root.width * 0.24
            y: root.height * 0.70
            width: root.strokeWidth
            height: root.height * 0.20
            rotation: -42
            radius: width * 0.5
            color: root.iconColor
        }

        Rectangle {
            x: root.width * 0.15
            y: root.height * 0.60
            width: root.strokeWidth
            height: root.height * 0.20
            rotation: 46
            radius: width * 0.5
            color: root.iconColor
        }
    }

    Item {
        anchors.fill: parent
        visible: root.iconName === "back-up"

        Rectangle {
            x: root.width * 0.22
            y: root.height * 0.24
            width: root.strokeWidth
            height: root.height * 0.34
            rotation: 45
            radius: width * 0.5
            color: root.iconColor
            transformOrigin: Item.Bottom
        }

        Rectangle {
            x: root.width * 0.22
            y: root.height * 0.48
            width: root.strokeWidth
            height: root.height * 0.34
            rotation: -45
            radius: width * 0.5
            color: root.iconColor
            transformOrigin: Item.Top
        }

        Rectangle {
            x: root.width * 0.26
            y: root.height * 0.50 - root.strokeWidth / 2
            width: root.width * 0.42
            height: root.strokeWidth
            radius: height * 0.5
            color: root.iconColor
        }

        Rectangle {
            x: root.width * 0.54
            y: root.height * 0.22
            width: root.strokeWidth
            height: root.height * 0.32
            radius: width * 0.5
            color: root.iconColor
        }
    }

    Item {
        anchors.fill: parent
        visible: root.iconName === "grid"

        Repeater {
            model: [
                { "x": 0.12, "y": 0.12 },
                { "x": 0.55, "y": 0.12 },
                { "x": 0.12, "y": 0.55 },
                { "x": 0.55, "y": 0.55 }
            ]

            delegate: Rectangle {
                required property var modelData

                x: modelData.x * root.width
                y: modelData.y * root.height
                width: root.width * 0.30
                height: root.height * 0.30
                radius: root.width * 0.08
                color: root.iconColor
            }
        }
    }

    Item {
        anchors.fill: parent
        visible: root.iconName === "list"

        Repeater {
            model: 3

            delegate: Item {
                required property int index

                readonly property real rowY: root.height * (0.20 + index * 0.30)

                Rectangle {
                    x: root.width * 0.12
                    y: parent.rowY
                    width: root.width * 0.16
                    height: root.strokeWidth * 1.15
                    radius: height * 0.5
                    color: root.iconColor
                }

                Rectangle {
                    x: root.width * 0.36
                    y: parent.rowY
                    width: root.width * 0.52
                    height: root.strokeWidth * 1.15
                    radius: height * 0.5
                    color: root.iconColor
                }
            }
        }
    }

    Item {
        anchors.fill: parent
        visible: root.iconName === "detail"

        Rectangle {
            x: root.width * 0.16
            y: root.height * 0.14
            width: root.width * 0.68
            height: root.height * 0.72
            radius: root.width * 0.10
            color: "transparent"
            border.width: root.strokeWidth
            border.color: root.iconColor
        }

        Repeater {
            model: [
                { "y": 0.34, "w": 0.42 },
                { "y": 0.50, "w": 0.50 },
                { "y": 0.66, "w": 0.34 }
            ]

            delegate: Rectangle {
                required property var modelData

                x: root.width * 0.28
                y: root.height * modelData.y
                width: root.width * modelData.w
                height: root.strokeWidth
                radius: height * 0.5
                color: root.iconColor
            }
        }
    }

    Item {
        anchors.fill: parent
        visible: root.iconName === "open"

        Rectangle {
            x: root.width * 0.16
            y: root.height * 0.30
            width: root.width * 0.68
            height: root.height * 0.46
            radius: root.width * 0.10
            color: "transparent"
            border.width: root.strokeWidth
            border.color: root.iconColor
        }

        Rectangle {
            x: root.width * 0.30
            y: root.height * 0.18
            width: root.strokeWidth
            height: root.height * 0.34
            rotation: -45
            radius: width * 0.5
            color: root.iconColor
            transformOrigin: Item.Top
        }

        Rectangle {
            x: root.width * 0.44
            y: root.height * 0.18
            width: root.strokeWidth
            height: root.height * 0.22
            radius: width * 0.5
            color: root.iconColor
        }

        Rectangle {
            x: root.width * 0.42
            y: root.height * 0.18
            width: root.width * 0.24
            height: root.strokeWidth
            radius: height * 0.5
            color: root.iconColor
        }
    }

    Item {
        anchors.fill: parent
        visible: root.iconName === "download"

        Rectangle {
            x: root.width * 0.50 - root.strokeWidth / 2
            y: root.height * 0.12
            width: root.strokeWidth
            height: root.height * 0.46
            radius: width * 0.5
            color: root.iconColor
        }

        Rectangle {
            x: root.width * 0.38
            y: root.height * 0.45
            width: root.strokeWidth
            height: root.height * 0.20
            rotation: -45
            radius: width * 0.5
            color: root.iconColor
            transformOrigin: Item.Top
        }

        Rectangle {
            x: root.width * 0.62
            y: root.height * 0.45
            width: root.strokeWidth
            height: root.height * 0.20
            rotation: 45
            radius: width * 0.5
            color: root.iconColor
            transformOrigin: Item.Top
        }

        Rectangle {
            x: root.width * 0.18
            y: root.height * 0.76
            width: root.width * 0.64
            height: root.strokeWidth
            radius: height * 0.5
            color: root.iconColor
        }
    }

    Item {
        anchors.fill: parent
        visible: root.iconName === "trash"

        Rectangle {
            x: root.width * 0.26
            y: root.height * 0.32
            width: root.width * 0.48
            height: root.height * 0.50
            radius: root.width * 0.08
            color: "transparent"
            border.width: root.strokeWidth
            border.color: root.iconColor
        }

        Rectangle {
            x: root.width * 0.22
            y: root.height * 0.22
            width: root.width * 0.56
            height: root.strokeWidth
            radius: height * 0.5
            color: root.iconColor
        }

        Rectangle {
            x: root.width * 0.40
            y: root.height * 0.14
            width: root.width * 0.20
            height: root.strokeWidth
            radius: height * 0.5
            color: root.iconColor
        }
    }

    Item {
        anchors.fill: parent
        visible: root.iconName === "clear"

        Rectangle {
            x: root.width * 0.20
            y: root.height * 0.20
            width: root.strokeWidth
            height: root.height * 0.68
            rotation: -45
            radius: width * 0.5
            color: root.iconColor
        }

        Rectangle {
            x: root.width * 0.20
            y: root.height * 0.68
            width: root.strokeWidth
            height: root.height * 0.68
            rotation: -135
            radius: width * 0.5
            color: root.iconColor
        }
    }

    Item {
        anchors.fill: parent
        visible: root.iconName === "eye"

        Rectangle {
            x: root.width * 0.12
            y: root.height * 0.34
            width: root.width * 0.76
            height: root.height * 0.32
            radius: height * 0.5
            color: "transparent"
            border.width: root.strokeWidth
            border.color: root.iconColor
        }

        Rectangle {
            anchors.centerIn: parent
            width: root.width * 0.20
            height: width
            radius: width * 0.5
            color: root.iconColor
        }
    }

    Item {
        anchors.fill: parent
        visible: root.iconName === "close"

        Rectangle {
            x: root.width * 0.24
            y: root.height * 0.18
            width: root.strokeWidth
            height: root.height * 0.64
            rotation: -45
            radius: width * 0.5
            color: root.iconColor
        }

        Rectangle {
            x: root.width * 0.24
            y: root.height * 0.64
            width: root.strokeWidth
            height: root.height * 0.64
            rotation: -135
            radius: width * 0.5
            color: root.iconColor
        }
    }

    Item {
        anchors.fill: parent
        visible: root.iconName === "chevron-down"

        Rectangle {
            x: root.width * 0.27
            y: root.height * 0.38
            width: root.strokeWidth
            height: root.height * 0.26
            rotation: -45
            radius: width * 0.5
            color: root.iconColor
            transformOrigin: Item.Bottom
        }

        Rectangle {
            x: root.width * 0.62
            y: root.height * 0.38
            width: root.strokeWidth
            height: root.height * 0.26
            rotation: 45
            radius: width * 0.5
            color: root.iconColor
            transformOrigin: Item.Bottom
        }
    }
}
