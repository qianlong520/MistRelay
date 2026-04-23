from __future__ import annotations

import argparse
import os
import sys
from pathlib import Path

from PySide6.QtCore import QRect, QRectF, Qt
from PySide6.QtGui import QGuiApplication
from PySide6.QtGui import QColor, QFont, QImage, QLinearGradient, QPainter


WELCOME_SIZE = (164, 314)
HEADER_SIZE = (150, 57)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate MistRelay NSIS installer artwork")
    parser.add_argument("--icon", required=True, type=Path, help="Path to the source PNG icon")
    parser.add_argument("--output-dir", required=True, type=Path, help="Directory for generated BMP assets")
    parser.add_argument("--product-name", default="MistRelay", help="Product name shown in installer artwork")
    return parser.parse_args()


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

    title_font = QFont("Segoe UI", 15)
    title_font.setBold(True)
    painter.setFont(title_font)
    painter.setPen(QColor("#12324a"))
    painter.drawText(QRectF(10, 154, width - 20, 28), Qt.AlignmentFlag.AlignCenter, product_name)

    subtitle_font = QFont("Segoe UI", 8)
    subtitle_font.setBold(True)
    painter.setFont(subtitle_font)
    painter.setPen(QColor("#38627d"))
    painter.drawText(QRectF(12, 184, width - 24, 20), Qt.AlignmentFlag.AlignCenter, "Desktop Client")

    painter.setPen(QColor("#6aa9db"))
    painter.drawLine(38, 226, width - 38, 226)

    caption_font = QFont("Segoe UI", 7)
    painter.setFont(caption_font)
    painter.setPen(QColor("#4a6d84"))
    painter.drawText(
        QRectF(18, 244, width - 36, 44),
        Qt.AlignmentFlag.AlignHCenter | Qt.AlignmentFlag.AlignTop | Qt.TextFlag.TextWordWrap,
        "Lightweight relay workspace",
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

    title_font = QFont("Segoe UI", 10)
    title_font.setBold(True)
    painter.setFont(title_font)
    painter.setPen(QColor("#12324a"))
    painter.drawText(QRectF(54, 11, 88, 18), Qt.AlignmentFlag.AlignLeft | Qt.AlignmentFlag.AlignVCenter, product_name)

    subtitle_font = QFont("Segoe UI", 7)
    painter.setFont(subtitle_font)
    painter.setPen(QColor("#38627d"))
    painter.drawText(QRectF(55, 29, 86, 14), Qt.AlignmentFlag.AlignLeft | Qt.AlignmentFlag.AlignVCenter, "Installer")

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
    args = parse_args()
    welcome_path, header_path = generate_installer_assets(args.icon, args.output_dir, args.product_name)
    print(f"Generated: {welcome_path}")
    print(f"Generated: {header_path}")
    app.quit()
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
