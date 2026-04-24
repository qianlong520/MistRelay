from __future__ import annotations

import shutil
from pathlib import Path
from typing import Any

from PySide6.QtCore import QUrl
from PySide6.QtGui import QDesktopServices

from ..paths import configured_cache_root


class LocalCacheService:
    def __init__(self, config_service) -> None:
        self._config_service = config_service

    def cache_root(self) -> Path:
        return configured_cache_root(self._config_service.config.cache.cache_dir)

    def ensure_cache_root(self) -> Path:
        root = self.cache_root()
        root.mkdir(parents=True, exist_ok=True)
        return root

    def scan(self) -> dict[str, Any]:
        root = self.cache_root()
        total_size = 0
        file_count = 0
        item_count = 0
        latest_mtime = 0.0
        items: list[dict[str, Any]] = []

        if not root.exists():
            return {
                "root": str(root),
                "totalSize": 0,
                "fileCount": 0,
                "itemCount": 0,
                "latestMtime": 0.0,
                "items": [],
            }

        for path in root.rglob("*"):
            if not path.is_file() or self._is_metadata_file(path):
                continue
            try:
                stat = path.stat()
            except OSError:
                continue
            total_size += stat.st_size
            file_count += 1
            latest_mtime = max(latest_mtime, stat.st_mtime)
            item_count += 1
            items.append(
                {
                    "name": path.name,
                    "path": str(path),
                    "size": stat.st_size,
                    "mtime": stat.st_mtime,
                }
            )

        items.sort(key=lambda item: float(item["mtime"]), reverse=True)
        return {
            "root": str(root),
            "totalSize": total_size,
            "fileCount": file_count,
            "itemCount": item_count,
            "latestMtime": latest_mtime,
            "items": items,
        }

    def clear(self) -> dict[str, Any]:
        root = self.cache_root()
        before = self.scan()
        if root.exists():
            for child in root.iterdir():
                try:
                    if child.is_dir():
                        shutil.rmtree(child)
                    else:
                        child.unlink()
                except OSError:
                    continue
        root.mkdir(parents=True, exist_ok=True)
        return before

    def open_cache_root(self) -> None:
        root = self.ensure_cache_root()
        QDesktopServices.openUrl(QUrl.fromLocalFile(str(root)))

    def _is_metadata_file(self, path: Path) -> bool:
        return path.name.endswith(".complete") or path.name.endswith(".mistrelay.json")
