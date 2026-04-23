from __future__ import annotations

from datetime import datetime
from typing import Any

from PySide6.QtCore import Property, Signal, Slot

from ..formatters import format_bytes, format_datetime
from ..task_runner import TaskRunner
from .base import BaseViewModel


class DashboardViewModel(BaseViewModel):
    statCardsChanged = Signal()
    resourceCardsChanged = Signal()
    systemInfoChanged = Signal()
    trendPointsChanged = Signal()
    recentDownloadsChanged = Signal()
    botLoadRowsChanged = Signal()
    trendSummaryChanged = Signal()
    lastUpdatedChanged = Signal()
    subtitleChanged = Signal()
    serverBaseUrlChanged = Signal()
    userRoleChanged = Signal()

    def __init__(self, *, api_client, config_service=None, task_runner: TaskRunner) -> None:
        super().__init__()
        self._api_client = api_client
        self._config_service = config_service
        self._task_runner = task_runner
        self._stat_cards: list[dict[str, Any]] = []
        self._resource_cards: list[dict[str, Any]] = []
        self._system_info: list[dict[str, Any]] = []
        self._trend_points: list[dict[str, Any]] = []
        self._recent_downloads: list[dict[str, Any]] = []
        self._bot_load_rows: list[dict[str, Any]] = []
        self._trend_summary = "等待获取实时监控数据"
        self._last_updated = ""
        self._subtitle = "首页会显示服务状态、近期任务与资源负载。"
        self._server_base_url = ""
        self._user_role = ""
        self._refresh_scheduled = False
        self._load_local_context()

    def _load_local_context(self) -> None:
        if not self._config_service:
            return
        config = self._config_service.config
        self._server_base_url = str(config.server_base_url or "")
        self._user_role = self._role_label(str(config.user.role or ""))

    def get_stat_cards(self) -> list[dict[str, Any]]:
        return self._stat_cards

    def get_resource_cards(self) -> list[dict[str, Any]]:
        return self._resource_cards

    def get_system_info(self) -> list[dict[str, Any]]:
        return self._system_info

    def get_trend_points(self) -> list[dict[str, Any]]:
        return self._trend_points

    def get_recent_downloads(self) -> list[dict[str, Any]]:
        return self._recent_downloads

    def get_bot_load_rows(self) -> list[dict[str, Any]]:
        return self._bot_load_rows

    def get_trend_summary(self) -> str:
        return self._trend_summary

    def get_last_updated(self) -> str:
        return self._last_updated

    def get_subtitle(self) -> str:
        return self._subtitle

    def get_server_base_url(self) -> str:
        return self._server_base_url

    def get_user_role(self) -> str:
        return self._user_role

    @Slot()
    def refresh(self) -> None:
        if self._busy:
            return
        self._set_busy(True)
        self._set_error_message("")
        self._subtitle = "正在刷新首页数据"
        self.subtitleChanged.emit()
        self._load_local_context()
        self.serverBaseUrlChanged.emit()
        self.userRoleChanged.emit()
        self._task_runner.submit(self._load_snapshot, on_success=self._apply_snapshot, on_error=self._apply_error)

    def _load_snapshot(self) -> dict[str, Any]:
        status = self._api_client.get_status()
        downloads = self._api_client.get_download_statistics()
        queue = self._api_client.get_queue_status()
        resources = self._api_client.get_system_resources()
        trend = self._api_client.get_system_trend()
        recent = self._api_client.get_downloads(limit=8, grouped=False)
        return {
            "status": status,
            "downloads": downloads,
            "queue": queue,
            "resources": resources,
            "trend": trend,
            "recent": recent,
        }

    def _apply_snapshot(self, payload: dict[str, Any]) -> None:
        self._refresh_scheduled = False
        self._set_busy(False)
        status = payload.get("status") or {}
        download_stats = (payload.get("downloads") or {}).get("data") or {}
        queue_stats = payload.get("queue") or {}
        resources = (payload.get("resources") or {}).get("data") or {}
        trend_points = (payload.get("trend") or {}).get("data") or []
        recent_records = (payload.get("recent") or {}).get("data") or []

        completed_count = int(download_stats.get("completed", 0))
        pending_count = int(download_stats.get("pending", 0))
        failed_count = int(download_stats.get("failed", 0))
        total_count = int(download_stats.get("total", 0))

        self._stat_cards = [
            {
                "title": "完成",
                "value": str(completed_count),
                "caption": "已完成任务",
                "tone": "success",
                "glyph": "✓",
            },
            {
                "title": "清理",
                "value": str(pending_count),
                "caption": "待处理任务",
                "tone": "info",
                "glyph": "⌧",
            },
            {
                "title": "失败",
                "value": str(failed_count),
                "caption": "异常任务",
                "tone": "danger",
                "glyph": "!",
            },
            {
                "title": "总计",
                "value": str(total_count),
                "caption": "历史任务数",
                "tone": "primary",
                "glyph": "▣",
            },
        ]
        self._resource_cards = self._build_resource_cards(resources)
        self._system_info = [
            {"label": "运行状态", "value": str(status.get("server_status") or "running"), "tone": "success"},
            {"label": "运行时长", "value": str(status.get("uptime") or "-"), "tone": "primary"},
            {"label": "Telegram Bot", "value": str(status.get("telegram_bot") or "@unknown"), "tone": "primary"},
            {"label": "已连接机器人", "value": str(status.get("connected_bots") or 0), "tone": "primary"},
            {"label": "队列大小", "value": str(queue_stats.get("queue_size") or 0), "tone": "warning"},
            {"label": "版本", "value": str(status.get("version") or "-"), "tone": "primary"},
        ]
        self._trend_points = self._build_trend_points(trend_points)
        self._recent_downloads = self._build_recent_download_rows(recent_records)
        self._bot_load_rows = self._build_bot_load_rows(status)
        self._trend_summary = self._build_trend_summary(self._trend_points)
        self._last_updated = datetime.now().strftime("%Y-%m-%d %H:%M:%S")
        self._subtitle = "服务状态、系统资源和近期任务已经同步到首页。"
        self._load_local_context()

        self.statCardsChanged.emit()
        self.resourceCardsChanged.emit()
        self.systemInfoChanged.emit()
        self.trendPointsChanged.emit()
        self.recentDownloadsChanged.emit()
        self.botLoadRowsChanged.emit()
        self.trendSummaryChanged.emit()
        self.lastUpdatedChanged.emit()
        self.subtitleChanged.emit()
        self.serverBaseUrlChanged.emit()
        self.userRoleChanged.emit()

    def _apply_error(self, message: str) -> None:
        self._refresh_scheduled = False
        self._set_busy(False)
        self._set_error_message(message)
        self._subtitle = "首页数据拉取失败"
        self.subtitleChanged.emit()

    def consume_status_event(self, payload: dict[str, Any]) -> None:
        return

    def _build_resource_cards(self, resources: dict[str, Any]) -> list[dict[str, Any]]:
        cpu = resources.get("cpu") or {}
        memory = resources.get("memory") or {}
        disk = resources.get("disk") or {}
        return [
            {
                "title": "CPU",
                "value": f"{float(cpu.get('percent') or 0):.1f}%",
                "caption": "系统实时占用",
                "detail": "",
                "tone": self._resource_tone(float(cpu.get("percent") or 0)),
                "percent": float(cpu.get("percent") or 0),
            },
            {
                "title": "内存",
                "value": f"{float(memory.get('percent') or 0):.1f}%",
                "caption": f"{format_bytes(memory.get('used'))} / {format_bytes(memory.get('total'))}",
                "detail": "",
                "tone": self._resource_tone(float(memory.get("percent") or 0)),
                "percent": float(memory.get("percent") or 0),
            },
            {
                "title": "硬盘",
                "value": f"{float(disk.get('percent') or 0):.1f}%",
                "caption": f"{format_bytes(disk.get('used'))} / {format_bytes(disk.get('total'))}",
                "detail": "",
                "tone": self._resource_tone(float(disk.get("percent") or 0)),
                "percent": float(disk.get("percent") or 0),
            },
        ]

    def _build_trend_points(self, trend_points: list[dict[str, Any]]) -> list[dict[str, Any]]:
        if not trend_points:
            return []

        trimmed = trend_points[-20:]
        max_value = 1
        for point in trimmed:
            max_value = max(
                max_value,
                int(point.get("upload") or 0),
                int(point.get("download") or 0),
                int(point.get("io") or 0),
            )

        result: list[dict[str, Any]] = []
        count = len(trimmed)
        for index, point in enumerate(trimmed):
            timestamp = point.get("timestamp")
            label = self._format_trend_time(timestamp)
            ratio_base = index / max(1, count - 1)
            result.append(
                {
                    "label": label,
                    "upload": int(point.get("upload") or 0),
                    "download": int(point.get("download") or 0),
                    "io": int(point.get("io") or 0),
                    "xRatio": ratio_base,
                    "uploadRatio": min(1.0, float(point.get("upload") or 0) / max_value),
                    "downloadRatio": min(1.0, float(point.get("download") or 0) / max_value),
                    "ioRatio": min(1.0, float(point.get("io") or 0) / max_value),
                }
            )
        return result

    def _build_recent_download_rows(self, records: list[dict[str, Any]]) -> list[dict[str, Any]]:
        rows: list[dict[str, Any]] = []
        for record in records[:7]:
            status = str(record.get("status") or "pending")
            title = str(record.get("file_name") or record.get("caption") or record.get("gid") or "未命名文件")
            time_value = (
                record.get("completed_at")
                or record.get("updated_at")
                or record.get("created_at")
            )
            rows.append(
                {
                    "title": title,
                    "status": self._download_status_label(status),
                    "statusTone": self._download_status_tone(status),
                    "time": format_datetime(str(time_value or "")),
                }
            )
        return rows

    def _build_bot_load_rows(self, status: dict[str, Any]) -> list[dict[str, Any]]:
        bot_loads = status.get("loads") or {}
        rows: list[dict[str, Any]] = []
        for key in sorted(bot_loads.keys()):
            load_value = float(bot_loads.get(key) or 0)
            rows.append(
                {
                    "label": key,
                    "value": f"{load_value:.0f}",
                    "percent": min(100.0, max(0.0, load_value)),
                    "tone": self._resource_tone(load_value),
                }
            )
        return rows

    def _build_trend_summary(self, trend_points: list[dict[str, Any]]) -> str:
        if not trend_points:
            return "监控数据还没有开始采样"
        latest = trend_points[-1]
        return (
            f"上传 {format_bytes(latest['upload'])}/s · "
            f"下载 {format_bytes(latest['download'])}/s · "
            f"IO {format_bytes(latest['io'])}/s"
        )

    def _format_trend_time(self, timestamp: Any) -> str:
        try:
            value = int(timestamp or 0) / 1000
            return datetime.fromtimestamp(value).strftime("%H:%M:%S")
        except (TypeError, ValueError, OSError):
            return "--:--:--"

    def _download_status_label(self, status: str) -> str:
        return {
            "completed": "已完成",
            "downloading": "下载中",
            "pending": "等待中",
            "failed": "失败",
        }.get(status, status)

    def _download_status_tone(self, status: str) -> str:
        return {
            "completed": "success",
            "downloading": "warning",
            "pending": "info",
            "failed": "danger",
        }.get(status, "info")

    def _role_label(self, role: str) -> str:
        normalized = role.lower()
        if normalized in {"admin", "administrator"}:
            return "系统管理员"
        if normalized:
            return role
        return "系统管理员"

    def _resource_tone(self, percent: float) -> str:
        if percent >= 85:
            return "danger"
        if percent >= 65:
            return "warning"
        if percent > 0:
            return "success"
        return "success"

    statCards = Property("QVariantList", get_stat_cards, notify=statCardsChanged)
    resourceCards = Property("QVariantList", get_resource_cards, notify=resourceCardsChanged)
    systemInfo = Property("QVariantList", get_system_info, notify=systemInfoChanged)
    trendPoints = Property("QVariantList", get_trend_points, notify=trendPointsChanged)
    recentDownloads = Property("QVariantList", get_recent_downloads, notify=recentDownloadsChanged)
    botLoadRows = Property("QVariantList", get_bot_load_rows, notify=botLoadRowsChanged)
    trendSummary = Property(str, get_trend_summary, notify=trendSummaryChanged)
    lastUpdated = Property(str, get_last_updated, notify=lastUpdatedChanged)
    subtitle = Property(str, get_subtitle, notify=subtitleChanged)
    serverBaseUrl = Property(str, get_server_base_url, notify=serverBaseUrlChanged)
    userRole = Property(str, get_user_role, notify=userRoleChanged)
