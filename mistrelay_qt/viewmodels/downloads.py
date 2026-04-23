from __future__ import annotations

from datetime import datetime
from typing import Any

from PySide6.QtCore import QObject, Property, QTimer, Signal, Slot

from ..formatters import format_bytes, format_datetime, format_progress, format_speed
from ..list_models import RoleListModel
from ..task_runner import TaskRunner
from .base import BaseViewModel


class DownloadsViewModel(BaseViewModel):
    summaryCardsChanged = Signal()
    currentTabChanged = Signal()
    headlineChanged = Signal()
    runtimeNoteChanged = Signal()
    taskKeywordChanged = Signal()
    taskStatusFilterChanged = Signal()
    queueKeywordChanged = Signal()
    queueTypeFilterChanged = Signal()
    localKeywordChanged = Signal()
    localStatusFilterChanged = Signal()
    queueFloodWaitTextChanged = Signal()
    taskFilterSummaryChanged = Signal()
    queueFilterSummaryChanged = Signal()
    localFilterSummaryChanged = Signal()
    unifiedKeywordChanged = Signal()
    unifiedStatusFilterChanged = Signal()
    unifiedFilterSummaryChanged = Signal()
    taskSectionChanged = Signal()

    def __init__(self, *, api_client, local_runtime_service, task_runner: TaskRunner) -> None:
        super().__init__()
        self._api_client = api_client
        self._local_runtime_service = local_runtime_service
        self._task_runner = task_runner

        self._current_tab = "tasks"
        self._summary_cards: list[dict[str, Any]] = []
        self._headline = "任务中心已接入真实数据模型。"
        self._runtime_note = "本地下载、任务队列和服务端记录统一由 Python 状态层驱动。"
        self._task_keyword = ""
        self._task_status_filter = "all"
        self._queue_keyword = ""
        self._queue_type_filter = "all"
        self._local_keyword = ""
        self._local_status_filter = "all"
        self._queue_flood_wait_text = ""
        self._task_filter_summary = ""
        self._queue_filter_summary = ""
        self._local_filter_summary = ""
        self._unified_keyword = ""
        self._unified_status_filter = "all"
        self._unified_filter_summary = ""
        self._task_section = "server"
        self._limit = 100
        self._refresh_scheduled = False

        self._download_groups: list[dict[str, Any]] = []
        self._upload_records: list[dict[str, Any]] = []
        self._queue_snapshot: dict[str, Any] = {}
        self._download_statistics: dict[str, Any] = {}
        self._upload_statistics: dict[str, Any] = {}
        self._local_transfers: dict[str, dict[str, Any]] = {}

        self._active_downloads_model = RoleListModel()
        self._active_uploads_model = RoleListModel()
        self._group_records_model = RoleListModel()
        self._queue_current_model = RoleListModel()
        self._queue_waiting_model = RoleListModel()
        self._local_downloads_model = RoleListModel()
        self._unified_task_flow_model = RoleListModel()
        self._visible_task_flow_model = RoleListModel()

        self._local_runtime_service.transferUpdated.connect(self._handle_transfer_update)
        for item in self._local_runtime_service.list_download_statuses():
            self._local_transfers[item["transferId"]] = item
        self._rebuild_models()

    def get_summary_cards(self) -> list[dict[str, Any]]:
        return self._summary_cards

    def get_current_tab(self) -> str:
        return self._current_tab

    def get_headline(self) -> str:
        return self._headline

    def get_runtime_note(self) -> str:
        return self._runtime_note

    def get_task_keyword(self) -> str:
        return self._task_keyword

    def get_task_status_filter(self) -> str:
        return self._task_status_filter

    def get_queue_keyword(self) -> str:
        return self._queue_keyword

    def get_queue_type_filter(self) -> str:
        return self._queue_type_filter

    def get_local_keyword(self) -> str:
        return self._local_keyword

    def get_local_status_filter(self) -> str:
        return self._local_status_filter

    def get_queue_flood_wait_text(self) -> str:
        return self._queue_flood_wait_text

    def get_task_filter_summary(self) -> str:
        return self._task_filter_summary

    def get_queue_filter_summary(self) -> str:
        return self._queue_filter_summary

    def get_local_filter_summary(self) -> str:
        return self._local_filter_summary

    def get_unified_keyword(self) -> str:
        return self._unified_keyword

    def get_unified_status_filter(self) -> str:
        return self._unified_status_filter

    def get_unified_filter_summary(self) -> str:
        return self._unified_filter_summary

    def get_task_section(self) -> str:
        return self._task_section

    def get_active_downloads_model(self) -> QObject:
        return self._active_downloads_model

    def get_active_uploads_model(self) -> QObject:
        return self._active_uploads_model

    def get_group_records_model(self) -> QObject:
        return self._group_records_model

    def get_queue_current_model(self) -> QObject:
        return self._queue_current_model

    def get_queue_waiting_model(self) -> QObject:
        return self._queue_waiting_model

    def get_local_downloads_model(self) -> QObject:
        return self._local_downloads_model

    def get_unified_task_flow_model(self) -> QObject:
        return self._unified_task_flow_model

    def get_visible_task_flow_model(self) -> QObject:
        return self._visible_task_flow_model

    @Slot(str)
    def setCurrentTab(self, value: str) -> None:
        if value == self._current_tab:
            return
        self._current_tab = value
        self.currentTabChanged.emit()

    @Slot(str)
    def setTaskKeyword(self, value: str) -> None:
        self.setUnifiedKeyword(value)

    @Slot(str)
    def setTaskStatusFilter(self, value: str) -> None:
        self.setUnifiedStatusFilter(value)

    @Slot(str)
    def setQueueKeyword(self, value: str) -> None:
        self.setUnifiedKeyword(value)

    @Slot(str)
    def setQueueTypeFilter(self, value: str) -> None:
        mapped = "all"
        if value == "media_group":
            mapped = "group"
        elif value == "single":
            mapped = "download"
        self.setUnifiedStatusFilter(mapped)

    @Slot(str)
    def setLocalKeyword(self, value: str) -> None:
        self.setUnifiedKeyword(value)

    @Slot(str)
    def setLocalStatusFilter(self, value: str) -> None:
        self.setUnifiedStatusFilter(value)

    @Slot(str)
    def setUnifiedKeyword(self, value: str) -> None:
        normalized = value.strip()
        if normalized == self._unified_keyword:
            return
        self._unified_keyword = normalized
        self._task_keyword = normalized
        self._queue_keyword = normalized
        self._local_keyword = normalized
        self.unifiedKeywordChanged.emit()
        self.taskKeywordChanged.emit()
        self.queueKeywordChanged.emit()
        self.localKeywordChanged.emit()
        self._rebuild_models()

    @Slot(str)
    def setUnifiedStatusFilter(self, value: str) -> None:
        normalized = value or "all"
        if normalized == self._unified_status_filter:
            return
        self._unified_status_filter = normalized
        self._task_status_filter = normalized
        self._local_status_filter = normalized
        self._queue_type_filter = normalized
        self.unifiedStatusFilterChanged.emit()
        self.taskStatusFilterChanged.emit()
        self.localStatusFilterChanged.emit()
        self.queueTypeFilterChanged.emit()
        self._rebuild_models()

    @Slot(str)
    def setTaskSection(self, value: str) -> None:
        normalized = value or "server"
        if normalized not in {"server", "queue", "local"}:
            normalized = "server"
        if normalized == self._task_section:
            return
        self._task_section = normalized
        self.taskSectionChanged.emit()
        self._rebuild_models()

    @Slot()
    def refresh(self) -> None:
        if self._busy:
            return
        self._set_busy(True)
        self._set_error_message("")
        self._task_runner.submit(self._load_snapshot, on_success=self._apply_snapshot, on_error=self._apply_error)

    def _load_snapshot(self) -> dict[str, Any]:
        return {
            "downloads": self._api_client.get_downloads(limit=self._limit, grouped=True),
            "uploads": self._api_client.get_uploads(limit=self._limit),
            "queue": self._api_client.get_queue_status(),
            "download_stats": self._api_client.get_download_statistics(),
            "upload_stats": self._api_client.get_upload_statistics(),
        }

    def _apply_snapshot(self, payload: dict[str, Any]) -> None:
        self._refresh_scheduled = False
        self._set_busy(False)
        downloads_payload = payload.get("downloads") or {}
        uploads_payload = payload.get("uploads") or {}

        self._download_groups = list(downloads_payload.get("data") or [])
        self._upload_records = list(uploads_payload.get("data") or [])
        self._queue_snapshot = payload.get("queue") or {}
        self._download_statistics = (payload.get("download_stats") or {}).get("data") or {}
        self._upload_statistics = (payload.get("upload_stats") or {}).get("data") or {}

        self._headline = "任务中心已完成服务端任务、本地下载和队列快照接线。"
        self._runtime_note = "服务端任务快照和本地下载状态已同步，WebSocket 更新会自动触发局部刷新。"
        self.headlineChanged.emit()
        self.runtimeNoteChanged.emit()
        self._rebuild_models()

    def _apply_error(self, message: str) -> None:
        self._refresh_scheduled = False
        self._set_busy(False)
        self._set_error_message(message)
        self._headline = "任务中心数据拉取失败"
        self.headlineChanged.emit()

    def consume_status_event(self, payload: dict[str, Any]) -> None:
        message_type = str(payload.get("type") or "")
        if message_type not in {
            "initial",
            "download_update",
            "upload_update",
            "cleanup_update",
            "statistics_update",
        }:
            return
        if self._busy or self._refresh_scheduled:
            return
        self._refresh_scheduled = True
        QTimer.singleShot(500, self.refresh)

    def _rebuild_models(self) -> None:
        self._summary_cards = []
        self.summaryCardsChanged.emit()

        active_downloads = [
            self._normalize_active_download(group, record)
            for group in self._download_groups
            for record in group.get("downloads") or []
        ]
        active_uploads = [self._normalize_upload_record(record) for record in self._upload_records]
        group_records = [self._normalize_group_record(group) for group in self._download_groups]

        current_processing = self._queue_snapshot.get("current_processing")
        queue_current = []
        if current_processing:
            queue_current.append(
                self._normalize_queue_item(
                    current_processing,
                    state_label="处理中",
                    state_kind="processing",
                    waiting_index=0,
                )
            )

        queue_waiting = [
            self._normalize_queue_item(
                item,
                state_label=f"等待 {index + 1}",
                state_kind="waiting",
                waiting_index=index + 1,
            )
            for index, item in enumerate(self._queue_snapshot.get("waiting_items") or [])
        ]

        local_items = [self._normalize_local_transfer(item) for item in self._local_transfers.values()]

        self._queue_flood_wait_text = self._build_flood_wait_text()
        self.queueFloodWaitTextChanged.emit()

        filtered_downloads = [item for item in active_downloads if self._matches_task_item(item)]
        filtered_uploads = [item for item in active_uploads if self._matches_task_item(item)]
        filtered_groups = [item for item in group_records if self._matches_task_item(item)]
        filtered_queue_current = [item for item in queue_current if self._matches_queue_item(item)]
        filtered_queue_waiting = [item for item in queue_waiting if self._matches_queue_item(item)]
        filtered_local = [item for item in local_items if self._matches_local_item(item)]

        self._active_downloads_model.set_items(filtered_downloads)
        self._active_uploads_model.set_items(filtered_uploads)
        self._group_records_model.set_items(filtered_groups)
        self._queue_current_model.set_items(filtered_queue_current)
        self._queue_waiting_model.set_items(filtered_queue_waiting)
        self._local_downloads_model.set_items(filtered_local)

        self._task_filter_summary = (
            f"下载 {len(filtered_downloads)}/{len(active_downloads)} · "
            f"上传 {len(filtered_uploads)}/{len(active_uploads)} · "
            f"记录组 {len(filtered_groups)}/{len(group_records)}"
        )
        self.taskFilterSummaryChanged.emit()

        waiting_total = len(queue_waiting)
        self._queue_filter_summary = (
            f"处理中 {len(filtered_queue_current)} · 等待 {len(filtered_queue_waiting)}/{waiting_total}"
        )
        self.queueFilterSummaryChanged.emit()

        self._local_filter_summary = f"匹配 {len(filtered_local)} / {len(local_items)} 项"
        self.localFilterSummaryChanged.emit()

        unified_items = [
            *active_downloads,
            *active_uploads,
            *group_records,
            *queue_current,
            *queue_waiting,
            *local_items,
        ]
        unified_items = [item for item in unified_items if self._matches_unified_item(item)]
        unified_items.sort(key=self._unified_sort_key)
        self._unified_task_flow_model.set_items(unified_items)

        visible_items = self._items_for_section(
            active_downloads=active_downloads,
            active_uploads=active_uploads,
            group_records=group_records,
            queue_current=queue_current,
            queue_waiting=queue_waiting,
            local_items=local_items,
        )
        visible_items = [item for item in visible_items if self._matches_unified_item(item)]
        visible_items.sort(key=self._unified_sort_key)
        self._visible_task_flow_model.set_items(visible_items)

        counts = {
            "active": sum(1 for item in unified_items if item.get("statusBucket") == "active"),
            "waiting": sum(1 for item in unified_items if item.get("statusBucket") == "waiting"),
            "failed": sum(1 for item in unified_items if item.get("statusBucket") == "failed"),
            "completed": sum(1 for item in unified_items if item.get("statusBucket") == "completed"),
        }
        parts = []
        if counts["active"] > 0:
            parts.append(f"进行中 {counts['active']}")
        if counts["waiting"] > 0:
            parts.append(f"等待中 {counts['waiting']}")
        if counts["failed"] > 0:
            parts.append(f"失败 {counts['failed']}")
        if counts["completed"] > 0:
            parts.append(f"已完成 {counts['completed']}")
        self._unified_filter_summary = " · ".join(parts) if parts else "当前没有匹配的任务"
        self.unifiedFilterSummaryChanged.emit()

    def _normalize_active_download(self, group: dict[str, Any], record: dict[str, Any]) -> dict[str, Any]:
        progress = format_progress(record.get("completed_length"), record.get("total_length") or record.get("file_size"))
        status = str(record.get("status") or "pending")
        updated_at = str(record.get("updated_at") or record.get("created_at") or "")
        return {
            "rowType": "download",
            "sourceType": "download",
            "typeLabel": "下载",
            "downloadId": int(record.get("id") or 0),
            "gid": str(record.get("gid") or ""),
            "title": str(record.get("file_name") or "未知文件"),
            "subtitle": str(group.get("caption") or group.get("group_key") or "下载任务"),
            "status": status,
            "statusLabel": self._download_status_label(status, record.get("error_message")),
            "statusTone": self._download_status_tone(status, record.get("error_message")),
            "statusBucket": self._download_status_bucket(status, record.get("error_message")),
            "progressPercent": round(progress, 2),
            "metaPrimary": self._readable_speed(record.get("download_speed")),
            "metaSecondary": format_datetime(updated_at),
            "sizeText": self._download_size_text(record),
            "localPath": "",
            "queueHint": "",
            "error": str(record.get("error_message") or ""),
            "canRetry": bool(record.get("gid") or record.get("source_url")),
            "canDelete": bool(record.get("gid")),
            "canCancel": False,
            "canOpen": False,
            "canReveal": False,
            "primaryActionText": "重试" if bool(record.get("gid") or record.get("source_url")) else "",
            "secondaryActionText": "删除" if bool(record.get("gid")) else "",
            "updatedAtRaw": updated_at,
            "sortTimestamp": self._sort_timestamp(updated_at),
            "sortWeight": self._sort_weight_for_bucket(self._download_status_bucket(status, record.get("error_message"))),
        }

    def _normalize_upload_record(self, record: dict[str, Any]) -> dict[str, Any]:
        progress = format_progress(record.get("uploaded_size"), record.get("total_size"))
        status = str(record.get("status") or "pending")
        target = str(record.get("upload_target") or "unknown")
        updated_at = str(record.get("updated_at") or record.get("created_at") or "")
        return {
            "rowType": "upload",
            "sourceType": "upload",
            "typeLabel": "上传",
            "uploadId": int(record.get("id") or 0),
            "gid": "",
            "title": str(record.get("file_name") or "未知文件"),
            "subtitle": f"目标 {target}",
            "status": status,
            "statusLabel": self._upload_status_label(status, target),
            "statusTone": self._upload_status_tone(status),
            "statusBucket": self._upload_status_bucket(status),
            "progressPercent": round(progress, 2),
            "metaPrimary": self._readable_speed(record.get("upload_speed")),
            "metaSecondary": format_datetime(updated_at),
            "sizeText": format_bytes(record.get("total_size")),
            "localPath": "",
            "queueHint": "",
            "error": str(record.get("error_message") or record.get("failure_reason") or ""),
            "canRetry": bool(record.get("id")),
            "canDelete": bool(record.get("id")),
            "canCancel": False,
            "canOpen": False,
            "canReveal": False,
            "primaryActionText": "重试" if bool(record.get("id")) else "",
            "secondaryActionText": "删除" if bool(record.get("id")) else "",
            "updatedAtRaw": updated_at,
            "sortTimestamp": self._sort_timestamp(updated_at),
            "sortWeight": self._sort_weight_for_bucket(self._upload_status_bucket(status)),
        }

    def _record_remote_path(self, record: dict[str, Any]) -> str:
        if record.get("remote_path"):
            return str(record.get("remote_path"))
        for upload in record.get("uploads") or []:
            if upload.get("remote_path"):
                return str(upload.get("remote_path"))
        return ""

    def _telegram_message_url(self, record: dict[str, Any]) -> str:
        chat_id = record.get("chat_id")
        message_id = record.get("message_id")
        if not chat_id or not message_id:
            return ""
        chat_text = str(chat_id)
        if chat_text.startswith("-100"):
            chat_text = chat_text[4:]
        elif chat_text.startswith("-"):
            chat_text = chat_text[1:]
        return f"https://t.me/c/{chat_text}/{message_id}"

    def _normalize_queue_item(
        self,
        item: dict[str, Any],
        *,
        state_label: str,
        state_kind: str,
        waiting_index: int,
    ) -> dict[str, Any]:
        item_type = str(item.get("type") or "single")
        title = str(item.get("title") or "未命名任务")
        updated_at = str(
            item.get("updated_at")
            or item.get("created_at")
            or item.get("scheduled_at")
            or ""
        )
        bucket = "active" if state_kind == "processing" else "waiting"
        queue_meta = (
            f"文件数 {item.get('media_group_total', 0)}"
            if item_type == "media_group"
            else f"下载任务 {len(item.get('task_gids') or [])}"
        )
        return {
            "rowType": "queue",
            "sourceType": "queue",
            "typeLabel": "队列",
            "queueId": str(item.get("queue_id") or title),
            "gid": "",
            "title": title,
            "subtitle": "媒体组" if item_type == "media_group" else "单个文件",
            "status": state_kind,
            "statusLabel": state_label,
            "statusTone": "primary" if state_kind == "processing" else "info",
            "statusBucket": bucket,
            "progressPercent": 0.0,
            "metaPrimary": queue_meta,
            "metaSecondary": format_datetime(updated_at),
            "sizeText": "",
            "localPath": "",
            "queueHint": state_label,
            "error": "",
            "canRetry": False,
            "canDelete": False,
            "canCancel": False,
            "canOpen": False,
            "canReveal": False,
            "primaryActionText": "",
            "secondaryActionText": "",
            "updatedAtRaw": updated_at,
            "sortTimestamp": self._sort_timestamp(updated_at),
            "sortWeight": self._sort_weight_for_bucket(bucket),
            "queueOrder": waiting_index,
        }

    def _normalize_local_transfer(self, item: dict[str, Any]) -> dict[str, Any]:
        state = str(item.get("state") or "pending")
        total_bytes = item.get("totalBytes")
        updated_at = str(
            item.get("updatedAt")
            or item.get("updated_at")
            or item.get("finishedAt")
            or item.get("finished_at")
            or item.get("createdAt")
            or item.get("created_at")
            or ""
        )
        bucket = self._local_status_bucket(state)
        local_path = str(item.get("localPath") or "")
        return {
            "rowType": "local",
            "sourceType": "local",
            "typeLabel": "本地",
            "transferId": str(item.get("transferId") or ""),
            "gid": "",
            "title": str(item.get("fileName") or "未命名文件"),
            "subtitle": local_path,
            "status": state,
            "statusLabel": self._local_status_label(state),
            "statusTone": self._local_status_tone(state),
            "statusBucket": bucket,
            "progressPercent": float(item.get("progressPercent") or 0),
            "metaPrimary": self._local_meta_text(item),
            "metaSecondary": self._readable_speed(item.get("downloadSpeed")),
            "sizeText": (
                f"{format_bytes(item.get('downloadedBytes'))} / {format_bytes(total_bytes)}"
                if total_bytes
                else format_bytes(item.get("downloadedBytes"))
            ),
            "localPath": local_path,
            "queueHint": "",
            "error": str(item.get("error") or ""),
            "canRetry": state in {"error", "cancelled"},
            "canDelete": state in {"completed", "error", "cancelled"},
            "canCancel": state in {"pending", "downloading"},
            "canOpen": state == "completed",
            "canReveal": state == "completed",
            "primaryActionText": "打开" if state == "completed" else ("重试" if state in {"error", "cancelled"} else ""),
            "secondaryActionText": "删除" if state in {"completed", "error", "cancelled"} else ("取消" if state in {"pending", "downloading"} else ""),
            "updatedAtRaw": updated_at,
            "sortTimestamp": self._sort_timestamp(updated_at),
            "sortWeight": self._sort_weight_for_bucket(bucket),
        }

    def _matches_task_item(self, item: dict[str, Any]) -> bool:
        return self._matches_unified_item(item)

    def _matches_queue_item(self, item: dict[str, Any]) -> bool:
        return self._matches_unified_item(item)

    def _matches_local_item(self, item: dict[str, Any]) -> bool:
        return self._matches_unified_item(item)

    def _matches_unified_item(self, item: dict[str, Any]) -> bool:
        if not self._matches_unified_filter(item):
            return False
        if not self._unified_keyword:
            return True
        query = self._unified_keyword.lower()
        return any(
            query in str(item.get(key, "")).lower()
            for key in (
                "title",
                "subtitle",
                "typeLabel",
                "statusLabel",
                "metaPrimary",
                "metaSecondary",
                "sizeText",
                "error",
                "queueHint",
                "fileSearchText",
            )
        )

    def _matches_unified_filter(self, item: dict[str, Any]) -> bool:
        current = self._unified_status_filter
        if current == "all":
            return True
        if current in {"active", "waiting", "failed", "completed"}:
            return item.get("statusBucket") == current
        return item.get("sourceType") == current

    def _items_for_section(
        self,
        *,
        active_downloads: list[dict[str, Any]],
        active_uploads: list[dict[str, Any]],
        group_records: list[dict[str, Any]],
        queue_current: list[dict[str, Any]],
        queue_waiting: list[dict[str, Any]],
        local_items: list[dict[str, Any]],
    ) -> list[dict[str, Any]]:
        if self._task_section == "queue":
            return [*queue_current, *queue_waiting]
        if self._task_section == "local":
            return list(local_items)
        return [*active_downloads, *active_uploads, *group_records]

    def _download_size_text(self, record: dict[str, Any]) -> str:
        total = record.get("total_length") or record.get("file_size")
        completed = record.get("completed_length")
        if total:
            return f"{format_bytes(completed)} / {format_bytes(total)}"
        return format_bytes(completed)

    def _download_status_label(self, status: str, error_message: str | None) -> str:
        if error_message and "跳过" in error_message:
            return "已跳过"
        return {
            "pending": "等待中",
            "waiting": "等待中",
            "downloading": "下载中",
            "completed": "已完成",
            "failed": "失败",
            "skipped": "已跳过",
        }.get(status, status)

    def _download_status_tone(self, status: str, error_message: str | None) -> str:
        if error_message and "跳过" in error_message:
            return "info"
        return {
            "pending": "info",
            "waiting": "info",
            "downloading": "warning",
            "completed": "success",
            "failed": "danger",
            "skipped": "info",
        }.get(status, "info")

    def _download_status_bucket(self, status: str, error_message: str | None) -> str:
        if error_message and "跳过" in error_message:
            return "completed"
        if status in {"pending", "waiting"}:
            return "waiting"
        if status == "downloading":
            return "active"
        if status == "completed" or status == "skipped":
            return "completed"
        if status == "failed":
            return "failed"
        return "waiting"

    def _upload_status_label(self, status: str, upload_target: str) -> str:
        target = "Telegram" if upload_target == "telegram" else "OneDrive" if upload_target == "onedrive" else upload_target
        return {
            "pending": "等待中",
            "waiting_download": "等待下载",
            "uploading": f"上传到 {target}",
            "completed": "已完成",
            "failed": "失败",
            "cancelled": "已取消",
        }.get(status, status)

    def _upload_status_tone(self, status: str) -> str:
        return {
            "pending": "info",
            "waiting_download": "info",
            "uploading": "primary",
            "completed": "success",
            "failed": "danger",
            "cancelled": "warning",
        }.get(status, "info")

    def _upload_status_bucket(self, status: str) -> str:
        if status in {"pending", "waiting_download"}:
            return "waiting"
        if status == "uploading":
            return "active"
        if status == "completed":
            return "completed"
        if status in {"failed", "cancelled"}:
            return "failed"
        return "waiting"

    def _group_status_bucket(self, status: str) -> str:
        if status in {"downloading", "uploading"}:
            return "active"
        if status in {"completed", "skipped"}:
            return "completed"
        if status == "failed":
            return "failed"
        return "waiting"

    def _local_status_label(self, state: str) -> str:
        return {
            "pending": "等待中",
            "downloading": "下载中",
            "ready": "可预览",
            "completed": "已完成",
            "error": "失败",
            "cancelling": "取消中",
            "cancelled": "已取消",
        }.get(state, state)

    def _local_status_tone(self, state: str) -> str:
        return {
            "pending": "info",
            "downloading": "warning",
            "ready": "primary",
            "completed": "success",
            "error": "danger",
            "cancelling": "warning",
            "cancelled": "info",
        }.get(state, "info")

    def _local_status_bucket(self, state: str) -> str:
        if state in {"pending"}:
            return "waiting"
        if state in {"downloading", "ready", "cancelling"}:
            return "active"
        if state == "completed":
            return "completed"
        if state in {"error", "cancelled"}:
            return "failed"
        return "waiting"

    def _local_meta_text(self, item: dict[str, Any]) -> str:
        state = str(item.get("state") or "")
        if state == "completed":
            return "本地文件已就绪"
        if state == "error":
            return str(item.get("error") or "本地下载失败")
        if state == "cancelled":
            return "下载已取消"
        if state == "cancelling":
            return "正在取消下载"
        if state == "ready":
            return "已可预览"
        return "正在写入本地文件"

    def _local_active_count(self) -> int:
        return sum(
            1
            for item in self._local_transfers.values()
            if item.get("state") not in {"completed", "error", "cancelled"}
        )

    def _local_sort_key(self, item: dict[str, Any]) -> tuple[int, str]:
        state = item["status"]
        if state in {"downloading", "pending", "cancelling"}:
            score = 0
        elif state == "completed":
            score = 1
        else:
            score = 2
        return (score, item["title"].lower())

    def _build_flood_wait_text(self) -> str:
        flood_wait = self._queue_snapshot.get("flood_wait") or {}
        if flood_wait.get("is_waiting"):
            return f"Telegram 限流中，还需等待 {flood_wait.get('remaining_seconds', 0)} 秒。"
        return ""

    def _readable_speed(self, value: int | float | None) -> str:
        speed = format_speed(value)
        return "" if speed == "-" else speed

    def _sort_weight_for_bucket(self, bucket: str) -> int:
        return {
            "active": 0,
            "waiting": 1,
            "failed": 2,
            "completed": 3,
        }.get(bucket, 4)

    def _sort_timestamp(self, value: str | None) -> int:
        if not value:
            return 0
        normalized = value.replace("Z", "+00:00")
        try:
            parsed = datetime.fromisoformat(normalized)
        except ValueError:
            return 0
        if parsed.tzinfo is not None:
            parsed = parsed.astimezone().replace(tzinfo=None)
        return int(parsed.timestamp())

    def _unified_sort_key(self, item: dict[str, Any]) -> tuple[int, int, int, str]:
        queue_order = int(item.get("queueOrder") or 0)
        queue_bias = queue_order if item.get("sourceType") == "queue" and item.get("statusBucket") == "waiting" else 0
        return (
            int(item.get("sortWeight") or 99),
            queue_bias,
            -int(item.get("sortTimestamp") or 0),
            str(item.get("title") or "").lower(),
        )

    def _normalize_group_upload_item(self, upload: dict[str, Any]) -> dict[str, Any]:
        status = str(upload.get("status") or "pending")
        target = str(upload.get("upload_target") or "unknown")
        return {
            "uploadId": int(upload.get("id") or 0),
            "target": target,
            "targetLabel": "Telegram" if target == "telegram" else "OneDrive" if target == "onedrive" else target,
            "status": status,
            "statusLabel": self._upload_status_label(status, target),
            "statusTone": self._upload_status_tone(status),
            "remotePath": str(upload.get("remote_path") or ""),
            "completedAtText": format_datetime(upload.get("completed_at")),
            "error": str(upload.get("error_message") or upload.get("failure_reason") or ""),
        }

    def _group_display_title(self, group: dict[str, Any]) -> str:
        caption = str(group.get("caption") or "").strip()
        if caption:
            return caption
        label = self._group_type_label(group.get("group_type"), group.get("message_id"))
        if label:
            return label
        group_key = str(group.get("group_key") or "").strip()
        return group_key or "è®°å½•ç»„"

    def _group_type_label(self, group_type: Any, message_id: Any) -> str:
        normalized = str(group_type or "group")
        if normalized == "media_group":
            base = "媒体组"
        else:
            base = "消息"
        if message_id:
            return f"{base} #{message_id}"
        return base

    def _record_status_presentation(self, record: dict[str, Any]) -> tuple[str, str]:
        status = str(record.get("status") or "pending")
        error_message = str(record.get("error_message") or "")
        uploads = record.get("uploads") or []
        if status == "failed":
            if "跳过" in error_message:
                return "已跳过", "info"
            return "失败", "danger"
        if status in {"pending", "waiting", "downloading"}:
            return "下载中", "warning"
        if status == "completed":
            if uploads:
                has_uploading = any(
                    str(upload.get("status") or "") in {"uploading", "pending", "waiting_download"}
                    for upload in uploads
                )
                if has_uploading:
                    return "上传中", "warning"
                has_failed = any(str(upload.get("status") or "") == "failed" for upload in uploads)
                if has_failed:
                    has_completed = any(str(upload.get("status") or "") == "completed" for upload in uploads)
                    return ("上传中", "warning") if has_completed else ("失败", "danger")
                all_completed = all(
                    str(upload.get("status") or "") in {"completed", "failed"}
                    for upload in uploads
                )
                if all_completed:
                    has_uncleaned = any(
                        str(upload.get("status") or "") == "completed" and not upload.get("cleaned_at")
                        for upload in uploads
                    )
                    if has_uncleaned:
                        return "清理中", "warning"
                    return "已完成", "success"
                return "上传中", "warning"
            return "已完成", "success"
        if status == "skipped":
            return "已跳过", "info"
        return self._download_status_label(status, error_message or None), self._download_status_tone(status, error_message or None)

    def _normalize_group_record(self, group: dict[str, Any]) -> dict[str, Any]:
        stats = group.get("stats") or {}
        caption = str(group.get("caption") or "").strip()
        title = self._group_display_title(group)
        downloads = group.get("downloads") or []
        status, label, tone = self._group_status(stats, downloads)
        updated_at = str(group.get("updated_at") or group.get("created_at") or "")
        created_at = str(group.get("created_at") or updated_at)
        bucket = self._group_status_bucket(status)
        group_type = str(group.get("group_type") or "group")
        files = [
            self._normalize_group_file(record, index)
            for index, record in enumerate(downloads)
        ]
        file_search_text = " ".join(
            str(file.get(key) or "")
            for file in files
            for key in (
                "fileName",
                "fileType",
                "remotePath",
                "sourceUrl",
                "sourceTgUrl",
                "descriptionText",
            )
        )
        total_files = int(stats.get("total_files") or len(files) or 0)
        completed_files = int(stats.get("completed") or 0)
        skipped_files = int(stats.get("skipped") or 0)
        failed_files = int(stats.get("failed") or 0)
        downloading_files = int(stats.get("downloading") or 0)
        return {
            "rowType": "group",
            "sourceType": "group",
            "typeLabel": "记录组",
            "groupKey": str(group.get("group_key") or title),
            "gid": "",
            "title": title,
            "subtitle": format_datetime(updated_at),
            "captionText": caption,
            "messageId": str(group.get("message_id") or ""),
            "groupType": group_type,
            "groupTypeLabel": self._group_type_label(group_type, group.get("message_id")),
            "status": status,
            "statusLabel": label,
            "statusTone": tone,
            "statusBucket": bucket,
            "progressPercent": round(format_progress(stats.get("completed_size"), stats.get("total_size")), 2),
            "metaPrimary": f"{stats.get('completed', 0)}/{stats.get('total_files', 0)} 完成",
            "metaSecondary": f"下载中 {downloading_files} · 已跳过 {skipped_files} · 失败 {failed_files}",
            "sizeText": format_bytes(stats.get("total_size")),
            "fileCount": total_files,
            "completedCount": completed_files,
            "fileCountLabel": f"{total_files} 个文件",
            "completedLabel": f"{completed_files} 已完成",
            "downloadingLabel": f"{downloading_files} 下载中",
            "skippedLabel": f"{skipped_files} 已跳过",
            "failedLabel": f"{failed_files} 失败",
            "hasDownloading": downloading_files > 0,
            "hasSkipped": skipped_files > 0,
            "hasFailed": failed_files > 0,
            "createdAtText": format_datetime(created_at),
            "messageDateText": format_datetime(group.get("message_date")),
            "files": files,
            "fileSearchText": file_search_text,
            "localPath": "",
            "queueHint": "",
            "error": "",
            "canRetry": False,
            "canDelete": False,
            "canCancel": False,
            "canOpen": False,
            "canReveal": False,
            "primaryActionText": "",
            "secondaryActionText": "",
            "updatedAtRaw": updated_at,
            "sortTimestamp": self._sort_timestamp(updated_at),
            "sortWeight": self._sort_weight_for_bucket(bucket),
        }

    def _normalize_group_file(self, record: dict[str, Any], index: int) -> dict[str, Any]:
        status = str(record.get("status") or "pending")
        error_message = record.get("error_message")
        created_at = str(record.get("created_at") or "")
        started_at = str(record.get("started_at") or "")
        completed_at = str(record.get("completed_at") or "")
        updated_at = str(record.get("updated_at") or created_at)
        total_size = record.get("total_length") or record.get("file_size")
        completed_size = record.get("completed_length")
        remote_path = self._record_remote_path(record)
        status_label, status_tone = self._record_status_presentation(record)
        upload_items = [self._normalize_group_upload_item(upload) for upload in (record.get("uploads") or [])]
        if upload_items:
            remote_path_entries = [item.get("remotePath") or "-" for item in upload_items]
        elif remote_path:
            remote_path_entries = [remote_path]
        else:
            remote_path_entries = []
        file_name = str(record.get("file_name") or record.get("source_url") or "未知文件")
        if not remote_path:
            remote_path = "-"
        return {
            "index": index,
            "downloadId": int(record.get("id") or 0),
            "gid": str(record.get("gid") or ""),
            "fileName": file_name,
            "fileSizeText": format_bytes(total_size),
            "fileType": str(record.get("mime_type") or "-"),
            "status": status,
            "statusLabel": status_label,
            "statusTone": status_tone,
            "remotePath": remote_path,
            "remotePathEntries": remote_path_entries,
            "sourceTgUrl": self._telegram_message_url(record),
            "sourceUrl": str(record.get("source_url") or ""),
            "descriptionText": str(record.get("caption") or ""),
            "captionText": str(record.get("caption") or ""),
            "localPath": str(record.get("local_path") or ""),
            "createdAtText": format_datetime(created_at),
            "startedAtText": format_datetime(started_at),
            "completedAtText": format_datetime(completed_at),
            "updatedAtText": format_datetime(updated_at),
            "createdAtRaw": created_at,
            "startedAtRaw": started_at,
            "completedAtRaw": completed_at,
            "updatedAtRaw": updated_at,
            "sizeDetailText": (
                f"{format_bytes(completed_size)} / {format_bytes(total_size)}"
                if total_size
                else format_bytes(completed_size)
            ),
            "error": str(error_message or ""),
            "uploadItems": upload_items,
            "canRetry": bool(record.get("gid")),
            "canDelete": bool(record.get("gid")),
        }

    def _group_status(self, stats: dict[str, Any], downloads: list[dict[str, Any]]) -> tuple[str, str, str]:
        skipped_count = int(stats.get("skipped") or 0)
        failed_count = max(int(stats.get("failed") or 0) - skipped_count, 0)
        if int(stats.get("downloading") or 0) > 0:
            return "downloading", "下载中", "warning"
        if int(stats.get("pending") or 0) > 0:
            return "pending", "等待中", "info"
        if failed_count > 0:
            return "failed", "失败", "danger"
        total_files = int(stats.get("total_files") or 0)
        completed_or_skipped = int(stats.get("completed") or 0) + skipped_count
        if total_files > 0 and completed_or_skipped >= total_files:
            if skipped_count > 0:
                return "skipped", "已跳过", "info"
            return "completed", "已完成", "success"
        return "pending", "等待中", "info"

    @Slot(str)
    def retryServerDownload(self, gid: str) -> None:
        if not gid:
            self._set_error_message("下载任务缺少 GID，无法重试")
            return
        self._task_runner.submit(
            lambda: self._api_client.retry_download(gid),
            on_success=lambda result: self._handle_server_action_result(result, "已重新提交下载任务"),
            on_error=self._set_error_message,
        )

    @Slot(str)
    def deleteServerDownload(self, gid: str) -> None:
        if not gid:
            self._set_error_message("下载任务缺少 GID，无法删除")
            return
        self._task_runner.submit(
            lambda: self._api_client.delete_download(gid),
            on_success=lambda result: self._handle_server_action_result(result, "已删除下载任务"),
            on_error=self._set_error_message,
        )

    @Slot(int)
    def retryUpload(self, upload_id: int) -> None:
        if upload_id <= 0:
            self._set_error_message("上传任务 ID 不存在")
            return
        self._task_runner.submit(
            lambda: self._api_client.retry_upload(upload_id),
            on_success=lambda result: self._handle_server_action_result(result, "已重新提交上传任务"),
            on_error=self._set_error_message,
        )

    @Slot(int)
    def deleteUpload(self, upload_id: int) -> None:
        if upload_id <= 0:
            self._set_error_message("上传任务 ID 不存在")
            return
        self._task_runner.submit(
            lambda: self._api_client.delete_upload(upload_id),
            on_success=lambda result: self._handle_server_action_result(result, "已删除上传任务"),
            on_error=self._set_error_message,
        )

    @Slot(str)
    def cancelLocalDownload(self, transfer_id: str) -> None:
        try:
            status = self._local_runtime_service.cancel_download(transfer_id)
        except Exception as exc:
            self._set_error_message(str(exc))
            return
        self._local_transfers[transfer_id] = status
        self._show_toast("warning", f"正在取消: {status['fileName']}")
        self._rebuild_models()

    @Slot(str)
    def retryLocalDownload(self, transfer_id: str) -> None:
        try:
            status = self._local_runtime_service.retry_download(transfer_id)
        except Exception as exc:
            self._set_error_message(str(exc))
            return
        self._local_transfers[transfer_id] = status
        self._show_toast("success", f"已重新开始下载: {status['fileName']}")
        self._rebuild_models()

    @Slot(str)
    def removeLocalDownload(self, transfer_id: str) -> None:
        try:
            self._local_runtime_service.remove_download_session(transfer_id)
        except Exception as exc:
            self._set_error_message(str(exc))
            return
        self._local_transfers.pop(transfer_id, None)
        self._show_toast("success", "已移除本地下载任务")
        self._rebuild_models()

    @Slot(str)
    def openLocalFile(self, local_path: str) -> None:
        try:
            self._local_runtime_service.open_local_file(local_path)
        except Exception as exc:
            self._set_error_message(str(exc))

    @Slot(str)
    def showLocalFileInFolder(self, local_path: str) -> None:
        try:
            self._local_runtime_service.show_local_file_in_folder(local_path)
        except Exception as exc:
            self._set_error_message(str(exc))

    def _handle_server_action_result(self, result: dict[str, Any], fallback_message: str) -> None:
        self._show_toast("success", str(result.get("message") or fallback_message))
        self.refresh()

    def _handle_transfer_update(self, payload: dict[str, Any]) -> None:
        transfer_id = str(payload.get("transferId") or "")
        if not transfer_id:
            return
        self._local_transfers[transfer_id] = payload
        self._rebuild_models()

    summaryCards = Property("QVariantList", get_summary_cards, notify=summaryCardsChanged)
    currentTab = Property(str, get_current_tab, notify=currentTabChanged)
    headline = Property(str, get_headline, notify=headlineChanged)
    runtimeNote = Property(str, get_runtime_note, notify=runtimeNoteChanged)
    taskKeyword = Property(str, get_task_keyword, notify=taskKeywordChanged)
    taskStatusFilter = Property(str, get_task_status_filter, notify=taskStatusFilterChanged)
    queueKeyword = Property(str, get_queue_keyword, notify=queueKeywordChanged)
    queueTypeFilter = Property(str, get_queue_type_filter, notify=queueTypeFilterChanged)
    localKeyword = Property(str, get_local_keyword, notify=localKeywordChanged)
    localStatusFilter = Property(str, get_local_status_filter, notify=localStatusFilterChanged)
    queueFloodWaitText = Property(str, get_queue_flood_wait_text, notify=queueFloodWaitTextChanged)
    taskFilterSummary = Property(str, get_task_filter_summary, notify=taskFilterSummaryChanged)
    queueFilterSummary = Property(str, get_queue_filter_summary, notify=queueFilterSummaryChanged)
    localFilterSummary = Property(str, get_local_filter_summary, notify=localFilterSummaryChanged)
    unifiedKeyword = Property(str, get_unified_keyword, notify=unifiedKeywordChanged)
    unifiedStatusFilter = Property(str, get_unified_status_filter, notify=unifiedStatusFilterChanged)
    unifiedFilterSummary = Property(str, get_unified_filter_summary, notify=unifiedFilterSummaryChanged)
    taskSection = Property(str, get_task_section, notify=taskSectionChanged)
    activeDownloadsModel = Property(QObject, get_active_downloads_model, constant=True)
    activeUploadsModel = Property(QObject, get_active_uploads_model, constant=True)
    groupRecordsModel = Property(QObject, get_group_records_model, constant=True)
    queueCurrentModel = Property(QObject, get_queue_current_model, constant=True)
    queueWaitingModel = Property(QObject, get_queue_waiting_model, constant=True)
    localDownloadsModel = Property(QObject, get_local_downloads_model, constant=True)
    unifiedTaskFlowModel = Property(QObject, get_unified_task_flow_model, constant=True)
    visibleTaskFlowModel = Property(QObject, get_visible_task_flow_model, constant=True)
