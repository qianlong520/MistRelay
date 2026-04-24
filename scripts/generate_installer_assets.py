from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

from PySide6.QtCore import QRect, QRectF, Qt
from PySide6.QtGui import QColor, QFont, QFontDatabase, QGuiApplication, QImage, QLinearGradient, QPainter


WELCOME_SIZE = (164, 314)
HEADER_SIZE = (150, 57)
FONT_FALLBACKS = ("Microsoft YaHei UI", "Microsoft YaHei", "SimHei", "Segoe UI")
WINDOWS_FONT_PATHS = (
    Path(r"C:\Windows\Fonts\msyh.ttc"),
    Path(r"C:\Windows\Fonts\msyhbd.ttc"),
    Path(r"C:\Windows\Fonts\msyhl.ttc"),
    Path(r"C:\Windows\Fonts\simhei.ttf"),
    Path(r"C:\Windows\Fonts\simsun.ttc"),
    Path(r"C:\Windows\Fonts\NotoSansSC-VF.ttf"),
)
TEXT_DESKTOP_CLIENT = "\u684c\u9762\u5ba2\u6237\u7aef"
TEXT_INSTALL_WIZARD = "\u5b89\u88c5\u5411\u5bfc"
TEXT_LIGHT_SECURE_AUTO_UPDATE = "\u8f7b\u91cf\u3001\u5b89\u5168\u3001\u81ea\u52a8\u66f4\u65b0"
_REGISTERED_FONT_FAMILY = ""


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate MistRelay NSIS installer artwork")
    parser.add_argument("--icon", required=True, type=Path, help="Path to the source PNG icon")
    parser.add_argument("--output-dir", required=True, type=Path, help="Directory for generated BMP assets")
    parser.add_argument("--product-name", default="MistRelay", help="Product name shown in installer artwork")
    return parser.parse_args()


def _register_chinese_fonts() -> None:
    global _REGISTERED_FONT_FAMILY
    if _REGISTERED_FONT_FAMILY:
        return
    for font_path in WINDOWS_FONT_PATHS:
        if not font_path.exists():
            continue
        font_id = QFontDatabase.addApplicationFont(str(font_path))
        if font_id < 0:
            continue
        families = QFontDatabase.applicationFontFamilies(font_id)
        if families:
            _REGISTERED_FONT_FAMILY = families[0]
            return


def _font_family() -> str:
    _register_chinese_fonts()
    if _REGISTERED_FONT_FAMILY:
        return _REGISTERED_FONT_FAMILY
    available_families = set(QFontDatabase.families())
    for family in FONT_FALLBACKS:
        if family in available_families:
            return family
    return FONT_FALLBACKS[-1]


def _font(point_size: int, *, bold: bool = False) -> QFont:
    font = QFont(_font_family())
    font.setPointSize(point_size)
    font.setBold(bold)
    return font


def _scaled_icon(icon_path: Path, size: int) -> QImage:
    icon = QImage(str(icon_path))
    if icon.isNull():
        raise SystemExit(f"failed to read icon: {icon_path}")
    return icon.scaled(
        size,
        size,
        Qt.AspectRatioMode.KeepAspectRatio,
        Qt.TransformationMode.SmoothTransformation,
    )


def _draw_icon_card(painter: QPainter, icon: QImage, rect: QRect, radius: int) -> None:
    painter.setPen(Qt.PenStyle.NoPen)
    painter.setBrush(QColor(255, 255, 255, 225))
    painter.drawRoundedRect(QRectF(rect), radius, radius)

    icon_rect = QRect(
        rect.x() + (rect.width() - icon.width()) // 2,
        rect.y() + (rect.height() - icon.height()) // 2,
        icon.width(),
        icon.height(),
    )
    painter.drawImage(icon_rect, icon)


