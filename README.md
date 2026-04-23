# MistRelay Desktop Qt

`desktop-qt/` 是 MistRelay 的独立 Windows Beta 客户端，基于 `PySide6 + Qt Quick/QML`。
它与现有 `desktop/` Tauri 客户端并行发布，使用独立 tag、安装包和更新清单，不接管现有正式版升级链路。

## 当前能力

- 登录、会话恢复、Dashboard、任务中心、Telegram 网盘、本地下载与预览
- 客户端连接 / 代理 / 下载配置
- 服务端分类配置读取、保存、从 `config.yml` 重新导入
- Rclone 配置文件读取与保存
- Docker 状态、Docker 日志、系统资源、应用日志
- 独立 `qt-latest.json` 更新清单、签名校验、Windows 静默安装更新

## 版本与发布

- 版本源：`version.json`
- 发布 tag：`desktop-qt-v<semver>`
- Release 资产：
  - `mistrelay-desktop-qt-v<version>-setup.exe`
  - `qt-latest.json`
  - `qt-latest.json.sig`

`version.json` 里的 `verify_key` 是 Qt 更新公钥，格式为 `Ed25519 VerifyKey` 原始 32 字节的 base64，推荐直接提交到仓库。
GitHub Actions 使用独立私钥 `QT_UPDATE_PRIVATE_KEY` 生成 `qt-latest.json.sig`，并优先使用 `QT_UPDATE_VERIFY_KEY` 覆盖公钥；如果未设置覆盖值，则回退到 `version.json.verify_key`，必要时再根据私钥推导公钥写入打包产物。
Beta 客户端不会依赖 GitHub 的 `releases/latest/download`，而是通过 `release_feed_url` 从 GitHub Releases API 中筛选 `desktop-qt-v*` 的最新资产。

## 目录结构

- `main.py`: Qt 客户端入口
- `version.json`: Qt 客户端版本与更新通道元数据
- `mistrelay_qt/app.py`: 应用装配、QML 上下文和生命周期
- `mistrelay_qt/services/`: HTTP、WS、更新、本地运行时服务
- `mistrelay_qt/viewmodels/`: 页面状态和命令
- `mistrelay_qt/qml/`: QML 页面、组件和主题
- `scripts/check_release.py`: 本地预发布检查
- `scripts/build_windows.py`: PyInstaller + NSIS Windows 构建入口
- `scripts/release_manifest.py`: 更新清单生成、验签、keygen
- `windows/installer.nsi`: Windows 安装器模板

## 本地开发环境

### 推荐基线

- Windows 10/11 x64
- Python `3.11.x` x64
- `pip`
- 打包安装器时额外需要 `NSIS`（提供 `makensis.exe`）

CI 当前使用 `Python 3.11` 构建 Windows 客户端，建议本地也对齐这个版本，避免 `PySide6` 和 `PyInstaller` 在新版本 Python 上出现兼容差异。

### 一键初始化

```powershell
cd desktop-qt
python scripts/dev_env.py bootstrap
.\.venv\Scripts\python.exe scripts/dev_env.py doctor
```

`bootstrap` 会自动：

- 创建 `desktop-qt/.venv`
- 升级 `pip`
- 安装 `requirements.txt` 中的依赖

`doctor` 会检查：

- Python 版本是否符合推荐基线
- `PySide6`、`httpx`、`websockets`、`PyNaCl`、`PyInstaller` 是否已安装
- `version.json`、应用图标是否齐全
- `makensis` 是否可用

### 隔离本地配置和缓存

客户端默认会读取旧桌面端配置 `%APPDATA%/MistRelay/desktop-client.json`，并迁移到 Qt 独立配置：

- Windows: `%APPDATA%/MistRelay/desktop-client-qt.json`
- Linux/macOS 开发环境: `~/.config/MistRelay/desktop-client-qt.json`

如果你不想污染本机现有配置，开发时可以使用仓库内隔离目录：

```powershell
cd desktop-qt
.\.venv\Scripts\python.exe scripts/dev_env.py run --isolated
```

这会把配置和缓存写到：

- `desktop-qt/.local/config`
- `desktop-qt/.local/cache`

### 本地运行

```powershell
cd desktop-qt
.\.venv\Scripts\python.exe scripts/dev_env.py run
```

也可以手动激活虚拟环境后直接运行：

```powershell
cd desktop-qt
.\.venv\Scripts\Activate.ps1
python main.py
```

## 本地测试与预发布检查

### 单元测试

```powershell
cd desktop-qt
.\.venv\Scripts\python.exe scripts/dev_env.py test
```

### 预发布检查

```powershell
cd desktop-qt
.\.venv\Scripts\python.exe scripts/dev_env.py release-check
```

如果要强制检查更新公钥已配置：

```powershell
.\.venv\Scripts\python.exe scripts/dev_env.py release-check --require-update-key
```

如果要临时指向一个手动托管的更新清单，可以覆盖：

```powershell
$env:MISTRELAY_QT_UPDATE_MANIFEST_URL = "https://example.com/qt-latest.json"
.\.venv\Scripts\python.exe scripts/dev_env.py release-check
```

## Windows 构建

### 仅验证 PyInstaller 产物

```powershell
cd desktop-qt
.\.venv\Scripts\python.exe scripts/dev_env.py build --clean --skip-installer
```

### 生成 Windows 安装包

先确保本机已安装 `NSIS`，并且 `makensis.exe` 能被下面这条命令检测到：

```powershell
cd desktop-qt
.\.venv\Scripts\python.exe scripts/dev_env.py doctor --build
.\.venv\Scripts\python.exe scripts/dev_env.py build --clean
```

该脚本会：

- 用 `PyInstaller` 生成 `onedir` 产物
- 打包 QML、图标和 `version.json`
- 调用 NSIS 生成 Windows 安装包

## 更新密钥

生成一套新的 Qt 更新密钥：

```powershell
cd desktop-qt
python scripts/release_manifest.py keygen --output-dir build/update-keys
```

生成结果：

- `qt-update-private.key`: 放到 GitHub Secret `QT_UPDATE_PRIVATE_KEY`
- `qt-update-public.key`: 推荐把内容写入 `version.json.verify_key`；也可以配置成 GitHub Secret `QT_UPDATE_VERIFY_KEY` 作为覆盖值

## GitHub Actions

工作流文件：`.github/workflows/build-windows-desktop-qt.yml`

需要的 Secrets：

- `QT_UPDATE_PRIVATE_KEY`
- `QT_UPDATE_VERIFY_KEY`（可选，用于覆盖 `version.json.verify_key`）

推送 `desktop-qt-v<semver>` tag 后会自动：

- 同步 `version.json` 版本号
- 解析并注入 Qt 更新公钥
- 运行本地预发布检查
- 构建 Windows 安装包
- 生成并签名 `qt-latest.json`
- 校验清单、签名、安装包 hash 和大小
- 创建 GitHub Release
