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

    from mistrelay_qt.models import AppConfig
    from mistrelay_qt.viewmodels.app_shell import AppViewModel


class StubConfigService:
    def __init__(self) -> None:
        self.config = AppConfig()
        self.clear_user_session_calls = 0

    def clear_user_session(self) -> None:
        self.clear_user_session_calls += 1


class StubApiClient:
    def get_current_user(self) -> dict:
        return {"user": {"username": "tester"}}


class StubTaskRunner:
    def submit(self, fn, *, on_success=None, on_error=None) -> None:
        try:
            result = fn()
        except Exception as exc:  # pragma: no cover - passthrough
            if on_error:
                on_error(str(exc))
        else:
            if on_success:
                on_success(result)


class StubLoginViewModel:
    def __init__(self) -> None:
        self.reset_calls = 0

    def resetAfterLogout(self) -> None:
        self.reset_calls += 1


class StubSignal:
    def __init__(self) -> None:
        self._callbacks: list = []

    def connect(self, callback) -> None:
        self._callbacks.append(callback)

    def emit(self, *args, **kwargs) -> None:
        for callback in list(self._callbacks):
            callback(*args, **kwargs)


class StubWebsocketService:
    def __init__(self) -> None:
        self.connectionStateChanged = StubSignal()
        self.errorRaised = StubSignal()
        self.start_calls = 0
        self.stop_calls = 0

    def start(self) -> None:
        self.start_calls += 1

    def stop(self) -> None:
        self.stop_calls += 1


@unittest.skipUnless(HAS_PYSIDE6, "requires PySide6")
class AppViewModelTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls) -> None:
        cls._app = QCoreApplication.instance() or QCoreApplication([])

    def build_view_model(self) -> AppViewModel:
        self.config_service = StubConfigService()
        self.websocket_service = StubWebsocketService()
        self.login_view_model = StubLoginViewModel()
        view_model = AppViewModel(
            config_service=self.config_service,
            api_client=StubApiClient(),
            websocket_service=self.websocket_service,
            login_view_model=self.login_view_model,
            task_runner=StubTaskRunner(),
        )
        return view_model

    def test_disconnected_state_starts_downloads_fallback_timer(self) -> None:
        view_model = self.build_view_model()
        view_model.register_refreshers({"downloads": lambda: None})

        view_model.loginSucceeded("tester")

        self.assertTrue(view_model._downloads_refresh_timer.isActive())
        self.assertEqual(view_model._downloads_refresh_timer.interval(), 5000)

    def test_connecting_or_connected_state_stops_downloads_fallback_timer(self) -> None:
        view_model = self.build_view_model()
        view_model.register_refreshers({"downloads": lambda: None})

        view_model.loginSucceeded("tester")
        self.assertTrue(view_model._downloads_refresh_timer.isActive())

        view_model._set_connection_state("connecting")
        self.assertFalse(view_model._downloads_refresh_timer.isActive())

        view_model._set_connection_state("disconnected")
        self.assertTrue(view_model._downloads_refresh_timer.isActive())

        view_model._set_connection_state("connected")
        self.assertFalse(view_model._downloads_refresh_timer.isActive())

    def test_fallback_timer_refreshes_downloads_only_when_logged_in_and_disconnected(self) -> None:
        view_model = self.build_view_model()
        calls: list[str] = []
        view_model.register_refreshers(
            {
                "dashboard": lambda: calls.append("dashboard"),
                "downloads": lambda: calls.append("downloads"),
            }
        )
        view_model.navigate("drive")
        calls.clear()

        view_model.loginSucceeded("tester")
        view_model._refresh_downloads_when_disconnected()
        self.assertEqual(calls, ["downloads"])

        view_model._set_connection_state("connected")
        view_model._refresh_downloads_when_disconnected()
        self.assertEqual(calls, ["downloads"])

    def test_logout_prevents_late_disconnected_state_from_restarting_timer(self) -> None:
        view_model = self.build_view_model()
        view_model.register_refreshers({"downloads": lambda: None})

        view_model.loginSucceeded("tester")
        self.assertTrue(view_model._downloads_refresh_timer.isActive())

        view_model.logout()
        self.assertFalse(view_model._downloads_refresh_timer.isActive())

        view_model._set_connection_state("connected")
        view_model._set_connection_state("disconnected")
        self.assertFalse(view_model._downloads_refresh_timer.isActive())


if __name__ == "__main__":
    unittest.main()