def _save_bitmap(image: QImage, path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    bitmap = image.convertToFormat(QImage.Format.Format_RGB888)
    if not bitmap.save(str(path), "BMP"):
        raise SystemExit(f"failed to write bitmap: {path}")


def generate_welcome_bitmap(icon_path: Path, output_path: Path, product_name: str) -> None:
    width, height = WELCOME_SIZE
    image = QImage(width, height, QImage.Format.Format_RGB32)
    painter = QPainter(image)
    painter.setRenderHint(QPainter.RenderHint.Antialiasing, True)
    painter.setRenderHint(QPainter.RenderHint.TextAntialiasing, True)

    gradient = QLinearGradient(0, 0, width, height)
    gradient.setColorAt(0.0, QColor("#f7fbff"))
    gradient.setColorAt(0.42, QColor("#d7ecff"))
    gradient.setColorAt(1.0, QColor("#b9dcf7"))
    painter.fillRect(QRect(0, 0, width, height), gradient)

    painter.setPen(Qt.PenStyle.NoPen)
    painter.setBrush(QColor(255, 255, 255, 105))
    painter.drawEllipse(QRectF(-48, -42, 132, 132))
    painter.setBrush(QColor("#95cdf7"))
    painter.setOpacity(0.24)
    painter.drawEllipse(QRectF(86, 210, 120, 120))
    painter.setOpacity(1.0)

    icon = _scaled_icon(icon_path, 58)
    _draw_icon_card(painter, icon, QRect(47, 64, 70, 70), 18)

    painter.setFont(_font(15, bold=True))
    painter.setPen(QColor("#12324a"))
    painter.drawText(QRectF(10, 154, width - 20, 28), Qt.AlignmentFlag.AlignCenter, product_name)

    painter.setFont(_font(8, bold=True))
    painter.setPen(QColor("#38627d"))
    painter.drawText(QRectF(12, 184, width - 24, 20), Qt.AlignmentFlag.AlignCenter, TEXT_DESKTOP_CLIENT)

    painter.setPen(QColor("#6aa9db"))
    painter.drawLine(38, 226, width - 38, 226)

    painter.setFont(_font(7))
    painter.setPen(QColor("#4a6d84"))
    painter.drawText(
        QRectF(18, 244, width - 36, 44),
        Qt.AlignmentFlag.AlignHCenter | Qt.AlignmentFlag.AlignTop | Qt.TextFlag.TextWordWrap,
        TEXT_LIGHT_SECURE_AUTO_UPDATE,
    )

    painter.end()
    _save_bitmap(image, output_path)


def generate_header_bitmap(icon_path: Path, output_path: Path, product_name: str) -> None:
    width, height = HEADER_SIZE
    image = QImage(width, height, QImage.Format.Format_RGB32)
    painter = QPainter(image)
    painter.setRenderHint(QPainter.RenderHint.Antialiasing, True)
    painter.setRenderHint(QPainter.RenderHint.TextAntialiasing, True)

    gradient = QLinearGradient(0, 0, width, height)
    gradient.setColorAt(0.0, QColor("#f8fbff"))
    gradient.setColorAt(1.0, QColor("#d7ecff"))
    painter.fillRect(QRect(0, 0, width, height), gradient)

    painter.setPen(Qt.PenStyle.NoPen)
    painter.setBrush(QColor("#b7ddfb"))
    painter.setOpacity(0.42)
    painter.drawEllipse(QRectF(96, -34, 84, 84))
    painter.setOpacity(1.0)

    icon = _scaled_icon(icon_path, 26)
    _draw_icon_card(painter, icon, QRect(10, 10, 36, 36), 10)

    painter.setFont(_font(10, bold=True))
    painter.setPen(QColor("#12324a"))
    painter.drawText(QRectF(54, 11, 88, 18), Qt.AlignmentFlag.AlignLeft | Qt.AlignmentFlag.AlignVCenter, product_name)

    painter.setFont(_font(7))
    painter.setPen(QColor("#38627d"))
    painter.drawText(QRectF(55, 29, 86, 14), Qt.AlignmentFlag.AlignLeft | Qt.AlignmentFlag.AlignVCenter, TEXT_INSTALL_WIZARD)

    painter.end()
    _save_bitmap(image, output_path)


def generate_installer_assets(icon_path: Path, output_dir: Path, product_name: str) -> tuple[Path, Path]:
    welcome_path = output_dir / "installer-welcome.bmp"
    header_path = output_dir / "installer-header.bmp"
    generate_welcome_bitmap(icon_path, welcome_path, product_name)
    generate_header_bitmap(icon_path, header_path, product_name)
    return welcome_path, header_path


def main() -> int:
    os.environ.setdefault("QT_QPA_PLATFORM", "offscreen")
    app = QGuiApplication.instance() or QGuiApplication(sys.argv)
    _register_chinese_fonts()
    args = parse_args()
    welcome_path, header_path = generate_installer_assets(args.icon, args.output_dir, args.product_name)
    print(f"Generated: {welcome_path}")
    print(f"Generated: {header_path}")
    app.quit()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
