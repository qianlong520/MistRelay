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

    from mistrelay_qt.viewmodels.downloads import DownloadsViewModel


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

    def list_download_statuses(self) -> list[dict]:
        return []

    def cancel_download(self, _transfer_id: str) -> dict:
        return {}

    def retry_download(self, _transfer_id: str) -> dict:
        return {}

    def remove_download(self, _transfer_id: str) -> None:
        return None

    def open_local_file(self, _path: str) -> None:
        return None

    def show_local_file_in_folder(self, _path: str) -> None:
        return None


class StubApiClient:
    def __init__(self) -> None:
        self.download_grouped_values: list[bool] = []
        self.download_payload: dict = {"data": []}

    def get_downloads(self, *, limit: int = 100, grouped: bool = True) -> dict:
        self.download_grouped_values.append(grouped)
        return self.download_payload

    def get_uploads(self, *, limit: int = 100) -> dict:
        return {"data": []}

    def get_queue_status(self) -> dict:
        return {}

    def get_download_statistics(self) -> dict:
        return {"data": {}}

    def get_upload_statistics(self) -> dict:
        return {"data": {}}


@unittest.skipUnless(HAS_PYSIDE6, "PySide6 is required for view model tests")
class DownloadsViewModelTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls._app = QCoreApplication.instance() or QCoreApplication([])

    def setUp(self) -> None:
        self.api_client = StubApiClient()
        self.view_model = DownloadsViewModel(
            api_client=self.api_client,
            local_runtime_service=StubLocalRuntimeService(),
            task_runner=ImmediateTaskRunner(),
        )

    def _download_records(self, count: int) -> list[dict]:
        return [
            {
                "id": index,
                "gid": f"gid-{index}",
                "file_name": f"file-{index:02d}.mp4",
                "status": "completed" if index % 2 == 0 else "pending",
                "total_length": 1024,
                "completed_length": 1024 if index % 2 == 0 else 0,
                "created_at": f"2026-04-24T{index % 24:02d}:00:00Z",
            }
            for index in range(1, count + 1)
        ]

    def test_refresh_requests_ungrouped_download_records(self) -> None:
        self.api_client.download_payload = {
            "data": [
                {
                    "id": 1,
                    "gid": "gid-1",
                    "file_name": "one.mp4",
                    "status": "completed",
                    "total_length": 1024,
                    "completed_length": 1024,
                    "created_at": "2026-04-24T01:00:00Z",
                },
                {
                    "id": 2,
                    "gid": "gid-2",
                    "file_name": "two.mp4",
                    "status": "failed",
                    "total_length": 2048,
                    "completed_length": 512,
                    "created_at": "2026-04-24T02:00:00Z",
                    "error_message": "network error",
                },
            ]
        }

        self.view_model.refresh()
        items = self.view_model.visibleTaskFlowModel.items()

        self.assertEqual(self.api_client.download_grouped_values[-1], False)
        self.assertEqual(len(items), 2)
        self.assertEqual({item["rowType"] for item in items}, {"download"})
        self.assertEqual({item["title"] for item in items}, {"one.mp4", "two.mp4"})
        self.assertEqual(self.view_model.groupRecordsModel.items(), [])

    def test_legacy_grouped_payload_is_flattened_to_download_rows(self) -> None:
        self.view_model._download_groups = [
            {
                "caption": "album caption",
                "group_key": "album-key",
                "downloads": [
                    {
                        "id": 10,
                        "gid": "gid-a",
                        "file_name": "a.jpg",
                        "status": "completed",
                        "total_length": 100,
                        "completed_length": 100,
                        "created_at": "2026-04-24T03:00:00Z",
                    },
                    {
                        "id": 11,
                        "gid": "gid-b",
                        "file_name": "b.jpg",
                        "status": "pending",
                        "total_length": 200,
                        "completed_length": 0,
                        "created_at": "2026-04-24T04:00:00Z",
                    },
                ],
            }
        ]

        self.view_model._rebuild_models()
        items = self.view_model.visibleTaskFlowModel.items()

        self.assertEqual(len(items), 2)
        self.assertEqual({item["rowType"] for item in items}, {"download"})
        self.assertEqual({item["subtitle"] for item in items}, {"album caption"})
        self.assertFalse(any(item.get("rowType") == "group" for item in items))

    def test_visible_task_flow_is_paginated(self) -> None:
        self.api_client.download_payload = {"data": self._download_records(25)}

        self.view_model.refresh()

        self.assertEqual(self.view_model.pageSize, 10)
        self.assertEqual(self.view_model.totalPages, 3)
        self.assertEqual(self.view_model.currentPage, 1)
        self.assertEqual(len(self.view_model.visibleTaskFlowModel.items()), 10)
        self.assertTrue(self.view_model.canNextPage)
        self.assertFalse(self.view_model.canPreviousPage)
        self.assertEqual(self.view_model.pageSummary, "显示 1-10 / 25 条")

        self.view_model.nextPage()
        self.assertEqual(self.view_model.currentPage, 2)
        self.assertEqual(len(self.view_model.visibleTaskFlowModel.items()), 10)
        self.assertTrue(self.view_model.canNextPage)
        self.assertTrue(self.view_model.canPreviousPage)
        self.assertEqual(self.view_model.pageSummary, "显示 11-20 / 25 条")

        self.view_model.nextPage()
        self.assertEqual(self.view_model.currentPage, 3)
        self.assertEqual(len(self.view_model.visibleTaskFlowModel.items()), 5)
        self.assertFalse(self.view_model.canNextPage)
        self.assertTrue(self.view_model.canPreviousPage)
        self.assertEqual(self.view_model.pageSummary, "显示 21-25 / 25 条")

        self.view_model.previousPage()
        self.assertEqual(self.view_model.currentPage, 2)
        self.assertEqual(self.view_model.pageSummary, "显示 11-20 / 25 条")

    def test_filter_resets_to_first_page_and_recalculates_total_pages(self) -> None:
        self.api_client.download_payload = {"data": self._download_records(25)}
        self.view_model.refresh()
        self.view_model.nextPage()

        self.view_model.setUnifiedStatusFilter("completed")

        self.assertEqual(self.view_model.currentPage, 1)
        self.assertEqual(self.view_model.totalPages, 2)
        self.assertEqual(len(self.view_model.visibleTaskFlowModel.items()), 10)
        self.assertEqual(self.view_model.pageSummary, "显示 1-10 / 12 条")

        self.view_model.setUnifiedKeyword("file-02")

        self.assertEqual(self.view_model.currentPage, 1)
        self.assertEqual(self.view_model.totalPages, 1)
        self.assertEqual(len(self.view_model.visibleTaskFlowModel.items()), 1)
        self.assertEqual(self.view_model.visibleTaskFlowModel.items()[0]["title"], "file-02.mp4")

    def test_page_size_changes_reset_page_and_invalid_values_use_default(self) -> None:
        self.api_client.download_payload = {"data": self._download_records(25)}
        self.view_model.refresh()
        self.view_model.nextPage()

        self.view_model.setPageSize(30)

        self.assertEqual(self.view_model.pageSize, 30)
        self.assertEqual(self.view_model.currentPage, 1)
        self.assertEqual(self.view_model.totalPages, 1)
        self.assertEqual(len(self.view_model.visibleTaskFlowModel.items()), 25)

        self.view_model.setPageSize(999)

        self.assertEqual(self.view_model.pageSize, 10)
        self.assertEqual(self.view_model.currentPage, 1)
        self.assertEqual(self.view_model.totalPages, 3)
        self.assertEqual(len(self.view_model.visibleTaskFlowModel.items()), 10)


if __name__ == "__main__":
    unittest.main()
