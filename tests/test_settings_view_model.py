from __future__ import annotations

import importlib.util
import sys
import unittest
from pathlib import Path


PROJECT_ROOT = Path(__file__).resolve().parents[1]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from mistrelay_qt.models import AppConfig


HAS_PYSIDE6 = importlib.util.find_spec("PySide6") is not None

if HAS_PYSIDE6:
    from PySide6.QtCore import QCoreApplication

    from mistrelay_qt.viewmodels.settings import SettingsViewModel


class ImmediateTaskRunner:
    def submit(self, fn, *, on_success=None, on_error=None) -> None:
        try:
            result = fn()
        except Exception as exc:  # pragma: no cover - relay only
            if on_error:
                on_error(str(exc))
        else:
            if on_success:
                on_success(result)


class StubApiClient:
    def get_config(self, _category: str) -> dict:
        return {"data": {}}

    def get_rclone_config(self) -> dict:
        return {"content": "", "file_path": "/tmp/rclone.conf"}

    def get_rclone_remotes(self) -> dict:
        return {"data": []}

    def get_docker_status(self) -> dict:
        return {}

    def get_docker_logs(self, *, lines: int) -> dict:
        return {"logs": f"tail={lines}"}

    def get_system_resources(self) -> dict:
        return {"data": {}}

    def get_log_files(self) -> dict:
        return {"files": []}

    def get_log_content(self, **_kwargs) -> dict:
        return {"lines": []}


class StubConfigService:
    def __init__(self) -> None:
        self.config = AppConfig()
        self.saved_runtime_settings: dict | None = None

    def update_runtime_settings(self, **kwargs):
        self.saved_runtime_settings = dict(kwargs)
        return self.config


class StubLocalRuntimeService:
    def get_default_download_dir(self) -> str:
        return "C:/Downloads/MistRelay"

    def open_external_url(self, _url: str) -> None:
        return

    def pick_download_dir(self, _current: str) -> str:
        return ""

    def show_local_file_in_folder(self, _path: str) -> None:
        return


class StubUpdateService:
    def check_for_updates(self):
        raise RuntimeError("not used in these tests")

    def download_update(self, *_args, **_kwargs):
        raise RuntimeError("not used in these tests")

    def install_update(self, *_args, **_kwargs):
        raise RuntimeError("not used in these tests")


@unittest.skipUnless(HAS_PYSIDE6, "requires PySide6")
class SettingsViewModelTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls._app = QCoreApplication.instance() or QCoreApplication([])

    def build_view_model(self) -> SettingsViewModel:
        return SettingsViewModel(
            api_client=StubApiClient(),
            config_service=StubConfigService(),
            local_runtime_service=StubLocalRuntimeService(),
            update_service=StubUpdateService(),
            task_runner=ImmediateTaskRunner(),
        )

    def test_apply_resources_builds_three_cards_with_expected_tones(self) -> None:
        view_model = self.build_view_model()

        view_model._apply_resources(
            {
                "data": {
                    "cpu": {"percent": 40},
                    "memory": {"percent": 72, "used": 8 * 1024**3, "total": 16 * 1024**3},
                    "disk": {"percent": 91, "used": 91 * 1024**3, "total": 100 * 1024**3},
                }
            }
        )

        cards = view_model.resourceCards
        self.assertEqual(len(cards), 3)
        self.assertEqual([card["title"] for card in cards], ["CPU", "内存", "硬盘"])
        self.assertEqual([card["tone"] for card in cards], ["success", "warning", "danger"])
        self.assertEqual(cards[0]["caption"], "当前系统处理器占用率")
        self.assertEqual(cards[1]["value"], "72.0%")
        self.assertEqual(cards[2]["value"], "91.0%")

    def test_set_docker_log_lines_enforces_minimum(self) -> None:
        view_model = self.build_view_model()

        view_model.setDockerLogLines(5)

        self.assertEqual(view_model.dockerLogLines, 20)

    def test_apply_app_logs_updates_text_and_summary(self) -> None:
        view_model = self.build_view_model()

        view_model._apply_app_logs({"lines": ["line one", "line two", "line three"]})

        self.assertEqual(view_model.appLogText, "line one\nline two\nline three")
        self.assertEqual(view_model.appLogSummary, "3 行日志")


if __name__ == "__main__":
    unittest.main()
