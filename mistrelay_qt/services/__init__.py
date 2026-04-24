__all__ = [
    "ApiClient",
    "ConfigService",
    "LocalCacheService",
    "LocalRuntimeService",
    "UpdateService",
    "WebsocketService",
]


def __getattr__(name: str):
    if name == "ApiClient":
        from .api_client import ApiClient

        return ApiClient
    if name == "ConfigService":
        from .config_service import ConfigService

        return ConfigService
    if name == "LocalCacheService":
        from .local_cache_service import LocalCacheService

        return LocalCacheService
    if name == "LocalRuntimeService":
        from .local_runtime_service import LocalRuntimeService

        return LocalRuntimeService
    if name == "UpdateService":
        from .update_service import UpdateService

        return UpdateService
    if name == "WebsocketService":
        from .websocket_service import WebsocketService

        return WebsocketService
    raise AttributeError(name)
