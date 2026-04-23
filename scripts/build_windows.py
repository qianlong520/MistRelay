from __future__ import annotations

import argparse
import shutil
import subprocess
import sys
from pathlib import Path


def desktop_qt_root() -> Path:
    script_root = Path(__file__).resolve().parents[1]
    if (script_root / "version.json").exists() and (script_root / "main.py").exists():
        return script_root
    return script_root.parent / "desktop-qt"


def repo_root() -> Path:
    qt_root = desktop_qt_root()
    if (qt_root / "desktop").exists():
        return qt_root
    return qt_root.parent


def load_version() -> str:
    import json

    payload = json.loads((desktop_qt_root() / "version.json").read_text(encoding="utf-8"))
    return str(payload.get("version") or "0.0.0-dev")


def load_product_name() -> str:
    import json

    payload = json.loads((desktop_qt_root() / "version.json").read_text(encoding="utf-8"))
    return str(payload.get("product_name") or "MistRelay")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Build MistRelay for Windows")
    parser.add_argument("--skip-installer", action="store_true", help="Only run PyInstaller")
    parser.add_argument("--clean", action="store_true", help="Remove existing build/dist output first")
    return parser.parse_args()


def ensure_update_signature_runtime(portable_dir: Path) -> None:
    runtime_root = portable_dir / "_internal" if (portable_dir / "_internal").exists() else portable_dir

    if not (runtime_root / "nacl").exists():
        raise SystemExit("PyInstaller output missing nacl package required for update signature verification.")
    if not (runtime_root / "cffi").exists():
        raise SystemExit("PyInstaller output missing cffi package required for update signature verification.")
    if not (runtime_root / "pycparser").exists():
        raise SystemExit("PyInstaller output missing pycparser package required for update signature verification.")
    if not any(path.is_file() and path.name.startswith("_cffi_backend") for path in runtime_root.rglob("*")):
        raise SystemExit("PyInstaller output missing _cffi_backend required for update signature verification.")
    if not any(
        path.is_file() and (path.name.startswith("_sodium") or "libsodium" in path.name.lower())
        for path in runtime_root.rglob("*")
    ):
        raise SystemExit("PyInstaller output missing PyNaCl sodium runtime required for update signature verification.")


def ensure_installer_assets(qt_root: Path, icon_png: Path, product_name: str) -> tuple[Path, Path]:
    assets_dir = qt_root / "windows" / "assets"
    welcome_bitmap = assets_dir / "installer-welcome.bmp"
    header_bitmap = assets_dir / "installer-header.bmp"

    if not icon_png.exists():
        raise SystemExit(f"missing icon: {icon_png}")

    icon_mtime = icon_png.stat().st_mtime
    should_generate = (
        not welcome_bitmap.exists()
        or not header_bitmap.exists()
        or welcome_bitmap.stat().st_mtime < icon_mtime
        or header_bitmap.stat().st_mtime < icon_mtime
    )
    if should_generate:
        generator = qt_root / "scripts" / "generate_installer_assets.py"
        command = [
            sys.executable,
            str(generator),
            "--icon",
            str(icon_png),
            "--output-dir",
            str(assets_dir),
            "--product-name",
            product_name,
        ]
        print("Running:", " ".join(command))
        subprocess.run(command, cwd=qt_root, check=True)

    if not welcome_bitmap.exists() or not header_bitmap.exists():
        raise SystemExit("installer artwork generation did not produce the expected bitmap assets.")
    return welcome_bitmap, header_bitmap


