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
    def __init__(self, statuses: list[dict] | None = None) -> None:
        self.transferUpdated = StubSignal()
        self.statuses = statuses or []
        self.cancelled: list[str] = []
        self.retried: list[str] = []
        self.removed: list[str] = []

    def list_download_statuses(self) -> list[dict]:
        return list(self.statuses)

    def cancel_download(self, transfer_id: str) -> dict:
        self.cancelled.append(transfer_id)
        return self._updated_status(transfer_id, "cancelling")

    def retry_download(self, transfer_id: str) -> dict:
        self.retried.append(transfer_id)
        return self._updated_status(transfer_id, "pending", error="")

    def remove_download_session(self, transfer_id: str) -> None:
        self.removed.append(transfer_id)
        self.statuses = [item for item in self.statuses if item["transferId"] != transfer_id]

    def open_local_file(self, _path: str) -> None:
        return None

    def show_local_file_in_folder(self, _path: str) -> None:
        return None

    def _updated_status(self, transfer_id: str, state: str, error: str | None = None) -> dict:
        for item in self.statuses:
            if item["transferId"] == transfer_id:
                updated = dict(item)
                updated["state"] = state
                if error is not None:
                    updated["error"] = error
                return updated
        return local_status(transfer_id, state=state)


class StubApiClient:
    def __getattr__(self, name: str):
        if name.startswith(("get_", "retry_", "delete_")):
            def unexpected_call(*_args, **_kwargs):
                raise AssertionError(f"server API should not be called: {name}")

            return unexpected_call
        raise AttributeError(name)


def local_status(
    transfer_id: str,
    *,
    file_name: str | None = None,
    state: str = "pending",
    downloaded: int = 0,
    total: int = 1024,
    progress: float = 0.0,
    speed: int = 0,
    local_path: str | None = None,
    error: str = "",
) -> dict:
    file_name = file_name or f"{transfer_id}.mp4"
    return {
        "transferId": transfer_id,
        "fileName": file_name,
        "remote": "telegram",
        "remotePath": "/Videos",
        "sourceUrl": f"https://example.test/{file_name}",
        "kind": "file",
        "localPath": local_path or f"C:/Downloads/{file_name}",
        "downloadedBytes": downloaded,
        "totalBytes": total,
        "downloadSpeed": speed,
        "progressPercent": progress,
        "state": state,
        "readyForPreview": state == "completed",
        "error": error,
    }


