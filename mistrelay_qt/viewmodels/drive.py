from __future__ import annotations

from datetime import datetime, timedelta
from pathlib import Path
from typing import Any
from urllib.parse import parse_qsl, urlparse

from PySide6.QtCore import Property, QTimer, QUrl, QObject, Signal, Slot

from ..formatters import format_bytes, format_datetime
from ..list_models import RoleListModel
from ..task_runner import TaskRunner
from .base import BaseViewModel

TELEGRAM_GROUP_PATH_PREFIX = "/__tg_group__/"
RECENT_DAYS = 7
DEFAULT_PAGE_SIZE = 10
PAGE_SIZE_CHOICES = {10, 30, 60, 100, 200}


class DriveViewModel(BaseViewModel):
    subtitleChanged = Signal()
    usageSummaryChanged = Signal()
    currentFilterChanged = Signal()
    searchKeywordChanged = Signal()
    currentPathLabelChanged = Signal()
    canNavigateUpChanged = Signal()
    filterSummaryChanged = Signal()
    selectedItemChanged = Signal()
    previewStateChanged = Signal()
    emptyStateChanged = Signal()
    viewModeChanged = Signal()
    sortOptionChanged = Signal()
    detailPanelVisibleChanged = Signal()
    sidebarSectionChanged = Signal()
    sidebarStatsChanged = Signal()
    workspaceTitleChanged = Signal()
    breadcrumbTextChanged = Signal()
    selectionSummaryChanged = Signal()
    selectedPathsChanged = Signal()
    contentStatsChanged = Signal()
    channelSummaryChanged = Signal()
    channelStatsChanged = Signal()
    paginationChanged = Signal()

    def __init__(self, *, api_client, local_runtime_service, task_runner: TaskRunner) -> None:
        super().__init__()
        self._api_client = api_client
        self._local_runtime_service = local_runtime_service
        self._task_runner = task_runner

        self._subtitle = "Telegram 网盘工作台"
        self._usage_summary = "等待同步 Telegram 容量"
        self._channel_summary = "Telegram 频道"
        self._channel_stats: dict[str, Any] = {
            "totalSize": "0 B",
            "totalCount": 0,
            "videos": 0,
            "images": 0,
            "documents": 0,
        }
        self._current_filter = "all"
        self._search_keyword = ""
        self._current_path = "/"
        self._filter_summary = ""
        self._empty_state = "当前没有可显示的 Telegram 媒体。"
        self._view_mode = "grid"
        self._sort_option = "time_desc"
        self._detail_panel_visible = False
        self._sidebar_section = "all"
        self._workspace_title = "文件流"
        self._breadcrumb_text = "Telegram 频道"
        self._selection_summary = "未选择内容"
        self._content_stats: dict[str, Any] = {
            "total": 0,
            "files": 0,
            "groups": 0,
            "videos": 0,
            "images": 0,
            "documents": 0,
        }
        self._sidebar_stats: dict[str, Any] = {
            "all": 0,
            "videos": 0,
            "images": 0,
            "documents": 0,
            "flows": 0,
            "recent": 0,
            "streaming": 0,
            "cached": 0,
        }
        self._current_page = 1
        self._page_size = DEFAULT_PAGE_SIZE
        self._total_items = 0
        self._total_pages = 1

        self._items_model = RoleListModel()
        self._raw_items: list[dict[str, Any]] = []
        self._visible_items: list[dict[str, Any]] = []
        self._all_file_rows: list[dict[str, Any]] = []
        self._all_flow_rows: list[dict[str, Any]] = []
        self._telegram_meta: dict[str, dict[str, Any]] = {}
        self._group_meta: dict[str, dict[str, Any]] = {}
        self._cached_paths: set[str] = set()
        self._selected_paths: list[str] = []
        self._selected_item: dict[str, Any] = self._empty_selected_item()
        self._preview_state: dict[str, Any] = self._empty_preview_state()
        self._preview_transfer_id = ""
        self._preview_item_path = ""
        self._preview_token = 0
        self._refresh_scheduled = False

        self._local_runtime_service.transferUpdated.connect(self._handle_transfer_update)

    def get_subtitle(self) -> str:
        return self._subtitle

    def get_usage_summary(self) -> str:
        return self._usage_summary

    def get_current_filter(self) -> str:
        return self._current_filter

    def get_search_keyword(self) -> str:
        return self._search_keyword

    def get_current_path_label(self) -> str:
        if self._current_path == "/":
            return "Telegram 频道"
        group = self._group_meta.get(self._current_path)
        return str(group.get("title") or "媒体组") if group else "Telegram 频道"

    def get_can_navigate_up(self) -> bool:
        return self._current_path != "/"

    def get_filter_summary(self) -> str:
        return self._filter_summary

    def get_selected_item(self) -> dict[str, Any]:
        return dict(self._selected_item)

    def get_preview_state(self) -> dict[str, Any]:
        return dict(self._preview_state)

    def get_empty_state(self) -> str:
        return self._empty_state

    def get_items_model(self) -> QObject:
        return self._items_model

    def get_view_mode(self) -> str:
        return self._view_mode

    def get_sort_option(self) -> str:
        return self._sort_option

    def get_detail_panel_visible(self) -> bool:
        return self._detail_panel_visible

    def get_sidebar_section(self) -> str:
        return self._sidebar_section

    def get_sidebar_stats(self) -> dict[str, Any]:
        return dict(self._sidebar_stats)

    def get_workspace_title(self) -> str:
        return self._workspace_title

    def get_breadcrumb_text(self) -> str:
        return self._breadcrumb_text

    def get_selection_summary(self) -> str:
        return self._selection_summary

    def get_selected_paths(self) -> list[str]:
        return list(self._selected_paths)

    def get_has_selection(self) -> bool:
        return bool(self._selected_paths)

    def get_selection_count(self) -> int:
        return len(self._selected_paths)

    def get_content_stats(self) -> dict[str, Any]:
        return dict(self._content_stats)

    def get_channel_summary(self) -> str:
        return self._channel_summary

    def get_channel_stats(self) -> dict[str, Any]:
        return dict(self._channel_stats)

    def get_show_files_chips(self) -> bool:
        return self._sidebar_section not in {"flows", "recent", "streaming", "cached"}

    def get_open_enabled(self) -> bool:
        return len(self._selected_paths) == 1

    def get_batch_download_enabled(self) -> bool:
        return bool(self._selected_paths)

    def get_batch_delete_enabled(self) -> bool:
        return bool(self._selected_paths)

    def get_current_page(self) -> int:
        return self._current_page

    def get_page_size(self) -> int:
        return self._page_size

    def get_total_items(self) -> int:
        return self._total_items

    def get_total_pages(self) -> int:
        return self._total_pages

    def get_page_summary(self) -> str:
        if self._current_path != "/":
            return f"本组 {len(self._visible_items)} 项"
        return f"第 {self._current_page} / {self._total_pages} 页 · 共 {self._total_items} 项 · 本页 {len(self._visible_items)} 项"

    def get_can_previous_page(self) -> bool:
        return self._current_path == "/" and self._current_page > 1

    def get_can_next_page(self) -> bool:
        return self._current_path == "/" and self._total_items > 0 and self._current_page < self._total_pages

    @Slot()
    def refresh(self) -> None:
        if self._busy:
            return
        self._set_busy(True)
        self._set_error_message("")
        self._task_runner.submit(self._load_snapshot, on_success=self._apply_snapshot, on_error=self._apply_error)

    def _load_snapshot(self) -> dict[str, Any]:
        usage = self._api_client.get_telegram_usage()
        sort_by, sort_desc = self._backend_sort_params()
        browse = self._api_client.browse_telegram(
            page=self._current_page,
            page_size=self._page_size,
            search=self._search_keyword,
            media_type=self._filter_media_type(self._current_filter),
            sort_by=sort_by,
            sort_desc=sort_desc,
        )
        return {"usage": usage, "browse": browse}

    def _apply_snapshot(self, payload: dict[str, Any]) -> None:
        self._refresh_scheduled = False
        self._set_busy(False)
        usage = (payload.get("usage") or {}).get("data") or {}
        browse = payload.get("browse") or {}
        browse_items = list(browse.get("items") or [])
        browse_total = int(browse.get("total") or 0)
        browse_page_size = self._normalize_page_size(int(browse.get("page_size") or self._page_size))
        requested_page = self._current_page
        total_pages = max(1, (browse_total + browse_page_size - 1) // browse_page_size) if browse_page_size > 0 else 1

        if browse_total > 0 and not browse_items and requested_page > 1:
            self._current_page = max(1, min(total_pages, requested_page - 1))
            self.paginationChanged.emit()
            self._clear_transient_state()
            QTimer.singleShot(0, self.refresh)
            return

        self._page_size = browse_page_size
        self._total_items = browse_total
        self._total_pages = total_pages
        self._current_page = max(1, min(int(browse.get("page") or requested_page or 1), self._total_pages))

        total_count = int(usage.get("total_count") or 0)
        videos = int(usage.get("videos") or 0)
        images = int(usage.get("images") or 0)
        documents = int(usage.get("documents") or 0)
        total_size = format_bytes(usage.get("total_size"))

        self._usage_summary = (
            f"{total_size} · {total_count} 个文件 · "
            f"{videos} 视频 · {images} 图片 · {documents} 文档"
        )
        self.usageSummaryChanged.emit()

        self._channel_summary = f"Telegram 频道  {total_size} · {total_count} 个文件"
        self.channelSummaryChanged.emit()
        self._channel_stats = {
            "totalSize": total_size,
            "totalCount": total_count,
            "videos": videos,
            "images": images,
            "documents": documents,
        }
        self.channelStatsChanged.emit()

        self._raw_items = self._map_telegram_items(browse_items)
        self._subtitle = f"已同步 {self._total_items} 个 Telegram 项目"
        self.subtitleChanged.emit()

        self._refresh_cached_paths()
        self._rebuild_visible_items()

    def _apply_error(self, message: str) -> None:
        self._refresh_scheduled = False
        self._set_busy(False)
        self._set_error_message(message)
        self._subtitle = "Telegram 网盘数据拉取失败"
        self.subtitleChanged.emit()

    def consume_status_event(self, payload: dict[str, Any]) -> None:
        message_type = str(payload.get("type") or "")
        if message_type not in {"initial", "cleanup_update", "statistics_update"}:
            return
        if self._busy or self._refresh_scheduled:
            return
        self._refresh_scheduled = True
        QTimer.singleShot(1000, self.refresh)

    @Slot(str)
    def setCurrentFilter(self, value: str) -> None:
        next_filter = value if value in {"all", "videos", "images", "documents"} else "all"
        if next_filter == self._current_filter:
            return
        self._current_filter = next_filter
        self.currentFilterChanged.emit()
        self._refresh_from_first_page()

    @Slot(str)
    def setSidebarSection(self, value: str) -> None:
        next_section = value if value in {"all", "videos", "images", "documents", "flows", "recent", "streaming", "cached"} else "all"
        if next_section == self._sidebar_section:
            return
        self._sidebar_section = next_section
        self.sidebarSectionChanged.emit()
        if next_section in {"videos", "images", "documents"}:
            mapped_filter = {
                "videos": "videos",
                "images": "images",
                "documents": "documents",
            }[next_section]
            if self._current_filter != mapped_filter:
                self._current_filter = mapped_filter
                self.currentFilterChanged.emit()
        elif self._current_filter != "all":
            self._current_filter = "all"
            self.currentFilterChanged.emit()

        if next_section != "flows" and self._current_path != "/":
            self._current_path = "/"
            self.currentPathLabelChanged.emit()
            self.canNavigateUpChanged.emit()
        self._refresh_from_first_page()

    @Slot(str)
    def setSearchKeyword(self, value: str) -> None:
        normalized = value.strip()
        if normalized == self._search_keyword:
            return
        self._search_keyword = normalized
        self.searchKeywordChanged.emit()

    @Slot()
    def commitSearch(self) -> None:
        self._refresh_from_first_page()

    @Slot()
    def clearSearch(self) -> None:
        if not self._search_keyword:
            return
        self._search_keyword = ""
        self.searchKeywordChanged.emit()
        self._refresh_from_first_page()

    @Slot()
    def navigateUp(self) -> None:
        if self._current_path == "/":
            return
        self._current_path = "/"
        self.currentPathLabelChanged.emit()
        self.canNavigateUpChanged.emit()
        self._rebuild_visible_items()

    @Slot(str)
    def setViewMode(self, value: str) -> None:
        next_mode = value if value in {"grid", "list"} else "grid"
        if next_mode == self._view_mode:
            return
        self._view_mode = next_mode
        self.viewModeChanged.emit()

    @Slot(str)
    def setSortOption(self, value: str) -> None:
        next_value = value if value in {"time_desc", "time_asc", "size_desc", "name_asc"} else "time_desc"
        if next_value == self._sort_option:
            return
        self._sort_option = next_value
        self.sortOptionChanged.emit()
        self._refresh_from_first_page()

    @Slot(int)
    def goToPage(self, value: int) -> None:
        if self._current_path != "/":
            return
        next_page = max(1, min(int(value or 1), self._total_pages))
        if next_page == self._current_page:
            return
        self._current_page = next_page
        self.paginationChanged.emit()
        self._clear_transient_state()
        self.refresh()

    @Slot()
    def previousPage(self) -> None:
        self.goToPage(self._current_page - 1)

    @Slot()
    def nextPage(self) -> None:
        self.goToPage(self._current_page + 1)

    @Slot(int)
    def setPageSize(self, value: int) -> None:
        next_size = self._normalize_page_size(value)
        if next_size == self._page_size:
            return
        self._page_size = next_size
        self._current_page = 1
        self.paginationChanged.emit()
        self._clear_transient_state()
        self.refresh()

    @Slot()
    def toggleDetailPanel(self) -> None:
        self._detail_panel_visible = not self._detail_panel_visible
        self.detailPanelVisibleChanged.emit()

    @Slot(bool)
    def setDetailPanelVisible(self, value: bool) -> None:
        if bool(value) == self._detail_panel_visible:
            return
        self._detail_panel_visible = bool(value)
        self.detailPanelVisibleChanged.emit()

    @Slot(str)
    def selectItem(self, path: str) -> None:
        if not path:
            return
        self._selected_paths = [path]
        self.selectedPathsChanged.emit()
        self._sync_preview_with_selection()
        self._rebuild_selected_item()
        self._rebuild_visible_items()

    @Slot(str)
    def toggleSelection(self, path: str) -> None:
        if not path:
            return
        next_paths = list(self._selected_paths)
        if path in next_paths:
            next_paths = [item for item in next_paths if item != path]
        else:
            next_paths.append(path)
        self._selected_paths = next_paths
        self.selectedPathsChanged.emit()
        self._sync_preview_with_selection()
        self._rebuild_selected_item()
        self._rebuild_visible_items()

    @Slot()
    def clearSelection(self) -> None:
        if not self._selected_paths:
            return
        self._selected_paths = []
        self.selectedPathsChanged.emit()
        self._sync_preview_with_selection()
        self._rebuild_selected_item()
        self._rebuild_visible_items()

    @Slot(str)
    def activateItem(self, path: str) -> None:
        if not path:
            return
        if path.startswith(TELEGRAM_GROUP_PATH_PREFIX):
            self._selected_paths = [path]
            self.selectedPathsChanged.emit()
            self._current_path = path
            self.currentPathLabelChanged.emit()
            self.canNavigateUpChanged.emit()
            self._sync_preview_with_selection()
            self._rebuild_selected_item()
            self._rebuild_visible_items()
            return

        self.selectItem(path)
        self.openPreview(path)

    @Slot()
    def openSelection(self) -> None:
        if len(self._selected_paths) != 1:
            return
        self.activateItem(self._selected_paths[0])

    @Slot(str)
    def openPreview(self, path: str) -> None:
        target_path = path or self._selected_primary_path()
        item = self._find_item_by_path(target_path)
        if not item or item.get("isDir"):
            return

        self.selectItem(target_path)
        self._detail_panel_visible = True
        self.detailPanelVisibleChanged.emit()

        kind = self._item_kind(item)
        if kind not in {"image", "video"}:
            self._show_toast("warning", "当前文件类型暂不支持内置预览")
            return

        self._preview_token += 1
        token = self._preview_token
        self._reset_preview_state(cancel_existing=True)
        self._preview_item_path = target_path
        self._preview_state = {
            "mode": kind,
            "source": "",
            "status": "正在准备本地预览缓存",
            "info": self._file_time_text(item),
            "busy": True,
            "ready": False,
        }
        self.previewStateChanged.emit()

        if kind == "image":
            self._task_runner.submit(
                lambda: self._prepare_image_preview(target_path),
                on_success=lambda result: self._apply_image_preview(token, result),
                on_error=lambda message: self._apply_preview_error(token, message),
            )
            return

        self._task_runner.submit(
            lambda: self._start_video_preview(target_path),
            on_success=lambda result: self._apply_video_preview(token, result),
            on_error=lambda message: self._apply_preview_error(token, message),
        )

    @Slot()
    def closePreview(self) -> None:
        self._preview_token += 1
        self._reset_preview_state(cancel_existing=True)

    @Slot(str)
    def downloadItem(self, path: str) -> None:
        target_path = path or self._selected_primary_path()
        items = self._resolve_download_items(target_path)
        self._queue_downloads(items)

    @Slot()
    def batchDownloadSelected(self) -> None:
        items: list[dict[str, Any]] = []
        for path in self._selected_paths:
            items.extend(self._resolve_download_items(path))
        unique_items = self._unique_items(items)
        self._queue_downloads(unique_items)

    @Slot(str)
    def deleteItem(self, path: str) -> None:
        target_path = path or self._selected_primary_path()
        if not target_path:
            return

        if target_path.startswith(TELEGRAM_GROUP_PATH_PREFIX):
            group = self._group_meta.get(target_path)
            if not group:
                self._set_error_message("媒体组信息缺失，无法删除")
                return
            self._task_runner.submit(
                lambda: self._api_client.delete_telegram_group(str(group.get("mediaGroupId") or "")),
                on_success=lambda result: self._handle_delete_result(result, "已删除媒体组", {target_path}),
                on_error=self._set_error_message,
            )
            return

        meta = self._telegram_meta.get(target_path)
        message_id = int(meta.get("messageId") or 0) if meta else 0
        if message_id <= 0:
            self._set_error_message("文件消息 ID 缺失，无法删除")
            return
        self._task_runner.submit(
            lambda: self._api_client.delete_telegram_item(message_id),
            on_success=lambda result: self._handle_delete_result(result, "已删除 Telegram 文件", {target_path}),
            on_error=self._set_error_message,
        )

    @Slot()
    def deleteSelected(self) -> None:
        self.deleteItem(self._selected_primary_path())

    @Slot()
    def batchDeleteSelected(self) -> None:
        selected_paths = list(self._selected_paths)
        if not selected_paths:
            return
        self._task_runner.submit(
            lambda: self._delete_paths(selected_paths),
            on_success=lambda payload: self._handle_batch_delete_result(payload, selected_paths),
            on_error=self._set_error_message,
        )

    def _delete_paths(self, paths: list[str]) -> dict[str, Any]:
        group_ids: list[str] = []
        message_ids: list[int] = []
        for path in paths:
            if path.startswith(TELEGRAM_GROUP_PATH_PREFIX):
                group = self._group_meta.get(path)
                media_group_id = str(group.get("mediaGroupId") or "") if group else ""
                if media_group_id:
                    group_ids.append(media_group_id)
                continue
            meta = self._telegram_meta.get(path) or {}
            message_id = int(meta.get("messageId") or 0)
            if message_id > 0:
                message_ids.append(message_id)

        deleted_groups = 0
        deleted_files = 0
        for media_group_id in group_ids:
            self._api_client.delete_telegram_group(media_group_id)
            deleted_groups += 1
        for message_id in message_ids:
            self._api_client.delete_telegram_item(message_id)
            deleted_files += 1
        return {
            "deletedGroups": deleted_groups,
            "deletedFiles": deleted_files,
        }

    def _map_telegram_items(self, records: list[dict[str, Any]]) -> list[dict[str, Any]]:
        items: list[dict[str, Any]] = []
        self._telegram_meta = {}
        self._group_meta = {}

        for index, record in enumerate(records):
            message_id = int(record.get("message_id") or 0)
            mime_type = str(record.get("mime_type") or "")
            extension = f".{mime_type.split('/', 1)[1]}" if "/" in mime_type else ""
            fallback_name = f"media_{message_id}{extension}" if message_id else f"media_{index + 1}.bin"
            path = f"tg://{message_id}" if message_id else f"tg://{index + 1}"
            stream_url = str(record.get("stream_url") or "")
            caption = str(record.get("caption") or "")
            remote_path = path

            self._telegram_meta[path] = {
                "streamUrl": stream_url,
                "hash": str(record.get("hash") or ""),
                "caption": caption,
                "duration": record.get("duration"),
                "messageId": message_id,
                "supportsStreaming": bool(record.get("supports_streaming")),
                "mediaGroupId": str(record.get("media_group_id") or ""),
                "sourceUrl": str(record.get("source_url") or ""),
                "remotePath": remote_path,
                "description": caption,
                "thumbnailUrl": self._first_non_empty(
                    record,
                    "thumbnail_url",
                    "thumbnailUrl",
                    "thumb_url",
                    "thumbUrl",
                ),
            }

            items.append(
                {
                    "name": str(record.get("file_name") or fallback_name),
                    "path": path,
                    "size": int(record.get("file_size") or 0),
                    "mimeType": mime_type,
                    "modTime": str(record.get("message_date") or ""),
                    "isDir": False,
                }
            )

        return items

    def _rebuild_visible_items(self) -> None:
        self._rebuild_group_meta()
        self._rebuild_sidebar_stats()

        if self._current_path != "/" and self._current_path not in self._group_meta:
            self._current_path = "/"
            self.currentPathLabelChanged.emit()
            self.canNavigateUpChanged.emit()

        self._visible_items = self._build_visible_items()
        self._items_model.set_items(self._visible_items)

        total = self._total_items if self._current_path == "/" else len(self._raw_items)
        visible = len(self._visible_items)
        self._filter_summary = f"{self._breadcrumb_text} · {self._workspace_subtitle(visible)}"
        self.filterSummaryChanged.emit()

        self._empty_state = self._empty_state_text(total)
        self.emptyStateChanged.emit()

        self._rebuild_selection_summary()
        self._rebuild_selected_item()
        self.paginationChanged.emit()

    def _build_visible_items(self) -> list[dict[str, Any]]:
        if self._current_path != "/":
            group_items = self._group_members(self._current_path)
            rows = [self._build_file_row(item, in_group=True) for item in group_items]
            rows = self._sort_rows(rows)
            self._all_file_rows = rows
            self._all_flow_rows = rows
            self._update_workspace_meta(rows)
            return rows

        file_rows = [self._build_file_row(item, in_group=False) for item in self._raw_items]
        flow_rows = self._build_root_flow_rows()
        self._all_file_rows = self._sort_rows(file_rows)
        self._all_flow_rows = self._sort_rows(flow_rows)

        if self._sidebar_section == "flows":
            rows = list(self._all_flow_rows)
        elif self._sidebar_section == "recent":
            rows = [row for row in self._all_file_rows if row.get("isRecent")]
        elif self._sidebar_section == "streaming":
            rows = [row for row in self._all_file_rows if row.get("supportsStreaming")]
        elif self._sidebar_section == "cached":
            rows = [row for row in self._all_file_rows if row.get("isCached")]
        elif self._sidebar_section == "videos":
            rows = [row for row in self._all_file_rows if row.get("kind") == "video"]
        elif self._sidebar_section == "images":
            rows = [row for row in self._all_file_rows if row.get("kind") == "image"]
        elif self._sidebar_section == "documents":
            rows = [row for row in self._all_file_rows if row.get("kind") == "document"]
        else:
            rows = list(self._all_file_rows)

        self._update_workspace_meta(rows)
        return rows

    def _build_root_flow_rows(self) -> list[dict[str, Any]]:
        rows: list[dict[str, Any]] = []

        for group_path, group in self._group_meta.items():
            members = self._group_members(group_path)
            kind_counts = {
                "video": sum(1 for member in members if self._item_kind(member) == "video"),
                "image": sum(1 for member in members if self._item_kind(member) == "image"),
                "document": sum(1 for member in members if self._item_kind(member) == "document"),
            }
            recent = any(self._is_recent(member) for member in members)
            streaming = any(self._supports_streaming(member) for member in members)
            cached = any(self._is_cached_path(str(member.get("path") or "")) for member in members)
            rows.append(
                {
                    "path": group_path,
                    "title": str(group.get("title") or "媒体组"),
                    "name": str(group.get("title") or "媒体组"),
                    "kind": "group",
                    "subtitle": self._group_subtitle(kind_counts, len(members)),
                    "description": f"{len(members)} 个文件",
                    "metaPrimary": format_bytes(group.get("size")),
                    "metaSecondary": format_datetime(group.get("modTime")),
                    "sizeText": format_bytes(group.get("size")),
                    "timeText": format_datetime(group.get("modTime")),
                    "sortTime": str(group.get("modTime") or ""),
                    "sortSize": int(group.get("size") or 0),
                    "sortName": str(group.get("title") or ""),
                    "tone": "warning",
                    "isDir": True,
                    "canPreview": False,
                    "canDownload": True,
                    "canDelete": True,
                    "supportsStreaming": streaming,
                    "isCached": cached,
                    "isRecent": recent,
                    "selected": group_path in self._selected_paths,
                    "selectionOrder": self._selection_order(group_path),
                    "badgeText": self._group_badge_text(kind_counts, len(members)),
                    "thumbnailUrl": "",
                    "thumbnailItems": self._group_thumbnail_items(members),
                    "cardMode": "collage",
                    "countText": f"{len(members)} 项",
                    "groupCount": len(members),
                    "videosCount": kind_counts["video"],
                    "imagesCount": kind_counts["image"],
                    "documentsCount": kind_counts["document"],
                    "remotePath": group_path,
                    "displayPath": self._current_path_label_for_row(group_path),
                    "contextActions": self._context_actions_for_row(True, False, True, True),
                }
            )

        singles = [
            item
            for item in self._raw_items
            if not str((self._telegram_meta.get(str(item.get("path") or "")) or {}).get("mediaGroupId") or "")
        ]
        rows.extend(self._build_file_row(item, in_group=False) for item in singles)
        return rows

    def _build_file_row(self, item: dict[str, Any], *, in_group: bool) -> dict[str, Any]:
        path = str(item.get("path") or "")
        kind = self._item_kind(item)
        meta = self._telegram_meta.get(path) or {}
        title = str(item.get("name") or "未命名文件")
        caption = str(meta.get("caption") or "")
        subtitle = caption or self._kind_label(kind)
        thumbnail_url = self._thumbnail_url_for_item(item)
        card_mode = "image" if thumbnail_url and kind == "image" else ("video" if kind == "video" else "document")
        badge_text = self._kind_label(kind)
        supports_streaming = self._supports_streaming(item)
        is_cached = self._is_cached_path(path)
        is_recent = self._is_recent(item)
        can_preview = kind in {"image", "video"}

        return {
            "path": path,
            "title": title,
            "name": title,
            "kind": kind,
            "subtitle": subtitle,
            "description": subtitle,
            "metaPrimary": format_bytes(item.get("size")),
            "metaSecondary": format_datetime(item.get("modTime")),
            "sizeText": format_bytes(item.get("size")),
            "timeText": format_datetime(item.get("modTime")),
            "sortTime": str(item.get("modTime") or ""),
            "sortSize": int(item.get("size") or 0),
            "sortName": title.lower(),
            "tone": self._kind_tone(kind),
            "isDir": False,
            "canPreview": can_preview,
            "canDownload": True,
            "canDelete": True,
            "supportsStreaming": supports_streaming,
            "isCached": is_cached,
            "isRecent": is_recent,
            "selected": path in self._selected_paths,
            "selectionOrder": self._selection_order(path),
            "badgeText": badge_text,
            "thumbnailUrl": thumbnail_url,
            "thumbnailItems": [],
            "cardMode": card_mode,
            "countText": "1 个文件",
            "groupCount": 0,
            "videosCount": 1 if kind == "video" else 0,
            "imagesCount": 1 if kind == "image" else 0,
            "documentsCount": 1 if kind == "document" else 0,
            "remotePath": str(meta.get("remotePath") or path),
            "displayPath": self._current_path_label_for_file(item, in_group=in_group),
            "contextActions": self._context_actions_for_row(False, can_preview, True, True),
            "streamTag": "可在线播放" if supports_streaming else "",
            "cacheTag": "本地缓存" if is_cached else "",
            "recentTag": "最近" if is_recent else "",
        }

    def _sort_rows(self, rows: list[dict[str, Any]]) -> list[dict[str, Any]]:
        if self._sort_option == "time_asc":
            return sorted(rows, key=self._sort_key_time)
        if self._sort_option == "size_desc":
            return sorted(rows, key=self._sort_key_size, reverse=True)
        if self._sort_option == "name_asc":
            return sorted(rows, key=self._sort_key_name)
        return sorted(rows, key=self._sort_key_time, reverse=True)

    def _sort_key_time(self, row: dict[str, Any]) -> tuple[str, str]:
        return (str(row.get("sortTime") or ""), str(row.get("sortName") or ""))

    def _sort_key_size(self, row: dict[str, Any]) -> tuple[int, str]:
        return (int(row.get("sortSize") or 0), str(row.get("sortName") or ""))

    def _sort_key_name(self, row: dict[str, Any]) -> tuple[str, str]:
        return (str(row.get("sortName") or ""), str(row.get("sortTime") or ""))

    def _rebuild_group_meta(self) -> None:
        grouped: dict[str, list[dict[str, Any]]] = {}
        for item in self._raw_items:
            media_group_id = str((self._telegram_meta.get(str(item.get("path") or "")) or {}).get("mediaGroupId") or "")
            if media_group_id:
                grouped.setdefault(media_group_id, []).append(item)

        next_group_meta: dict[str, dict[str, Any]] = {}
        for media_group_id, members in grouped.items():
            members.sort(key=lambda item: str(item.get("modTime") or ""), reverse=True)
            group_path = f"{TELEGRAM_GROUP_PATH_PREFIX}{media_group_id}"
            next_group_meta[group_path] = {
                "mediaGroupId": media_group_id,
                "title": self._build_group_title(media_group_id, members),
                "count": len(members),
                "size": sum(int(member.get("size") or 0) for member in members),
                "modTime": str(members[0].get("modTime") or ""),
                "memberPaths": [str(member.get("path") or "") for member in members],
            }
        self._group_meta = next_group_meta

    def _rebuild_sidebar_stats(self) -> None:
        counts = {
            "all": len(self._raw_items),
            "videos": 0,
            "images": 0,
            "documents": 0,
            "flows": len(self._group_meta)
            + sum(
                1
                for item in self._raw_items
                if not str((self._telegram_meta.get(str(item.get("path") or "")) or {}).get("mediaGroupId") or "")
            ),
            "recent": 0,
            "streaming": 0,
            "cached": 0,
        }
        for item in self._raw_items:
            kind = self._item_kind(item)
            if kind == "video":
                counts["videos"] += 1
            elif kind == "image":
                counts["images"] += 1
            else:
                counts["documents"] += 1
            if self._is_recent(item):
                counts["recent"] += 1
            if self._supports_streaming(item):
                counts["streaming"] += 1
            if self._is_cached_path(str(item.get("path") or "")):
                counts["cached"] += 1

        self._sidebar_stats = counts
        self.sidebarStatsChanged.emit()

    def _update_workspace_meta(self, rows: list[dict[str, Any]]) -> None:
        files = sum(1 for row in rows if not row.get("isDir"))
        groups = sum(1 for row in rows if row.get("isDir"))
        videos = sum(int(row.get("videosCount") or 0) for row in rows)
        images = sum(int(row.get("imagesCount") or 0) for row in rows)
        documents = sum(int(row.get("documentsCount") or 0) for row in rows)
        self._content_stats = {
            "total": len(rows),
            "files": files,
            "groups": groups,
            "videos": videos,
            "images": images,
            "documents": documents,
        }
        self.contentStatsChanged.emit()

        self._workspace_title = self._workspace_title_for_state()
        self.workspaceTitleChanged.emit()
        self._breadcrumb_text = self._breadcrumb_for_state()
        self.breadcrumbTextChanged.emit()

    def _workspace_title_for_state(self) -> str:
        if self._current_path != "/":
            return "媒体组内容"
        return {
            "flows": "文件流",
            "recent": "最近",
            "streaming": "在线播放",
            "cached": "本地缓存",
            "videos": "视频",
            "images": "图片",
            "documents": "文档",
        }.get(self._sidebar_section, "文件流")

    def _workspace_subtitle(self, visible_count: int) -> str:
        stats = self._content_stats
        if self._current_path != "/":
            return f"{visible_count} 项"
        if self._sidebar_section == "flows":
            return f"全部流 · 共 {self._total_items} 项"
        if self._sidebar_section == "recent":
            return f"近 {RECENT_DAYS} 天 · 共 {self._total_items} 项"
        if self._sidebar_section == "streaming":
            return f"可在线播放 · 共 {self._total_items} 项"
        if self._sidebar_section == "cached":
            return f"本地缓存 · 共 {self._total_items} 项"
        if self._sidebar_section in {"videos", "images", "documents"}:
            return f"{self._workspace_title} · 共 {self._total_items} 项"
        return f"全部 · 全部流 · 共 {self._total_items} 项"

    def _breadcrumb_for_state(self) -> str:
        if self._current_path == "/":
            return "Telegram 频道"
        return f"Telegram 频道 / {self.get_current_path_label()}"

    def _rebuild_selected_item(self) -> None:
        primary_path = self._selected_primary_path()
        if not primary_path:
            self._selected_item = self._empty_selected_item()
            self.selectedItemChanged.emit()
            return

        group = self._group_meta.get(primary_path)
        if group is not None:
            members = self._group_members(primary_path)
            thumbnails = self._group_thumbnail_items(members)
            self._selected_item = {
                "path": primary_path,
                "title": str(group.get("title") or "媒体组"),
                "subtitle": f"{len(members)} 个文件",
                "metaPrimary": format_bytes(group.get("size")),
                "metaSecondary": format_datetime(group.get("modTime")),
                "kindLabel": "媒体组",
                "canPreview": False,
                "canDownload": True,
                "canDelete": True,
                "isDir": True,
                "hasSelection": True,
                "hasMultiple": len(self._selected_paths) > 1,
                "thumbnailUrl": "",
                "thumbnailItems": thumbnails,
                "badgeText": self._group_badge_text(
                    {
                        "video": sum(1 for member in members if self._item_kind(member) == "video"),
                        "image": sum(1 for member in members if self._item_kind(member) == "image"),
                        "document": sum(1 for member in members if self._item_kind(member) == "document"),
                    },
                    len(members),
                ),
                "description": "单击选择，双击打开，右键操作",
            }
            self.selectedItemChanged.emit()
            return

        item = self._find_item_by_path(primary_path)
        if not item:
            self._selected_item = self._empty_selected_item()
            self.selectedItemChanged.emit()
            return

        kind = self._item_kind(item)
        meta = self._telegram_meta.get(primary_path) or {}
        self._selected_item = {
            "path": primary_path,
            "title": str(item.get("name") or "未命名文件"),
            "subtitle": str(meta.get("caption") or self._kind_label(kind)),
            "metaPrimary": format_bytes(item.get("size")),
            "metaSecondary": format_datetime(item.get("modTime")),
            "kindLabel": self._kind_label(kind),
            "canPreview": kind in {"image", "video"},
            "canDownload": True,
            "canDelete": True,
            "isDir": False,
            "hasSelection": True,
            "hasMultiple": len(self._selected_paths) > 1,
            "thumbnailUrl": self._thumbnail_url_for_item(item),
            "thumbnailItems": [],
            "badgeText": self._kind_label(kind),
            "description": str(meta.get("caption") or ""),
            "remotePath": str(meta.get("remotePath") or primary_path),
        }
        self.selectedItemChanged.emit()

    def _rebuild_selection_summary(self) -> None:
        selection_count = len(self._selected_paths)
        if selection_count <= 0:
            self._selection_summary = "未选择内容"
        else:
            files = sum(1 for path in self._selected_paths if not path.startswith(TELEGRAM_GROUP_PATH_PREFIX))
            groups = selection_count - files
            self._selection_summary = f"已选 {selection_count} 项  {files} 个文件 · {groups} 个媒体组"
        self.selectionSummaryChanged.emit()

    def _empty_selected_item(self) -> dict[str, Any]:
        return {
            "path": "",
            "title": "",
            "subtitle": "选择一个文件或媒体组以查看详情",
            "metaPrimary": "-",
            "metaSecondary": "-",
            "kindLabel": "",
            "canPreview": False,
            "canDownload": False,
            "canDelete": False,
            "isDir": False,
            "hasSelection": False,
            "hasMultiple": False,
            "thumbnailUrl": "",
            "thumbnailItems": [],
            "badgeText": "",
            "description": "",
        }

    def _empty_preview_state(self) -> dict[str, Any]:
        return {
            "mode": "none",
            "source": "",
            "status": "选择图片或视频后可在右侧预览",
            "info": "",
            "busy": False,
            "ready": False,
        }

    def _normalize_page_size(self, value: int) -> int:
        try:
            candidate = int(value)
        except (TypeError, ValueError):
            return DEFAULT_PAGE_SIZE
        return candidate if candidate in PAGE_SIZE_CHOICES else DEFAULT_PAGE_SIZE

    def _clear_transient_state(self) -> None:
        if self._selected_paths:
            self._selected_paths = []
            self.selectedPathsChanged.emit()
        self._reset_preview_state(cancel_existing=True)
        self._rebuild_selected_item()
        self._rebuild_selection_summary()

    def _refresh_from_first_page(self) -> None:
        if self._current_path != "/":
            self._current_path = "/"
            self.currentPathLabelChanged.emit()
            self.canNavigateUpChanged.emit()
        self._current_page = 1
        self.paginationChanged.emit()
        self._clear_transient_state()
        self.refresh()

    def _reset_preview_state(self, *, cancel_existing: bool) -> None:
        if cancel_existing and self._preview_transfer_id:
            try:
                self._local_runtime_service.cancel_preview(self._preview_transfer_id)
            except Exception:
                pass
        self._preview_transfer_id = ""
        self._preview_item_path = ""
        self._preview_state = self._empty_preview_state()
        self.previewStateChanged.emit()

    def _prepare_image_preview(self, path: str) -> dict[str, Any]:
        item = self._find_item_by_path(path)
        if not item:
            raise RuntimeError("未找到需要预览的图片")
        result = self._local_runtime_service.prepare_preview_file(
            source_url=self._source_url_for_item(item),
            remote="telegram",
            remote_path=str(item.get("path") or ""),
            file_name=str(item.get("name") or "image"),
        )
        local_path = str(result.get("localPath") or "")
        return {
            "source": QUrl.fromLocalFile(local_path).toString(),
            "info": local_path,
        }

    def _apply_image_preview(self, token: int, payload: dict[str, Any]) -> None:
        if token != self._preview_token:
            return
        self._preview_state = {
            "mode": "image",
            "source": str(payload.get("source") or ""),
            "status": "图片预览已就绪",
            "info": str(payload.get("info") or ""),
            "busy": False,
            "ready": True,
        }
        self.previewStateChanged.emit()
        self._refresh_cached_paths()
        self._rebuild_visible_items()

    def _start_video_preview(self, path: str) -> dict[str, Any]:
        item = self._find_item_by_path(path)
        if not item:
            raise RuntimeError("未找到需要预览的视频")
        return self._local_runtime_service.start_preview_stream(
            source_url=self._source_url_for_item(item),
            remote="telegram",
            remote_path=str(item.get("path") or ""),
            file_name=str(item.get("name") or "video"),
        )

    def _apply_video_preview(self, token: int, payload: dict[str, Any]) -> None:
        if token != self._preview_token:
            transfer_id = str(payload.get("transferId") or "")
            if transfer_id:
                try:
                    self._local_runtime_service.cancel_preview(transfer_id)
                except Exception:
                    pass
            return

        self._preview_transfer_id = str(payload.get("transferId") or "")
        ready = bool(payload.get("readyForPreview"))
        self._preview_state = {
            "mode": "video",
            "source": str(payload.get("streamUrl") or ""),
            "status": "视频已达到可播放阈值" if ready else "正在准备本地播放缓存",
            "info": "本地流已可播放" if ready else "达到缓存阈值后即可开始播放",
            "busy": not ready,
            "ready": ready,
        }
        self.previewStateChanged.emit()
        self._refresh_cached_paths()
        self._rebuild_visible_items()

    def _apply_preview_error(self, token: int, message: str) -> None:
        if token != self._preview_token:
            return
        self._preview_transfer_id = ""
        self._preview_state = {
            "mode": self._preview_state.get("mode") or "none",
            "source": "",
            "status": "预览准备失败",
            "info": message,
            "busy": False,
            "ready": False,
        }
        self.previewStateChanged.emit()
        self._set_error_message(message)

    def _handle_transfer_update(self, payload: dict[str, Any]) -> None:
        remote = str(payload.get("remote") or "")
        remote_path = str(payload.get("remotePath") or "")
        if remote == "telegram" and remote_path.startswith("tg://"):
            state = str(payload.get("state") or "")
            if state in {"completed", "ready", "downloading"}:
                if remote_path not in self._cached_paths:
                    self._refresh_cached_paths()
                    self._rebuild_visible_items()

        if str(payload.get("transferId") or "") != self._preview_transfer_id:
            return

        state = str(payload.get("state") or "")
        if state == "error":
            self._preview_state["status"] = "本地播放缓存失败"
            self._preview_state["info"] = str(payload.get("error") or "未知错误")
            self._preview_state["busy"] = False
            self._preview_state["ready"] = False
        elif state == "completed":
            self._preview_state["status"] = "视频缓存完成"
            self._preview_state["info"] = self._preview_info(payload)
            self._preview_state["busy"] = False
            self._preview_state["ready"] = True
        elif state == "ready":
            self._preview_state["status"] = "视频已达到可播放阈值"
            self._preview_state["info"] = self._preview_info(payload)
            self._preview_state["busy"] = False
            self._preview_state["ready"] = True
        else:
            self._preview_state["status"] = "正在准备本地播放缓存"
            self._preview_state["info"] = self._preview_info(payload)
            self._preview_state["busy"] = True
            self._preview_state["ready"] = False
        self.previewStateChanged.emit()

    def _preview_info(self, payload: dict[str, Any]) -> str:
        downloaded = format_bytes(payload.get("downloadedBytes"))
        total = payload.get("totalBytes")
        speed = int(payload.get("downloadSpeed") or 0)
        total_text = format_bytes(total) if total else "未知"
        if speed > 0:
            return f"已缓存 {downloaded} / {total_text} · {format_bytes(speed)}/s"
        return f"已缓存 {downloaded} / {total_text}"

    def _handle_delete_result(self, result: dict[str, Any], fallback_message: str, removed_paths: set[str]) -> None:
        self._show_toast("success", str(result.get("message") or fallback_message))
        self._selected_paths = [path for path in self._selected_paths if path not in removed_paths]
        self.selectedPathsChanged.emit()
        if self._preview_item_path in removed_paths:
            self._reset_preview_state(cancel_existing=True)
        if self._current_path != "/" and self._current_path in removed_paths:
            self._current_path = "/"
            self.currentPathLabelChanged.emit()
            self.canNavigateUpChanged.emit()
        if self._current_path == "/" and len(removed_paths) >= len(self._raw_items) and self._current_page > 1:
            self._current_page -= 1
            self.paginationChanged.emit()
        self.refresh()

    def _handle_batch_delete_result(self, payload: dict[str, Any], selected_paths: list[str]) -> None:
        deleted_groups = int(payload.get("deletedGroups") or 0)
        deleted_files = int(payload.get("deletedFiles") or 0)
        self._show_toast("success", f"已删除 {deleted_files} 个文件，{deleted_groups} 个媒体组")
        removed = set(selected_paths)
        self._selected_paths = [path for path in self._selected_paths if path not in removed]
        self.selectedPathsChanged.emit()
        if self._preview_item_path in removed:
            self._reset_preview_state(cancel_existing=True)
        if self._current_path != "/" and self._current_path in removed:
            self._current_path = "/"
            self.currentPathLabelChanged.emit()
            self.canNavigateUpChanged.emit()
        if self._current_path == "/" and len(removed) >= len(self._raw_items) and self._current_page > 1:
            self._current_page -= 1
            self.paginationChanged.emit()
        self.refresh()

    def _handle_clear_result(self, result: dict[str, Any]) -> None:
        self._show_toast("success", str(result.get("message") or "已清空 Telegram 媒体"))
        self._selected_paths = []
        self.selectedPathsChanged.emit()
        self._current_path = "/"
        self.currentPathLabelChanged.emit()
        self.canNavigateUpChanged.emit()
        self._current_page = 1
        self._total_items = 0
        self._total_pages = 1
        self.paginationChanged.emit()
        self._reset_preview_state(cancel_existing=True)
        self.refresh()

    def _resolve_download_items(self, path: str) -> list[dict[str, Any]]:
        if not path:
            return []
        if path.startswith(TELEGRAM_GROUP_PATH_PREFIX):
            return self._group_members(path)
        item = self._find_item_by_path(path)
        return [item] if item else []

    def _queue_downloads(self, items: list[dict[str, Any]]) -> None:
        if not items:
            return

        queued = 0
        existing = 0
        for item in self._unique_items(items):
            result = self._local_runtime_service.start_download(
                source_url=self._source_url_for_item(item),
                remote="telegram",
                remote_path=str(item.get("path") or ""),
                file_name=str(item.get("name") or "未命名文件"),
            )
            if result.get("existing"):
                existing += 1
            else:
                queued += 1

        if queued > 0 and existing > 0:
            self._show_toast("success", f"已加入下载 {queued} 项，{existing} 项已在队列中")
        elif queued > 0:
            self._show_toast("success", f"已加入本地下载 {queued} 项")
        elif existing > 0:
            self._show_toast("info", "所选文件已在本地下载队列中")
        self._refresh_cached_paths()
        self._rebuild_visible_items()

    def _group_members(self, group_path: str) -> list[dict[str, Any]]:
        group = self._group_meta.get(group_path) or {}
        member_paths = list(group.get("memberPaths") or [])
        items = [self._find_item_by_path(path) for path in member_paths]
        return [item for item in items if item is not None]

    def _find_item_by_path(self, path: str) -> dict[str, Any] | None:
        for item in self._raw_items:
            if item.get("path") == path:
                return item
        return None

    def _backend_sort_params(self) -> tuple[str, bool]:
        if self._sort_option == "time_asc":
            return ("message_date", False)
        if self._sort_option == "size_desc":
            return ("file_size", True)
        if self._sort_option == "name_asc":
            return ("file_name", False)
        return ("message_date", True)

    def _build_group_title(self, media_group_id: str, members: list[dict[str, Any]]) -> str:
        for member in members:
            meta = self._telegram_meta.get(str(member.get("path") or "")) or {}
            caption = str(meta.get("caption") or "").strip()
            if caption:
                return caption[:48]
        suffix = media_group_id[-8:] if len(media_group_id) >= 8 else media_group_id
        return f"媒体组 {suffix}"

    def _source_url_for_item(self, item: dict[str, Any]) -> str:
        path = str(item.get("path") or "")
        meta = self._telegram_meta.get(path) or {}
        raw_stream_url = str(meta.get("streamUrl") or "").strip()
        fallback_short_path = ""
        if meta.get("hash") and meta.get("messageId"):
            fallback_short_path = f"/{meta['hash']}{meta['messageId']}"

        if not raw_stream_url and not fallback_short_path:
            raise RuntimeError("Telegram 直链地址缺失，请刷新后重试")
        if raw_stream_url.startswith("http://") or raw_stream_url.startswith("https://"):
            return raw_stream_url

        normalized_path = fallback_short_path
        if raw_stream_url:
            normalized_path = f"/{raw_stream_url.lstrip('/')}"
        return self._api_client.resolve_server_url(normalized_path)

    def _filter_media_type(self, value: str) -> str:
        return {
            "videos": "video",
            "images": "image",
            "documents": "document",
        }.get(value, "")

    def _item_kind(self, item: dict[str, Any]) -> str:
        if item.get("isDir"):
            return "group"
        mime_type = str(item.get("mimeType") or "")
        suffix = Path(str(item.get("name") or "")).suffix.lower()
        if mime_type.startswith("image/") or suffix in {".jpg", ".jpeg", ".png", ".gif", ".webp", ".bmp"}:
            return "image"
        if mime_type.startswith("video/") or suffix in {".mp4", ".mkv", ".mov", ".webm", ".m4v"}:
            return "video"
        return "document"

    def _kind_label(self, kind: str) -> str:
        return {
            "group": "媒体组",
            "image": "图片",
            "video": "视频",
            "document": "文档",
        }.get(kind, "文件")

    def _kind_tone(self, kind: str) -> str:
        return {
            "group": "warning",
            "image": "success",
            "video": "primary",
            "document": "info",
        }.get(kind, "info")

    def _thumbnail_url_for_item(self, item: dict[str, Any]) -> str:
        if self._item_kind(item) != "image":
            return ""
        path = str(item.get("path") or "")
        meta = self._telegram_meta.get(path) or {}
        thumbnail_url = self._first_non_empty(
            item,
            "thumbnail_url",
            "thumbnailUrl",
            "thumb_url",
            "thumbUrl",
        ) or str(meta.get("thumbnailUrl") or "")
        return self._normalize_thumbnail_url(thumbnail_url)

    def _first_non_empty(self, source: dict[str, Any], *keys: str) -> str:
        for key in keys:
            value = str(source.get(key) or "").strip()
            if value:
                return value
        return ""

    def _normalize_thumbnail_url(self, thumbnail_url: str) -> str:
        thumbnail_url = thumbnail_url.strip()
        if not thumbnail_url:
            return ""
        if thumbnail_url.startswith("http://") or thumbnail_url.startswith("https://"):
            return thumbnail_url
        try:
            return self._api_client.resolve_server_url(thumbnail_url)
        except Exception:
            return ""

    def _group_thumbnail_items(self, members: list[dict[str, Any]]) -> list[dict[str, Any]]:
        thumbnails: list[dict[str, Any]] = []
        for member in members[:4]:
            kind = self._item_kind(member)
            thumbnails.append(
                {
                    "kind": kind,
                    "thumbnailUrl": self._thumbnail_url_for_item(member),
                    "label": self._kind_label(kind),
                }
            )
        return thumbnails

    def _supports_streaming(self, item: dict[str, Any]) -> bool:
        meta = self._telegram_meta.get(str(item.get("path") or "")) or {}
        if bool(meta.get("supportsStreaming")):
            return True
        return self._item_kind(item) in {"image", "video"}

    def _group_subtitle(self, kind_counts: dict[str, int], total: int) -> str:
        if kind_counts["video"] == total:
            return f"{total} 个视频"
        if kind_counts["image"] == total:
            return f"{total} 张图片"
        if kind_counts["document"] == total:
            return f"{total} 个文档"
        return f"{total} 个文件"

    def _group_badge_text(self, kind_counts: dict[str, int], total: int) -> str:
        if kind_counts["video"] > 0:
            return f"{kind_counts['video']} 个视频"
        if kind_counts["image"] > 0:
            return f"{kind_counts['image']} 张图片"
        if kind_counts["document"] > 0:
            return f"{kind_counts['document']} 个文档"
        return f"{total} 项"

    def _selection_order(self, path: str) -> int:
        try:
            return self._selected_paths.index(path) + 1
        except ValueError:
            return 0

    def _selected_primary_path(self) -> str:
        return self._selected_paths[0] if self._selected_paths else ""

    def _unique_items(self, items: list[dict[str, Any]]) -> list[dict[str, Any]]:
        seen: set[str] = set()
        unique: list[dict[str, Any]] = []
        for item in items:
            path = str(item.get("path") or "")
            if not path or path in seen:
                continue
            seen.add(path)
            unique.append(item)
        return unique

    def _sync_preview_with_selection(self) -> None:
        primary = self._selected_primary_path()
        if self._preview_item_path and self._preview_item_path != primary:
            self._reset_preview_state(cancel_existing=True)

    def _refresh_cached_paths(self) -> None:
        cached: set[str] = set()
        try:
            for snapshot in self._local_runtime_service.list_download_statuses():
                if str(snapshot.get("remote") or "") != "telegram":
                    continue
                remote_path = str(snapshot.get("remotePath") or "")
                state = str(snapshot.get("state") or "")
                if remote_path.startswith("tg://") and state in {"completed", "ready", "downloading", "pending"}:
                    cached.add(remote_path)
        except Exception:
            pass

        cache_root = self._local_runtime_service.preview_cache_root()
        for item in self._raw_items:
            path = str(item.get("path") or "")
            if not path:
                continue
            try:
                source_url = self._source_url_for_item(item)
            except Exception:
                continue
            source_hash = self._extract_telegram_source_hash(source_url)
            if not source_hash:
                continue
            if self._has_cached_identity(cache_root, source_hash):
                cached.add(path)

        self._cached_paths = cached

    def _has_cached_identity(self, root: Path, source_hash: str) -> bool:
        try:
            root_exists = root.exists()
        except OSError:
            return False
        if not root_exists:
            return False
        try:
            sidecars = list(root.rglob("*.mistrelay.json"))
        except OSError:
            return False
        for sidecar in sidecars:
            try:
                content = sidecar.read_text(encoding="utf-8")
            except OSError:
                continue
            if f'"source_hash": "{source_hash}"' in content:
                return True
        return False

    def _extract_telegram_source_hash(self, source_url: str) -> str | None:
        parsed = urlparse(source_url)
        for key, value in parse_qsl(parsed.query):
            if key == "hash" and value.strip():
                return value
        return None

    def _is_cached_path(self, path: str) -> bool:
        return path in self._cached_paths

    def _parse_datetime(self, value: str | None) -> datetime | None:
        if not value:
            return None
        normalized = value.replace("Z", "+00:00")
        try:
            parsed = datetime.fromisoformat(normalized)
        except ValueError:
            return None
        if parsed.tzinfo is not None:
            parsed = parsed.astimezone().replace(tzinfo=None)
        return parsed

    def _is_recent(self, item: dict[str, Any]) -> bool:
        parsed = self._parse_datetime(str(item.get("modTime") or ""))
        if parsed is None:
            return False
        return parsed >= datetime.now() - timedelta(days=RECENT_DAYS)

    def _file_time_text(self, item: dict[str, Any]) -> str:
        return format_datetime(item.get("modTime"))

    def _current_path_label_for_file(self, item: dict[str, Any], *, in_group: bool) -> str:
        if in_group:
            return self.get_current_path_label()
        media_group_id = str((self._telegram_meta.get(str(item.get("path") or "")) or {}).get("mediaGroupId") or "")
        if media_group_id:
            group_path = f"{TELEGRAM_GROUP_PATH_PREFIX}{media_group_id}"
            group = self._group_meta.get(group_path) or {}
            return str(group.get("title") or "Telegram 频道")
        return "Telegram 频道"

    def _current_path_label_for_row(self, path: str) -> str:
        group = self._group_meta.get(path) or {}
        return str(group.get("title") or "Telegram 频道")

    def _empty_state_text(self, total: int) -> str:
        if total <= 0:
            return "Telegram 频道还没有可浏览的媒体文件。"
        if self._current_path == "/" and self._total_items > 0 and len(self._raw_items) == 0:
            return "当前页没有内容，已尝试回退页码，请刷新后重试。"
        if self._sidebar_section == "cached":
            return "当前没有本地缓存内容。"
        if self._sidebar_section == "recent":
            return f"最近 {RECENT_DAYS} 天没有匹配内容。"
        if self._sidebar_section == "streaming":
            return "当前没有可在线播放内容。"
        if self._sidebar_section == "flows":
            return "当前没有媒体流内容。"
        if self._current_path != "/":
            return "这个媒体组里还没有可显示内容。"
        return "当前筛选下没有匹配的 Telegram 媒体。"

    def _context_actions_for_row(self, is_dir: bool, can_preview: bool, can_download: bool, can_delete: bool) -> dict[str, Any]:
        return {
            "canOpen": True,
            "canPreview": can_preview,
            "canDownload": can_download,
            "canDelete": can_delete,
            "isDir": is_dir,
        }

    subtitle = Property(str, get_subtitle, notify=subtitleChanged)
    usageSummary = Property(str, get_usage_summary, notify=usageSummaryChanged)
    currentFilter = Property(str, get_current_filter, notify=currentFilterChanged)
    searchKeyword = Property(str, get_search_keyword, notify=searchKeywordChanged)
    currentPathLabel = Property(str, get_current_path_label, notify=currentPathLabelChanged)
    canNavigateUp = Property(bool, get_can_navigate_up, notify=canNavigateUpChanged)
    filterSummary = Property(str, get_filter_summary, notify=filterSummaryChanged)
    selectedItem = Property("QVariantMap", get_selected_item, notify=selectedItemChanged)
    previewState = Property("QVariantMap", get_preview_state, notify=previewStateChanged)
    emptyState = Property(str, get_empty_state, notify=emptyStateChanged)
    itemsModel = Property(QObject, get_items_model, constant=True)
    viewMode = Property(str, get_view_mode, notify=viewModeChanged)
    sortOption = Property(str, get_sort_option, notify=sortOptionChanged)
    detailPanelVisible = Property(bool, get_detail_panel_visible, notify=detailPanelVisibleChanged)
    sidebarSection = Property(str, get_sidebar_section, notify=sidebarSectionChanged)
    sidebarStats = Property("QVariantMap", get_sidebar_stats, notify=sidebarStatsChanged)
    workspaceTitle = Property(str, get_workspace_title, notify=workspaceTitleChanged)
    breadcrumbText = Property(str, get_breadcrumb_text, notify=breadcrumbTextChanged)
    selectionSummary = Property(str, get_selection_summary, notify=selectionSummaryChanged)
    selectedPaths = Property("QStringList", get_selected_paths, notify=selectedPathsChanged)
    hasSelection = Property(bool, get_has_selection, notify=selectedPathsChanged)
    selectionCount = Property(int, get_selection_count, notify=selectedPathsChanged)
    contentStats = Property("QVariantMap", get_content_stats, notify=contentStatsChanged)
    channelSummary = Property(str, get_channel_summary, notify=channelSummaryChanged)
    channelStats = Property("QVariantMap", get_channel_stats, notify=channelStatsChanged)
    currentPage = Property(int, get_current_page, notify=paginationChanged)
    pageSize = Property(int, get_page_size, notify=paginationChanged)
    totalItems = Property(int, get_total_items, notify=paginationChanged)
    totalPages = Property(int, get_total_pages, notify=paginationChanged)
    pageSummary = Property(str, get_page_summary, notify=paginationChanged)
    canPreviousPage = Property(bool, get_can_previous_page, notify=paginationChanged)
    canNextPage = Property(bool, get_can_next_page, notify=paginationChanged)
    showFilesChips = Property(bool, get_show_files_chips, notify=sidebarSectionChanged)
    openEnabled = Property(bool, get_open_enabled, notify=selectedPathsChanged)
    batchDownloadEnabled = Property(bool, get_batch_download_enabled, notify=selectedPathsChanged)
    batchDeleteEnabled = Property(bool, get_batch_delete_enabled, notify=selectedPathsChanged)
