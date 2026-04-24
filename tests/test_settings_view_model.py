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
    pass


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

    def test_save_uses_toast_without_persistent_info_message(self) -> None:
        view_model = self.build_view_model()
        events: list[tuple[str, str]] = []
        view_model.toastRequested.connect(lambda level, message: events.append((level, message)))

        view_model.save()

        self.assertEqual(events, [("success", "客户端设置已保存")])
        self.assertEqual(view_model.infoMessage, "")


if __name__ == "__main__":
    unittest.main()
