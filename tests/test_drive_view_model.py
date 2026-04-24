from __future__ import annotations

import importlib.util
import sys
import unittest
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))


HAS_PYSIDE6 = importlib.util.find_spec("PySide6") is not None

if HAS_PYSIDE6:
    from PySide6.QtCore import QCoreApplication

    from mistrelay_qt.viewmodels.drive import DriveViewModel, TELEGRAM_GROUP_PATH_PREFIX


class ImmediateTaskRunner:
    def submit(self, fn, *, on_success=None, on_error=None) -> None:
        try:
            result = fn()
        except Exception as exc:  # pragma: no cover - passthrough only
            if on_error:
                on_error(str(exc))
        else:
            if on_success:
                on_success(result)


class StubSignal:
    def __init__(self) -> None:
        self._callbacks: list = []

    def connect(self, callback) -> None:
        self._callbacks.append(callback)

    def emit(self, *args, **kwargs) -> None:
        for callback in list(self._callbacks):
            callback(*args, **kwargs)


class StubLocalRuntimeService:
    def __init__(self) -> None:
        self.transferUpdated = StubSignal()
        self.preview_requests: list[dict] = []

    def list_download_statuses(self) -> list[dict]:
        return []

    def prepare_preview_file(self, **kwargs) -> dict:
        self.preview_requests.append(kwargs)
        return {"localPath": "E:/MistRelay/.local/preview/image.jpg"}

    def start_preview_stream(self, **kwargs) -> dict:
        self.preview_requests.append(kwargs)
        return {"transferId": "preview-1", "url": "http://127.0.0.1:1234/preview/preview-1"}

    def cancel_preview(self, _transfer_id: str) -> None:
        return None

    def start_download(self, **_kwargs) -> dict:
        return {"transferId": "download-1"}


class StubApiClient:
    def __init__(self) -> None:
        self.records: list[dict] = []

    def get_telegram_usage(self) -> dict:
        return {
            "data": {
                "total_count": len(self.records),
                "images": len(self.records),
                "videos": 0,
                "documents": 0,
                "total_size": sum(int(record.get("file_size") or 0) for record in self.records),
            }
        }

    def browse_telegram(self, **_kwargs) -> dict:
        return {
            "items": self.records,
            "total": len(self.records),
            "page": 1,
            "page_size": 10,
        }

    def resolve_server_url(self, path: str) -> str:
        clean_path = path if path.startswith("/") else f"/{path}"
        return f"https://mist.example{clean_path}"


@unittest.skipUnless(HAS_PYSIDE6, "PySide6 is required for view model tests")
class DriveViewModelThumbnailTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls._app = QCoreApplication.instance() or QCoreApplication([])

    def setUp(self) -> None:
        self.api_client = StubApiClient()
        self.runtime_service = StubLocalRuntimeService()
        self.view_model = DriveViewModel(
            api_client=self.api_client,
            local_runtime_service=self.runtime_service,
            task_runner=ImmediateTaskRunner(),
        )

    def _refresh_with_records(self, records: list[dict]) -> list[dict]:
        self.api_client.records = records
        self.view_model.refresh()
        return self.view_model.itemsModel.items()

    def _image_record(self, **overrides) -> dict:
        record = {
            "message_id": 101,
            "file_name": "photo.jpg",
            "mime_type": "image/jpeg",
            "file_size": 1024,
            "message_date": "2026-04-24T01:00:00Z",
            "hash": "abc123",
            "stream_url": "/101/photo.jpg?hash=abc123",
        }
        record.update(overrides)
        return record

    def test_relative_thumbnail_url_is_resolved_to_server_url(self) -> None:
        rows = self._refresh_with_records([
            self._image_record(thumbnail_url="/api/rclone/thumbnail/serve/telegram/thumb.webp")
        ])

        self.assertEqual(rows[0]["thumbnailUrl"], "https://mist.example/api/rclone/thumbnail/serve/telegram/thumb.webp")

    def test_absolute_thumbnail_url_is_preserved(self) -> None:
        rows = self._refresh_with_records([
            self._image_record(thumbnailUrl="https://cdn.example/thumb.webp")
        ])

        self.assertEqual(rows[0]["thumbnailUrl"], "https://cdn.example/thumb.webp")

    def test_image_without_thumbnail_does_not_use_media_stream_url(self) -> None:
        rows = self._refresh_with_records([self._image_record()])

        self.assertEqual(rows[0]["thumbnailUrl"], "")

    def test_group_thumbnail_items_use_thumbnail_resolver(self) -> None:
        self._refresh_with_records(
            [
                self._image_record(
                    message_id=201,
                    file_name="one.jpg",
                    media_group_id="album-1",
                    thumbnail_url="/thumbs/one.webp",
                    stream_url="/201/one.jpg?hash=one",
                    hash="one",
                ),
                self._image_record(
                    message_id=202,
                    file_name="two.jpg",
                    media_group_id="album-1",
                    thumb_url="https://cdn.example/two.webp",
                    stream_url="/202/two.jpg?hash=two",
                    hash="two",
                ),
            ]
        )

        self.view_model.setSidebarSection("flows")
        rows = self.view_model.itemsModel.items()
        group_row = next(row for row in rows if row["path"] == f"{TELEGRAM_GROUP_PATH_PREFIX}album-1")
        self.assertEqual(
            [item["thumbnailUrl"] for item in group_row["thumbnailItems"]],
            ["https://mist.example/thumbs/one.webp", "https://cdn.example/two.webp"],
        )

    def test_open_preview_still_uses_media_stream_url(self) -> None:
        rows = self._refresh_with_records([
            self._image_record(thumbnail_url="/thumbs/photo.webp")
        ])

        self.view_model.openPreview(rows[0]["path"])

        self.assertEqual(self.runtime_service.preview_requests[-1]["source_url"], "https://mist.example/101/photo.jpg?hash=abc123")


if __name__ == "__main__":
    unittest.main()
