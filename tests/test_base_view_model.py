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

    from mistrelay_qt.viewmodels.base import BaseViewModel


@unittest.skipUnless(HAS_PYSIDE6, "requires PySide6")
class BaseViewModelToastTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls._app = QCoreApplication.instance() or QCoreApplication([])

    def test_show_toast_emits_level_and_message(self) -> None:
        view_model = BaseViewModel()
        events: list[tuple[str, str]] = []
        view_model.toastRequested.connect(lambda level, message: events.append((level, message)))

        view_model._show_toast("success", "保存成功")

        self.assertEqual(events, [("success", "保存成功")])

    def test_show_toast_emits_for_duplicate_message_twice(self) -> None:
        view_model = BaseViewModel()
        events: list[tuple[str, str]] = []
        view_model.toastRequested.connect(lambda level, message: events.append((level, message)))

        view_model._show_toast("info", "已加入下载")
        view_model._show_toast("info", "已加入下载")

        self.assertEqual(
            events,
            [("info", "已加入下载"), ("info", "已加入下载")],
        )


if __name__ == "__main__":
    unittest.main()
