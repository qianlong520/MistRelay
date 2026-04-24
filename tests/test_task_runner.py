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

    from mistrelay_qt.task_runner import TaskRunner, Worker


@unittest.skipUnless(HAS_PYSIDE6, "requires PySide6")
class TaskRunnerShutdownTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls._app = QCoreApplication.instance() or QCoreApplication([])

    def test_submit_is_ignored_after_shutdown(self) -> None:
        runner = TaskRunner()
        calls: list[str] = []

        runner.shutdown()
        runner.submit(lambda: calls.append("ran"), on_success=lambda _result: calls.append("success"))

        self.assertEqual(calls, [])

    def test_callbacks_are_ignored_after_shutdown(self) -> None:
        runner = TaskRunner()
        calls: list[str] = []

        runner._shutting_down = True
        worker = Worker(lambda: "done")
        runner._workers.add(worker)

        def cleanup() -> None:
            runner._workers.discard(worker)

        def success(result) -> None:
            cleanup()
            if runner._shutting_down:
                return
            calls.append(result)

        worker.signals.finished.connect(success)
        worker.run()

        self.assertEqual(calls, [])
        self.assertNotIn(worker, runner._workers)


if __name__ == "__main__":
    unittest.main()
