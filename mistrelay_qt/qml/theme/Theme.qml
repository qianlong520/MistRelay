pragma Singleton

import QtQuick

QtObject {
    readonly property bool fluentEnabled: true

    readonly property color colorPrimary: "#0f6cbd"
    readonly property color colorPrimaryDark: "#0c5da5"
    readonly property color colorPrimaryLight: "#4997d0"
    readonly property color colorPrimaryHover: "#115ea3"
    readonly property color colorPrimaryPressed: "#0e4775"
    readonly property color colorSuccess: "#107c10"
    readonly property color colorWarning: "#0284c7"
    readonly property color colorDanger: "#d13438"
    readonly property color colorInfo: "#0078d4"

    readonly property color textPrimary: "#1b1b1f"
    readonly property color textSecondary: "#44474f"
    readonly property color textTertiary: "#6b7280"
    readonly property color textOnAccent: "#ffffff"

    readonly property color surface: "#f5f7fb"
    readonly property color surfaceAlt: "#eff3f8"
    readonly property color panelSurface: "#fbfdff"
    readonly property color panelSurfaceSecondary: "#f7f9fc"
    readonly property color surfaceMuted: "#e9eef5"
    readonly property color micaBase: "#f3f6fb"
    readonly property color micaTint: "#ffffff"
    readonly property color micaTintStrong: "#f8fbff"
    readonly property color acrylicFill: "#f8fbffeb"
    readonly property color acrylicDarkFill: "#10233aee"

    readonly property color glassBg: acrylicFill
    readonly property color glassBorder: "#d8e3f0"
    readonly property color cardBackground: "#fbfdff"
    readonly property color cardBackgroundAlt: "#f6f9fd"
    readonly property color cardBorder: "#d6e0ec"
    readonly property color cardBorderStrong: "#c6d3e3"
    readonly property color lineColor: "#d0d8e5"
    readonly property color lineColorStrong: "#bcc7d6"

    readonly property color sidebarStart: "#f8fbff"
    readonly property color sidebarEnd: "#eef3f9"
    readonly property color sidebarBorder: "#d7e1ed"
    readonly property color sidebarActiveFill: "#dcecff"
    readonly property color sidebarHoverFill: "#ebf3fb"
    readonly property color sidebarText: "#243447"
    readonly property color sidebarTextMuted: "#5c6b7c"

    readonly property color successSoft: "#ecf6ec"
    readonly property color infoSoft: "#eef6fc"
    readonly property color warningSoft: "#eaf7ff"
    readonly property color dangerSoft: "#fde7e9"

    readonly property color shadowColor: "#14243a26"
    readonly property color shadowColorStrong: "#12233a38"
    readonly property color overlayScrim: "#4a1f2937"

    readonly property int radiusSmall: 8
    readonly property int radiusMedium: 12
    readonly property int radiusLarge: 18
    readonly property int radiusXLarge: 24
    readonly property int pagePadding: 28
    readonly property int pageCompactGap: 16
    readonly property int pageSectionGap: 22
    readonly property int compactBreakpoint: 960
    readonly property int wideBreakpoint: 1320
    readonly property int pageContentMaxWidth: 1400
    readonly property int cardPadding: 24
    readonly property int controlHeight: 40
    readonly property int controlHeightLarge: 46
    readonly property int sectionSpacing: 20
    readonly property int navItemHeight: 54
    readonly property int navGlyphBox: 34
    readonly property int navGlyphSize: 18
    readonly property int navTextSize: 16
    readonly property int headerIconBox: 38
    readonly property int headerIconSize: 18
    readonly property int fastDuration: 120
    readonly property int mediumDuration: 180
    readonly property int slowDuration: 260
    readonly property string fontFamily: "Segoe UI Variable"
    readonly property string fallbackFontFamily: "Segoe UI"

    function elevation(opacity, strongOpacity) {
        return {
            "shadowOpacity": opacity,
            "shadowOffsetY": 14,
            "shadowSpread": 24,
            "shadowColor": strongOpacity ? shadowColorStrong : shadowColor
        }
    }
}
