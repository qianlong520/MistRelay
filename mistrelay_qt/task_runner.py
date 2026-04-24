from __future__ import annotations

from collections.abc import Callable
from typing import Any

from PySide6.QtCore import QObject, QRunnable, QThreadPool, Signal
from shiboken6 import isValid


class WorkerSignals(QObject):
    finished = Signal(object)
    failed = Signal(str)


class Worker(QRunnable):
    def __init__(self, fn: Callable[[], Any]) -> None:
        super().__init__()
        self._fn = fn
        self.signals = WorkerSignals()

    def run(self) -> None:
        try:
            result = self._fn()
        except Exception as exc:  # pragma: no cover - UI thread relay
            self._safe_emit_failed(str(exc))
        else:  # pragma: no cover - UI thread relay
            self._safe_emit_finished(result)

    def _signals_available(self) -> bool:
        try:
            return isValid(self.signals)
        except RuntimeError:
            return False

    def _safe_emit_finished(self, result: Any) -> None:
        if not self._signals_available():
            return
        try:
            self.signals.finished.emit(result)
        except RuntimeError:
            return

    def _safe_emit_failed(self, message: str) -> None:
        if not self._signals_available():
            return
        try:
            self.signals.failed.emit(message)
        except RuntimeError:
            return


class TaskRunner(QObject):
    def __init__(self, parent: QObject | None = None) -> None:
        super().__init__(parent)
        self._pool = QThreadPool.globalInstance()
        self._workers: set[Worker] = set()
        self._shutting_down = False

    def submit(
        self,
        fn: Callable[[], Any],
        *,
        on_success: Callable[[Any], None] | None = None,
        on_error: Callable[[str], None] | None = None,
    ) -> None:
        if self._shutting_down:
            return

        worker = Worker(fn)
        self._workers.add(worker)

        def cleanup() -> None:
            self._workers.discard(worker)

        def success(result: Any) -> None:
            cleanup()
            if self._shutting_down:
                return
            if on_success:
                on_success(result)

        def failed(message: str) -> None:
            cleanup()
            if self._shutting_down:
                return
            if on_error:
                on_error(message)

        worker.signals.finished.connect(success)
        worker.signals.failed.connect(failed)
        self._pool.start(worker)

    def shutdown(self) -> None:
        self._shutting_down = True
        self._workers.clear()