def main() -> int:
    args = parse_args()
    version = load_version()
    product_name = load_product_name()
    qt_root = desktop_qt_root()
    build_root = qt_root / "build" / "windows"
    dist_root = qt_root / "dist" / "windows"
    icon_path = repo_root() / "desktop" / "icons" / "icon.ico"
    icon_png = repo_root() / "desktop" / "icons" / "icon.png"
    qml_path = qt_root / "mistrelay_qt" / "qml"
    version_path = qt_root / "version.json"
    desktop_icons = repo_root() / "desktop" / "icons"

    if not icon_path.exists():
        raise SystemExit(f"missing icon: {icon_path}")

    if args.clean:
        shutil.rmtree(build_root, ignore_errors=True)
        shutil.rmtree(dist_root, ignore_errors=True)

    build_root.mkdir(parents=True, exist_ok=True)
    dist_root.mkdir(parents=True, exist_ok=True)

    separator = ";" if sys.platform.startswith("win") else ":"
    pyinstaller_dist = dist_root / "pyinstaller"
    pyinstaller_build = build_root / "pyinstaller"
    portable_name = product_name

    command = [
        sys.executable,
        "-m",
        "PyInstaller",
        "--noconfirm",
        "--clean",
        "--windowed",
        "--onedir",
        "--name",
        portable_name,
        "--icon",
        str(icon_path),
        "--distpath",
        str(pyinstaller_dist),
        "--workpath",
        str(pyinstaller_build),
        "--specpath",
        str(pyinstaller_build),
        "--collect-all",
        "PySide6",
        "--copy-metadata",
        "PySide6",
        "--copy-metadata",
        "httpx",
        "--copy-metadata",
        "httpcore",
        "--copy-metadata",
        "websockets",
        "--copy-metadata",
        "PyNaCl",
        "--collect-all",
        "nacl",
        "--collect-all",
        "cffi",
        "--collect-all",
        "pycparser",
        "--hidden-import",
        "_cffi_backend",
        "--hidden-import",
        "socksio",
        "--hidden-import",
        "httpcore._sync.socks_proxy",
        "--hidden-import",
        "httpcore._async.socks_proxy",
        "--hidden-import",
        "PySide6.QtQuickControls2",
        "--hidden-import",
        "PySide6.QtMultimedia",
        "--add-data",
        f"{qml_path}{separator}mistrelay_qt/qml",
        "--add-data",
        f"{desktop_icons}{separator}desktop/icons",
        "--add-data",
        f"{version_path}{separator}.",
        str(qt_root / "main.py"),
    ]

    print("Running:", " ".join(command))
    subprocess.run(command, cwd=qt_root, check=True)

    portable_dir = pyinstaller_dist / portable_name
    if not portable_dir.exists():
        raise SystemExit(f"PyInstaller output missing: {portable_dir}")
    ensure_update_signature_runtime(portable_dir)

    if args.skip_installer:
        print(f"PyInstaller output: {portable_dir}")
        return 0

    welcome_bitmap, header_bitmap = ensure_installer_assets(qt_root, icon_png, product_name)
    installer_output = dist_root / f"mistrelay-v{version}-setup.exe"
    makensis = find_makensis()
    nsis_script = qt_root / "windows" / "installer.nsi"

    nsis_command = [
        makensis,
        f"/DAPP_NAME={product_name}",
        f"/DAPP_VERSION={version}",
        f"/DMAIN_EXE={product_name}.exe",
        f"/DSOURCE_DIR={portable_dir}",
        f"/DOUTPUT_FILE={installer_output}",
        f"/DINSTALL_DIR_NAME={product_name}",
        f"/DINSTALLER_ICON={icon_path}",
        f"/DINSTALLER_WELCOME_BITMAP={welcome_bitmap}",
        f"/DINSTALLER_HEADER_BITMAP={header_bitmap}",
        "/DFINISH_RUN_ENABLED=1",
        str(nsis_script),
    ]
    print("Running:", " ".join(str(part) for part in nsis_command))
    subprocess.run(nsis_command, cwd=qt_root, check=True)

    print(f"Installer: {installer_output}")
    return 0


def find_makensis() -> str:
    candidates = [
        "makensis",
        r"C:\Program Files (x86)\NSIS\makensis.exe",
        r"C:\Program Files\NSIS\makensis.exe",
    ]
    for candidate in candidates:
        resolved = shutil.which(candidate) if Path(candidate).name == candidate else candidate
        if resolved and Path(resolved).exists():
            return str(resolved)
    raise SystemExit("NSIS makensis was not found. Install NSIS or set it on PATH.")


if __name__ == "__main__":
    raise SystemExit(main())
