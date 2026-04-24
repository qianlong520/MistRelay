from __future__ import annotations

from PySide6.QtCore import Property, QCoreApplication, QTimer, Signal, Slot

from ..formatters import format_bytes
from ..models import DownloadedUpdate, UpdateInfo
from ..task_runner import TaskRunner
from .base import BaseViewModel


class UpdateViewModel(BaseViewModel):
    updateProgressReported = Signal(int, int, bool)

    updateStateChanged = Signal()
    updateNotesChanged = Signal()
    manualUrlChanged = Signal()
    updateVersionChanged = Signal()
    updateAvailableChanged = Signal()
    canInstallUpdateChanged = Signal()
    updateProgressPercentChanged = Signal()
    promptVisibleChanged = Signal()

    def __init__(
        self,
        *,
        update_service,
        local_runtime_service,
        task_runner: TaskRunner,
    ) -> None:
        super().__init__()
        self._update_service = update_service
        self._local_runtime_service = local_runtime_service
        self._task_runner = task_runner

        self._update_state = "尚未检查更新"
        self._update_notes = ""
        self._manual_url = ""
        self._update_version = ""
        self._update_available = False
        self._can_install_update = False
        self._update_progress_percent = -1
        self._prompt_visible = False
        self._startup_checked = False
        self._prompt_on_available = False
        self._pending_update: UpdateInfo | None = None

        self.updateProgressReported.connect(self._apply_update_progress)

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

    def get_prompt_visible(self) -> bool:
        return self._prompt_visible

    def _set_prompt_visible(self, value: bool) -> None:
        if self._prompt_visible == value:
            return
        self._prompt_visible = value
        self.promptVisibleChanged.emit()

    def _begin_update_check(self, *, prompt_on_available: bool) -> None:
        if self._busy:
            return
        self._prompt_on_available = prompt_on_available
        self._set_busy(True)
        self._update_progress_percent = -1
        self.updateProgressPercentChanged.emit()
        self._update_state = "正在检查更新"
        self.updateStateChanged.emit()
        self._task_runner.submit(
            self._update_service.check_for_updates,
            on_success=self._apply_update_result,
            on_error=self._apply_update_error,
        )

    @Slot()
    def startupCheck(self) -> None:
        if self._startup_checked:
            return
        self._startup_checked = True
        self._begin_update_check(prompt_on_available=True)

    @Slot()
    def checkForUpdates(self) -> None:
        self._begin_update_check(prompt_on_available=False)

    @Slot()
    def dismissPrompt(self) -> None:
        if self._busy:
            return
        self._set_prompt_visible(False)
        if self._update_available:
            self._update_state = (
                f"发现新版本 v{self._update_version}，可在设置页或下次启动时继续安装"
            )
            self.updateStateChanged.emit()

    @Slot()
    def installUpdate(self) -> None:
        if self._busy:
            return
        if not self._pending_update or not self._pending_update.installable:
            self._set_error_message("当前没有可自动安装的更新")
            return
        self._set_busy(True)
        self._update_progress_percent = 0
        self.updateProgressPercentChanged.emit()
        self._update_state = f"正在下载 v{self._pending_update.version}"
        self.updateStateChanged.emit()
        self._task_runner.submit(
            self._download_and_install_update,
            on_success=self._apply_install_result,
            on_error=self._apply_update_error,
        )

    def _download_and_install_update(self) -> DownloadedUpdate:
        assert self._pending_update is not None
        if self._pending_update.patch_available:
            downloaded_patch = self._update_service.download_patch(
                self._pending_update,
                on_progress=lambda downloaded_bytes, total_bytes, done: self.updateProgressReported.emit(
                    int(downloaded_bytes),
                    int(total_bytes or 0),
                    bool(done),
                ),
            )
            self._update_service.apply_patch_update(downloaded_patch)
            return DownloadedUpdate(
                version=downloaded_patch.version,
                installer_path=downloaded_patch.patch_path,
                download_url=downloaded_patch.download_url,
                sha256=downloaded_patch.sha256,
                size=downloaded_patch.size,
            )

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

        notes = info.notes
        if info.download_url:
            notes = "\n".join(filter(None, [notes, f"下载地址：{info.download_url}"]))
        self._update_notes = notes
        self._manual_url = info.manual_url

        show_prompt = self._prompt_on_available and info.available and info.installable
        self._prompt_on_available = False
        if show_prompt:
            self._set_prompt_visible(True)
            if info.patch_available:
                self._update_state = f"\u53d1\u73b0\u6587\u4ef6\u70ed\u66f4 v{info.version}\uff0c\u7b49\u5f85\u786e\u8ba4\u5e94\u7528"
            else:
                self._update_state = f"\u53d1\u73b0\u65b0\u7248\u672c v{info.version}\uff0c\u7b49\u5f85\u786e\u8ba4\u5b89\u88c5"
        else:
            self._set_prompt_visible(False)
            self._update_state = info.message or ("\u53d1\u73b0\u65b0\u7248\u672c" if info.available else "\u5f53\u524d\u5df2\u662f\u6700\u65b0\u7248\u672c")

        self.updateVersionChanged.emit()
        self.updateAvailableChanged.emit()
        self.canInstallUpdateChanged.emit()
        self.updateStateChanged.emit()
        self.updateNotesChanged.emit()
        self.manualUrlChanged.emit()

    def _apply_update_error(self, message: str) -> None:
        self._set_busy(False)
        self._prompt_on_available = False
        self._update_state = f"更新失败：{message}"
        self.updateStateChanged.emit()

    def _apply_install_result(self, downloaded: DownloadedUpdate) -> None:
        self._set_busy(False)
        if downloaded.installer_path.suffix.lower() == ".zip":
            self._update_state = f"\u6587\u4ef6\u70ed\u66f4 v{downloaded.version} \u5df2\u5e94\u7528\uff0c\u90e8\u5206\u6587\u4ef6\u53ef\u80fd\u9700\u8981\u91cd\u542f\u540e\u751f\u6548"
            self.updateStateChanged.emit()
            self._set_info_message("\u6587\u4ef6\u70ed\u66f4\u5df2\u5e94\u7528")
            return

        self._update_state = f"\u5df2\u4e0b\u8f7d {downloaded.version}\uff0c\u6b63\u5728\u9759\u9ed8\u5b89\u88c5\u5e76\u91cd\u542f"
        self.updateStateChanged.emit()
        self._set_info_message("\u66f4\u65b0\u5b89\u88c5\u5668\u5df2\u542f\u52a8\uff0c\u5ba2\u6237\u7aef\u5373\u5c06\u91cd\u542f")
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
            self._update_state = "下载完成，正在准备安装"
        else:
            self._update_state = f"正在下载更新… {format_bytes(downloaded)} / {format_bytes(total)}"
        self.updateStateChanged.emit()

    @Slot()
    def openManualUpdateUrl(self) -> None:
        if self._manual_url:
            self._local_runtime_service.open_external_url(self._manual_url)

    updateState = Property(str, get_update_state, notify=updateStateChanged)
    updateNotes = Property(str, get_update_notes, notify=updateNotesChanged)
    manualUrl = Property(str, get_manual_url, notify=manualUrlChanged)
    updateVersion = Property(str, get_update_version, notify=updateVersionChanged)
    updateAvailable = Property(bool, get_update_available, notify=updateAvailableChanged)
    canInstallUpdate = Property(bool, get_can_install_update, notify=canInstallUpdateChanged)
    updateProgressPercent = Property(int, get_update_progress_percent, notify=updateProgressPercentChanged)
    promptVisible = Property(bool, get_prompt_visible, notify=promptVisibleChanged)
