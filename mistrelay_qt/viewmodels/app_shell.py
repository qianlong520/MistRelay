from __future__ import annotations

from collections.abc import Callable
from typing import Any

from PySide6.QtCore import Property, QTimer, Signal, Slot

from ..constants import APP_NAME, ROUTE_TITLES, ROUTES
from ..task_runner import TaskRunner
from .base import BaseViewModel


class AppViewModel(BaseViewModel):
    _DOWNLOADS_REFRESH_INTERVAL_MS = 5000

    currentRouteChanged = Signal()
    loggedInChanged = Signal()
    userDisplayNameChanged = Signal()
    connectionStateChanged = Signal()
    windowTitleChanged = Signal()
    toastRequested = Signal(str, str)

    def __init__(
        self,
        *,
        config_service: Any,
        api_client: Any,
        websocket_service: Any,
        login_view_model: Any,
        task_runner: TaskRunner,
    ) -> None:
        super().__init__()
        self._config_service = config_service
        self._api_client = api_client
        self._websocket_service = websocket_service
        self._login_view_model = login_view_model
        self._task_runner = task_runner
        self._current_route = "dashboard"
        self._logged_in = False
        self._user_display_name = ""
        self._connection_state = "disconnected"
        self._refreshers: dict[str, Callable[[], None]] = {}
        self._status_consumers: dict[str, Callable[[dict[str, Any]], None]] = {}
        self._downloads_refresh_timer = QTimer(self)
        self._downloads_refresh_timer.setInterval(self._DOWNLOADS_REFRESH_INTERVAL_MS)
        self._downloads_refresh_timer.timeout.connect(self._refresh_downloads_when_disconnected)

        self._websocket_service.connectionStateChanged.connect(self._set_connection_state)
        self._websocket_service.errorRaised.connect(
            lambda message: self._show_toast("warning", message)
        )

    def register_refreshers(self, refreshers: dict[str, Callable[[], None]]) -> None:
        self._refreshers = refreshers
        self._sync_downloads_refresh_timer()

    def register_status_consumers(
        self,
        consumers: dict[str, Callable[[dict[str, Any]], None]],
    ) -> None:
        self._status_consumers = consumers

    @Slot(str, str)
    def relayToast(self, level: str, message: str) -> None:
        self._show_toast(level, message)

    def bootstrap(self) -> None:
        config = self._config_service.config
        if not config.auth_token or not config.server_base_url:
            self._set_logged_out()
            return

        self._set_busy(True)
        self._task_runner.submit(
            self._api_client.get_current_user,
            on_success=self._bootstrap_succeeded,
            on_error=self._bootstrap_failed,
        )

    def _bootstrap_succeeded(self, payload: dict[str, Any]) -> None:
        self._set_busy(False)
        user = payload.get("user") if isinstance(payload, dict) else payload
        self._set_logged_in(user)
        self._websocket_service.start()
        self._show_toast("success", "已恢复桌面会话")
        self._refresh_current_route()

    def _bootstrap_failed(self, message: str) -> None:
        self._set_busy(False)
        self._config_service.clear_user_session()
        self._set_logged_out()
        self._show_toast("warning", f"会话已失效：{message}")

    def _set_connection_state(self, state: str) -> None:
        if self._connection_state == state:
            return
        self._connection_state = state
        self.connectionStateChanged.emit()
        self._sync_downloads_refresh_timer()

    def _set_logged_in(self, user: dict[str, Any] | None) -> None:
        username = str((user or {}).get("username") or self._config_service.config.user.username or "管理员")
        self._logged_in = True
        self._user_display_name = username
        self.loggedInChanged.emit()
        self.userDisplayNameChanged.emit()
        self.windowTitleChanged.emit()
        self._sync_downloads_refresh_timer()

    def _set_logged_out(self) -> None:
        self._logged_in = False
        self._user_display_name = ""
        self._connection_state = "disconnected"
        self._current_route = "dashboard"
        self._sync_downloads_refresh_timer()
        self.loggedInChanged.emit()
        self.userDisplayNameChanged.emit()
        self.currentRouteChanged.emit()
        self.connectionStateChanged.emit()
        self.windowTitleChanged.emit()

    @Slot(str)
    def loginSucceeded(self, username: str) -> None:
        self._logged_in = True
        self._user_display_name = username or "管理员"
        self.loggedInChanged.emit()
        self.userDisplayNameChanged.emit()
        self.windowTitleChanged.emit()
        self._sync_downloads_refresh_timer()
        self._websocket_service.start()
        self._refresh_current_route()

    @Slot()
    def logout(self) -> None:
        self._config_service.clear_user_session()
        self._websocket_service.stop()
        self._login_view_model.resetAfterLogout()
        self._set_logged_out()
        self._show_toast("info", "已退出当前桌面会话")

    @Slot(str)
    def navigate(self, route: str) -> None:
        if route not in ROUTES or route == self._current_route:
            return
        self._current_route = route
        self.currentRouteChanged.emit()
        self.windowTitleChanged.emit()
        self._refresh_current_route()

    def _refresh_current_route(self) -> None:
        refresh = self._refreshers.get(self._current_route)
        if refresh:
            refresh()

    def _sync_downloads_refresh_timer(self) -> None:
        should_run = self._logged_in and self._connection_state == "disconnected"
        if should_run:
            self._downloads_refresh_timer.start()
            return
        self._downloads_refresh_timer.stop()

    def _refresh_downloads_when_disconnected(self) -> None:
        if not self._logged_in or self._connection_state != "disconnected":
            return
        refresh = self._refreshers.get("downloads")
        if refresh:
            refresh()

    @Slot("QVariantMap")
    def handle_status_message(self, payload: dict[str, Any]) -> None:
        if not isinstance(payload, dict):
            return
        for consume in self._status_consumers.values():
            consume(dict(payload))

    def get_current_route(self) -> str:
        return self._current_route

    def get_current_route_index(self) -> int:
        return list(ROUTES).index(self._current_route)

    def get_logged_in(self) -> bool:
        return self._logged_in

    def get_user_display_name(self) -> str:
        return self._user_display_name

    def get_connection_state(self) -> str:
        return self._connection_state

    def get_window_title(self) -> str:
        title = ROUTE_TITLES.get(self._current_route, APP_NAME)
        return f"{APP_NAME} · {title}"

    currentRoute = Property(str, get_current_route, notify=currentRouteChanged)
    currentRouteIndex = Property(int, get_current_route_index, notify=currentRouteChanged)
    loggedIn = Property(bool, get_logged_in, notify=loggedInChanged)
    userDisplayName = Property(str, get_user_display_name, notify=userDisplayNameChanged)
    connectionState = Property(str, get_connection_state, notify=connectionStateChanged)
    windowTitle = Property(str, get_window_title, notify=windowTitleChanged)
