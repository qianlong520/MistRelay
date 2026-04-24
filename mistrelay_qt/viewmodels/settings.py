from __future__ import annotations

from typing import Any

from PySide6.QtCore import Property, QCoreApplication, QTimer, Signal, Slot

from ..formatters import format_bytes
from ..models import DownloadedUpdate, UpdateInfo
from ..task_runner import TaskRunner
from .base import BaseViewModel


class SettingsViewModel(BaseViewModel):
    updateProgressReported = Signal(int, int, bool)

    serverBaseUrlChanged = Signal()
    proxyEnabledChanged = Signal()
    proxyUrlChanged = Signal()
    downloadDirChanged = Signal()
    maxConcurrentDownloadsChanged = Signal()
    threadsPerDownloadChanged = Signal()
    cacheDirChanged = Signal()
    cacheStatsChanged = Signal()
    cacheItemsTextChanged = Signal()

    updateStateChanged = Signal()
    updateNotesChanged = Signal()
    manualUrlChanged = Signal()
    updateVersionChanged = Signal()
    updateAvailableChanged = Signal()
    canInstallUpdateChanged = Signal()
    updateProgressPercentChanged = Signal()



    def __init__(
        self,
        *,
        api_client,
        config_service,
        local_cache_service,
        local_runtime_service,
        update_service,
        task_runner: TaskRunner,
    ) -> None:
        super().__init__()
        self._api_client = api_client
        self._config_service = config_service
        self._local_cache_service = local_cache_service
        self._local_runtime_service = local_runtime_service
        self._update_service = update_service
        self._task_runner = task_runner

        config = self._config_service.config
        self._server_base_url = config.server_base_url
        self._proxy_enabled = config.proxy.enabled
        self._proxy_url = config.proxy.url
        self._download_dir = (
            config.download.download_dir
            or self._local_runtime_service.get_default_download_dir()
        )
        self._max_concurrent_downloads = config.download.max_concurrent_downloads
        self._threads_per_download = config.download.threads_per_download
        self._cache_dir = config.cache.cache_dir or str(self._local_cache_service.cache_root())
        self._cache_total_size = 0
        self._cache_file_count = 0
        self._cache_item_count = 0
        self._cache_items_text = ""

        self._update_state = "灏氭湭妫€鏌ユ洿鏂?"
        self._update_notes = ""
        self._manual_url = ""
        self._update_version = ""
        self._update_available = False
        self._can_install_update = False
        self._update_progress_percent = -1
        self._pending_update: UpdateInfo | None = None

        self._bootstrapped = False
        self.updateProgressReported.connect(self._apply_update_progress)

    @Slot()
    def bootstrap(self) -> None:
        self._bootstrapped = True
        self.refreshCacheStats()

    def shutdown(self) -> None:
        pass

    def consume_status_event(self, payload: dict[str, Any]) -> None:
        pass

    def get_server_base_url(self) -> str:
        return self._server_base_url

    def get_proxy_enabled(self) -> bool:
        return self._proxy_enabled

    def get_proxy_url(self) -> str:
        return self._proxy_url

    def get_download_dir(self) -> str:
        return self._download_dir

    def get_max_concurrent_downloads(self) -> int:
        return self._max_concurrent_downloads

    def get_threads_per_download(self) -> int:
        return self._threads_per_download

    def get_cache_dir(self) -> str:
        return self._cache_dir

    def get_cache_total_size(self) -> str:
        return format_bytes(self._cache_total_size)

    def get_cache_file_count(self) -> int:
        return self._cache_file_count

    def get_cache_item_count(self) -> int:
        return self._cache_item_count

    def get_cache_items_text(self) -> str:
        return self._cache_items_text or "暂无本地缓存文件"
    def get_update_state(self) -> str:
        return self._update_state

    def get_update_notes(self) -> str:
        return self._update_notes

    def get_manual_url(self) -> str:
        return self._manual_url

    def get_update_version(self) -> str:
        return self._update_version

    def get_update_available(self) -> bool:
        return self._update_available

    def get_can_install_update(self) -> bool:
        return self._can_install_update

    def get_update_progress_percent(self) -> int:
        return self._update_progress_percent

    @Slot(str)
    def setServerBaseUrl(self, value: str) -> None:
        normalized = value.strip().rstrip("/")
        if normalized == self._server_base_url:
            return
        self._server_base_url = normalized
        self.serverBaseUrlChanged.emit()

    @Slot(bool)
    def setProxyEnabled(self, value: bool) -> None:
        if value == self._proxy_enabled:
            return
        self._proxy_enabled = value
        self.proxyEnabledChanged.emit()

    @Slot(str)
    def setProxyUrl(self, value: str) -> None:
        normalized = value.strip()
        if normalized == self._proxy_url:
            return
        self._proxy_url = normalized
        self.proxyUrlChanged.emit()

    @Slot(str)
    def setDownloadDir(self, value: str) -> None:
        normalized = value.strip()
        if normalized == self._download_dir:
            return
        self._download_dir = normalized
        self.downloadDirChanged.emit()

    @Slot(int)
    def setMaxConcurrentDownloads(self, value: int) -> None:
        normalized = max(1, int(value))
        if normalized == self._max_concurrent_downloads:
            return
        self._max_concurrent_downloads = normalized
        self.maxConcurrentDownloadsChanged.emit()

    @Slot(int)
    def setThreadsPerDownload(self, value: int) -> None:
        normalized = max(1, int(value))
        if normalized == self._threads_per_download:
            return
        self._threads_per_download = normalized
        self.threadsPerDownloadChanged.emit()

    @Slot(str)
    def setCacheDir(self, value: str) -> None:
        normalized = value.strip()
        if normalized == self._cache_dir:
            return
        self._cache_dir = normalized
        self.cacheDirChanged.emit()
    @Slot()
    def save(self) -> None:
        self._config_service.update_runtime_settings(
            server_base_url=self._server_base_url,
            proxy_enabled=self._proxy_enabled,
            proxy_url=self._proxy_url,
            download_dir=self._download_dir,
            max_concurrent_downloads=self._max_concurrent_downloads,
            threads_per_download=self._threads_per_download,
            cache_dir=self._cache_dir,
        )
        self._show_toast("success", "瀹㈡埛绔缃凡淇濆瓨")
        self.refreshCacheStats()
    @Slot()
    def pickDownloadDir(self) -> None:
        selected = self._local_runtime_service.pick_download_dir(self._download_dir)
        if selected and selected != self._download_dir:
            self._download_dir = selected
            self.downloadDirChanged.emit()


    @Slot()
    def pickCacheDir(self) -> None:
        selected = self._local_runtime_service.pick_cache_dir(self._cache_dir)
        if selected and selected != self._cache_dir:
            self._cache_dir = selected
            self.cacheDirChanged.emit()

    @Slot()
    def saveCacheSettings(self) -> None:
        self._config_service.update_cache_dir(self._cache_dir)
        self._show_toast("success", "本地缓存目录已保存")
        self.refreshCacheStats()

    @Slot()
    def refreshCacheStats(self) -> None:
        scan = self._local_cache_service.scan()
        self._cache_total_size = int(scan.get("totalSize") or 0)
        self._cache_file_count = int(scan.get("fileCount") or 0)
        self._cache_item_count = int(scan.get("itemCount") or 0)
        items = scan.get("items") or []
        lines = []
        for item in items[:50]:
            lines.append(f"{item.get('name')} · {format_bytes(item.get('size'))}")
        if len(items) > 50:
            lines.append(f"还有 {len(items) - 50} 个缓存文件未显示")
        self._cache_items_text = "\n".join(lines)
        self.cacheStatsChanged.emit()
        self.cacheItemsTextChanged.emit()

    @Slot()
    def clearCache(self) -> None:
        before = self._local_cache_service.clear()
        self.refreshCacheStats()
        self._show_toast("success", f"已清除 {format_bytes(before.get('totalSize'))} 本地缓存")

    @Slot()
    def openCacheDir(self) -> None:
        self._local_cache_service.open_cache_root()
    @Slot()
    def checkForUpdates(self) -> None:
        if self._busy:
            return
        self._set_busy(True)
        self._update_progress_percent = -1
        self.updateProgressPercentChanged.emit()
        self._update_state = "姝ｅ湪妫€鏌ユ洿鏂?"
        self.updateStateChanged.emit()
        self._task_runner.submit(
            self._update_service.check_for_updates,
            on_success=self._apply_update_result,
            on_error=self._apply_update_error,
        )

    @Slot()
    def installUpdate(self) -> None:
        if self._busy:
            return
        if not self._pending_update or not self._pending_update.installable:
            self._set_error_message("褰撳墠娌℃湁鍙洿鎺ュ畨瑁呯殑鏇存柊")
            return
        self._set_busy(True)
        self._update_progress_percent = 0
        self.updateProgressPercentChanged.emit()
        self._update_state = f"姝ｅ湪涓嬭浇 v{self._pending_update.version}"
        self.updateStateChanged.emit()
        self._task_runner.submit(
            self._download_and_install_update,
            on_success=self._apply_install_result,
            on_error=self._apply_update_error,
        )

    def _download_and_install_update(self) -> DownloadedUpdate:
        assert self._pending_update is not None
        downloaded = self._update_service.download_update(
            self._pending_update,
            on_progress=lambda downloaded_bytes, total_bytes, done: self.updateProgressReported.emit(
                int(downloaded_bytes),
                int(total_bytes or 0),
                bool(done),
            ),
        )
        self._update_service.install_update(downloaded)
        return downloaded

    def _apply_update_result(self, info: UpdateInfo) -> None:
        self._set_busy(False)
        self._pending_update = info if info.available else None
        self._update_version = info.version
        self._update_available = info.available
        self._can_install_update = bool(info.installable)
        self._update_state = info.message or ("?????" if info.available else "????????")
        notes = info.notes
        if info.download_url:
            notes = "\n".join(filter(None, [notes, f"?????{info.download_url}"]))
        self._update_notes = notes
        self._manual_url = info.manual_url
        self.updateVersionChanged.emit()
        self.updateAvailableChanged.emit()
        self.canInstallUpdateChanged.emit()
        self.updateStateChanged.emit()
        self.updateNotesChanged.emit()
        self.manualUrlChanged.emit()

    def _apply_update_error(self, message: str) -> None:
        self._set_busy(False)
        self._update_state = f"?????{message}"
        self.updateStateChanged.emit()

    def _apply_install_result(self, downloaded: DownloadedUpdate) -> None:
        self._set_busy(False)
        self._update_state = f"??? {downloaded.version}??????????"
        self.updateStateChanged.emit()
        self._show_toast("success", "????????????????")
        QTimer.singleShot(250, QCoreApplication.quit)

    def _apply_update_progress(self, downloaded: int, total: int, done: bool) -> None:
        if total > 0:
            self._update_progress_percent = max(0, min(100, round((downloaded / total) * 100)))
        elif done:
            self._update_progress_percent = 100
        else:
            self._update_progress_percent = 0
        self.updateProgressPercentChanged.emit()
        if done:
            self._update_state = "涓嬭浇瀹屾垚锛屾鍦ㄥ噯澶囧畨瑁?"
        else:
            self._update_state = f"姝ｅ湪涓嬭浇鏇存柊鈥?{format_bytes(downloaded)} / {format_bytes(total)}"
        self.updateStateChanged.emit()

    @Slot()
    def openManualUpdateUrl(self) -> None:
        if self._manual_url:
            self._local_runtime_service.open_external_url(self._manual_url)

    serverBaseUrl = Property(str, get_server_base_url, notify=serverBaseUrlChanged)
    proxyEnabled = Property(bool, get_proxy_enabled, notify=proxyEnabledChanged)
    proxyUrl = Property(str, get_proxy_url, notify=proxyUrlChanged)
    downloadDir = Property(str, get_download_dir, notify=downloadDirChanged)
    maxConcurrentDownloads = Property(int, get_max_concurrent_downloads, notify=maxConcurrentDownloadsChanged)
    threadsPerDownload = Property(int, get_threads_per_download, notify=threadsPerDownloadChanged)
    cacheDir = Property(str, get_cache_dir, notify=cacheDirChanged)
    cacheTotalSize = Property(str, get_cache_total_size, notify=cacheStatsChanged)
    cacheFileCount = Property(int, get_cache_file_count, notify=cacheStatsChanged)
    cacheItemCount = Property(int, get_cache_item_count, notify=cacheStatsChanged)
    cacheItemsText = Property(str, get_cache_items_text, notify=cacheItemsTextChanged)

    updateState = Property(str, get_update_state, notify=updateStateChanged)
    updateNotes = Property(str, get_update_notes, notify=updateNotesChanged)
    manualUrl = Property(str, get_manual_url, notify=manualUrlChanged)
    updateVersion = Property(str, get_update_version, notify=updateVersionChanged)
    updateAvailable = Property(bool, get_update_available, notify=updateAvailableChanged)
    canInstallUpdate = Property(bool, get_can_install_update, notify=canInstallUpdateChanged)
    updateProgressPercent = Property(int, get_update_progress_percent, notify=updateProgressPercentChanged)




