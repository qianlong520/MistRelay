# MistRelay Windows 桌面客户端

MistRelay 是面向 Windows 的正式桌面客户端，基于 `PySide6 + Qt Quick/QML` 构建，用于连接 MistRelay 服务端并完成任务管理、网盘浏览、本地下载、运行状态查看和客户端更新。

当前正式版本以 `version.json` 为版本源，通过 GitHub Releases 发布安装包、更新清单和文件级热更补丁。客户端支持签名校验、整包静默安装更新，以及优先使用文件级补丁的轻量热更新。

## 核心能力

- 登录、会话恢复、Dashboard 概览和任务状态查看。
- 下载管理、Telegram 网盘浏览、本地下载与预览。
- 服务端连接配置、代理配置、下载参数和缓存目录配置。
- 服务端分类配置读取、保存，以及从 `config.yml` 重新导入。
- Rclone 配置文件读取与保存。
- Docker 状态、Docker 日志、系统资源和应用日志查看。
- Windows 自动更新：优先文件级热更补丁，必要时回退整包安装器更新。

## 安装与运行

### 用户安装

从 GitHub Release 下载当前版本安装包：

- `mistrelay-v<version>-setup.exe`

安装器默认安装到当前用户目录：

```text
%LOCALAPPDATA%\Programs\MistRelay
```

安装完成后可通过桌面快捷方式或开始菜单启动。

### 本地运行

开发环境可直接运行源码：

```powershell
.\.venv\Scripts\python.exe scripts/dev_env.py run
```

如果要避免污染本机已有配置和缓存，可使用隔离模式：

```powershell
.\.venv\Scripts\python.exe scripts/dev_env.py run --isolated
```

## 配置与缓存路径

客户端会使用独立的 Qt 配置文件：

- Windows 配置：`%APPDATA%\MistRelay\desktop-client-qt.json`
- Windows 缓存：`%LOCALAPPDATA%\MistRelay`
- 更新缓存：`%LOCALAPPDATA%\MistRelay\updates`
- 更新回滚备份：`%LOCALAPPDATA%\MistRelay\update-backups`

开发隔离模式会把配置和缓存写入仓库内：

- `.local/config`
- `.local/cache`

## 更新能力概览

正式版客户端通过 `qt-latest.json` 获取更新信息，并用 `qt-latest.json.sig` 验证清单签名。

更新策略：

- 优先使用 `qt-patch-<from>-to-<to>.zip` 文件级热更补丁。
- QML、主题、图片、JSON 等可安全替换资源可在下载后立即应用。
- `exe`、`dll`、`pyd` 等运行中可能被锁定的文件会通过外部脚本在重启阶段替换。
- 补丁不适用、校验失败或应用失败时，保留现有客户端并回退到整包安装器更新。

详细发布、热更、回滚和排障说明见：[`docs/更新文档.md`](docs/更新文档.md)。

## 本地开发

### 环境要求

- Windows 10/11 x64
- Python `3.11.x` x64
- `pip`
- NSIS（仅构建安装器时需要，提供 `makensis.exe`）

### 初始化环境

```powershell
python scripts/dev_env.py bootstrap
.\.venv\Scripts\python.exe scripts/dev_env.py doctor
```

`bootstrap` 会创建 `.venv` 并安装 `requirements.txt` 中的依赖。

### 单元测试

```powershell
.\.venv\Scripts\python.exe scripts/dev_env.py test
```

### 发布前检查

```powershell
.\.venv\Scripts\python.exe scripts/dev_env.py release-check --require-update-key
```

发布前检查会验证版本信息、更新源、公钥配置、Python 编译和单元测试。

## Windows 构建

仅验证 PyInstaller 产物：

```powershell
.\.venv\Scripts\python.exe scripts/dev_env.py build --clean --skip-installer
```

生成正式 Windows 安装包：

```powershell
.\.venv\Scripts\python.exe scripts/dev_env.py doctor --build
.\.venv\Scripts\python.exe scripts/dev_env.py build --clean
```

构建产物位于：

- PyInstaller onedir：`dist/windows/pyinstaller/MistRelay`
- 安装器：`dist/windows/mistrelay-v<version>-setup.exe`

## 发布入口

正式发布使用 GitHub Actions：`.github/workflows/build-windows-desktop-qt.yml`。

推送 tag 后自动触发：

```powershell
git tag desktop-qt-v<semver>
git push origin desktop-qt-v<semver>
```

Release 资产包括：

- `mistrelay-v<version>-setup.exe`
- `qt-latest.json`
- `qt-latest.json.sig`
- `qt-patch-<from>-to-<to>.zip`（有上一版本 tag 且配置签名私钥时生成）

需要配置的 GitHub Secrets：

- `QT_UPDATE_PRIVATE_KEY`
- `QT_UPDATE_VERIFY_KEY`

## 相关文档

- 更新发布与排障：[`docs/更新文档.md`](docs/更新文档.md)
- 后端 API：[`backend-api.md`](backend-api.md)