@unittest.skipUnless(HAS_PYSIDE6, "PySide6 is required for view model tests")
class DownloadsViewModelTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls._app = QCoreApplication.instance() or QCoreApplication([])

    def make_view_model(self, statuses: list[dict] | None = None) -> DownloadsViewModel:
        self.api_client = StubApiClient()
        self.local_runtime = StubLocalRuntimeService(statuses)
        return DownloadsViewModel(
            api_client=self.api_client,
            local_runtime_service=self.local_runtime,
            task_runner=ImmediateTaskRunner(),
        )


    def _status_for(self, view_model: DownloadsViewModel, transfer_id: str) -> str:
        for item in view_model.visibleTaskFlowModel.items():
            if item["transferId"] == transfer_id:
                return item["status"]
        self.fail(f"missing transfer: {transfer_id}")
    def local_records(self, count: int) -> list[dict]:
        return [
            local_status(
                f"local-{index:02d}",
                file_name=f"file-{index:02d}.mp4",
                state="completed" if index % 2 == 0 else "pending",
                downloaded=1024 if index % 2 == 0 else 0,
                progress=100.0 if index % 2 == 0 else 0.0,
            )
            for index in range(1, count + 1)
        ]

    def test_refresh_uses_only_local_download_statuses(self) -> None:
        view_model = self.make_view_model([
            local_status("one", file_name="one.mp4", state="completed", downloaded=1024, progress=100.0),
            local_status("two", file_name="two.mp4", state="error", downloaded=512, progress=50.0, error="network error"),
        ])

        view_model.refresh()
        items = view_model.visibleTaskFlowModel.items()

        self.assertEqual(view_model.taskSection, "local")
        self.assertEqual(len(items), 2)
        self.assertEqual({item["rowType"] for item in items}, {"local"})
        self.assertEqual({item["title"] for item in items}, {"one.mp4", "two.mp4"})
        self.assertEqual(view_model.activeDownloadsModel.items(), [])
        self.assertEqual(view_model.activeUploadsModel.items(), [])
        self.assertEqual(view_model.queueCurrentModel.items(), [])
        self.assertEqual(view_model.queueWaitingModel.items(), [])

    def test_server_sections_and_events_do_not_change_local_only_view(self) -> None:
        view_model = self.make_view_model([local_status("one", state="completed")])

        view_model.setTaskSection("server")
        view_model.consume_status_event({"type": "download_update"})
        view_model.retryServerDownload("gid-1")
        view_model.deleteServerDownload("gid-1", 1)
        view_model.retryUpload(1)
        view_model.deleteUpload(1)

        self.assertEqual(view_model.taskSection, "local")
        self.assertEqual(view_model.errorMessage, "")
        self.assertEqual(len(view_model.visibleTaskFlowModel.items()), 1)

    def test_visible_local_downloads_are_paginated(self) -> None:
        view_model = self.make_view_model(self.local_records(25))
        view_model.refresh()

        self.assertEqual(view_model.pageSize, 10)
        self.assertEqual(view_model.totalPages, 3)
        self.assertEqual(view_model.currentPage, 1)
        self.assertEqual(len(view_model.visibleTaskFlowModel.items()), 10)
        self.assertTrue(view_model.canNextPage)
        self.assertFalse(view_model.canPreviousPage)
        self.assertEqual(view_model.pageSummary, "显示 1-10 / 25 条")

        view_model.nextPage()
        self.assertEqual(view_model.currentPage, 2)
        self.assertEqual(len(view_model.visibleTaskFlowModel.items()), 10)
        self.assertTrue(view_model.canNextPage)
        self.assertTrue(view_model.canPreviousPage)
        self.assertEqual(view_model.pageSummary, "显示 11-20 / 25 条")

        view_model.nextPage()
        self.assertEqual(view_model.currentPage, 3)
        self.assertEqual(len(view_model.visibleTaskFlowModel.items()), 5)
        self.assertFalse(view_model.canNextPage)
        self.assertTrue(view_model.canPreviousPage)
        self.assertEqual(view_model.pageSummary, "显示 21-25 / 25 条")

    def test_local_filter_resets_page_and_recalculates_total_pages(self) -> None:
        view_model = self.make_view_model(self.local_records(25))
        view_model.refresh()
        view_model.nextPage()

        view_model.setUnifiedStatusFilter("completed")

        self.assertEqual(view_model.currentPage, 1)
        self.assertEqual(view_model.totalPages, 2)
        self.assertEqual(len(view_model.visibleTaskFlowModel.items()), 10)
        self.assertEqual(view_model.pageSummary, "显示 1-10 / 12 条")

        view_model.setUnifiedKeyword("file-02")

        self.assertEqual(view_model.currentPage, 1)
        self.assertEqual(view_model.totalPages, 1)
        self.assertEqual(len(view_model.visibleTaskFlowModel.items()), 1)
        self.assertEqual(view_model.visibleTaskFlowModel.items()[0]["title"], "file-02.mp4")

    def test_page_size_changes_reset_page_and_invalid_values_use_default(self) -> None:
        view_model = self.make_view_model(self.local_records(25))
        view_model.refresh()
        view_model.nextPage()

        view_model.setPageSize(30)

        self.assertEqual(view_model.pageSize, 30)
        self.assertEqual(view_model.currentPage, 1)
        self.assertEqual(view_model.totalPages, 1)
        self.assertEqual(len(view_model.visibleTaskFlowModel.items()), 25)

        view_model.setPageSize(999)

        self.assertEqual(view_model.pageSize, 10)
        self.assertEqual(view_model.currentPage, 1)
        self.assertEqual(view_model.totalPages, 3)
        self.assertEqual(len(view_model.visibleTaskFlowModel.items()), 10)

    def test_transfer_update_and_local_actions_refresh_models(self) -> None:
        view_model = self.make_view_model([local_status("one", state="pending")])
        self.local_runtime.transferUpdated.emit(
            local_status("two", file_name="two.mp4", state="completed", downloaded=1024, progress=100.0)
        )

        self.assertEqual({item["title"] for item in view_model.visibleTaskFlowModel.items()}, {"one.mp4", "two.mp4"})

        view_model.cancelLocalDownload("one")
        self.assertEqual(self.local_runtime.cancelled, ["one"])
        self.assertEqual(self._status_for(view_model, "one"), "cancelling")

        view_model.retryLocalDownload("one")
        self.assertEqual(self.local_runtime.retried, ["one"])
        self.assertEqual(self._status_for(view_model, "one"), "pending")

        view_model.removeLocalDownload("one")
        self.assertEqual(self.local_runtime.removed, ["one"])
        self.assertEqual({item["transferId"] for item in view_model.visibleTaskFlowModel.items()}, {"two"})


if __name__ == "__main__":
    unittest.main()
