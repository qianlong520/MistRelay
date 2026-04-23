from __future__ import annotations

import argparse
import importlib.util
import os
import shutil
import subprocess
import sys
from pathlib import Path


MIN_PYTHON = (3, 11)
RECOMMENDED_PYTHON = (3, 11)
REQUIRED_MODULES = ("PySide6", "httpx", "websockets", "nacl", "PyInstaller")


def desktop_qt_root() -> Path:
    return Path(__file__).resolve().parents[1]


def venv_dir() -> Path:
    return desktop_qt_root() / ".venv"


def venv_python() -> Path:
    if os.name == "nt":
        return venv_dir() / "Scripts" / "python.exe"
    return venv_dir() / "bin" / "python"


def temp_root() -> Path:
    return desktop_qt_root() / ".local" / "tmp"


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Local development helper for desktop-qt")
    subparsers = parser.add_subparsers(dest="command", required=True)

    bootstrap = subparsers.add_parser("bootstrap", help="Create .venv and install dependencies")
    bootstrap.add_argument(
        "--python",
        default=sys.executable,
        help="Python executable used to create .venv (default: current interpreter)",
    )

    doctor = subparsers.add_parser("doctor", help="Check local development prerequisites")
    doctor.add_argument(
        "--build",
        action="store_true",
        help="Require NSIS packaging prerequisites in addition to runtime dependencies",
    )

    run = subparsers.add_parser("run", help="Run the desktop-qt client")
    run.add_argument("--isolated", action="store_true", help="Use repo-local config/cache directories")

    test = subparsers.add_parser("test", help="Run desktop-qt unit tests")
    test.add_argument("--isolated", action="store_true", help="Use repo-local config/cache directories")

    release_check = subparsers.add_parser("release-check", help="Run local pre-release checks")
    release_check.add_argument("--isolated", action="store_true", help="Use repo-local config/cache directories")
    release_check.add_argument("--require-update-key", action="store_true")

    build = subparsers.add_parser("build", help="Build the Windows package")
    build.add_argument("--isolated", action="store_true", help="Use repo-local config/cache directories")
    build.add_argument("--clean", action="store_true")
    build.add_argument("--skip-installer", action="store_true")

    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.command == "bootstrap":
        return bootstrap(args)
    if args.command == "doctor":
        return doctor(args)
    if args.command == "run":
        return run_client(args)
    if args.command == "test":
        return run_tests(args)
    if args.command == "release-check":
        return run_release_checks(args)
    if args.command == "build":
        return build_windows(args)
    raise SystemExit(f"unsupported command: {args.command}")


def bootstrap(args: argparse.Namespace) -> int:
    root = desktop_qt_root()
    python_executable = args.python
    venv_path = venv_python()

    if not venv_is_healthy():
        venv_path.parent.mkdir(parents=True, exist_ok=True)
        run_command([python_executable, "-m", "venv", "--clear", str(venv_dir())], cwd=root)

    python_cmd = str(venv_path)
    run_command([python_cmd, "-m", "pip", "install", "--upgrade", "pip"], cwd=root)
    run_command([python_cmd, "-m", "pip", "install", "-r", "requirements.txt"], cwd=root)

    print()
    print(f"Environment ready: {venv_path}")
    print(f"Next: {python_cmd} scripts/dev_env.py doctor")
    return 0


def doctor(args: argparse.Namespace) -> int:
    exit_code = 0
    version = sys.version_info[:3]
    if version[:2] < MIN_PYTHON:
        print_status(
            "FAIL",
            "python",
            f"{sys.executable} -> {version[0]}.{version[1]}.{version[2]} (need >= {MIN_PYTHON[0]}.{MIN_PYTHON[1]})",
        )
        exit_code = 1
    elif version[:2] != RECOMMENDED_PYTHON:
        print_status(
            "WARN",
            "python",
            f"{sys.executable} -> {version[0]}.{version[1]}.{version[2]} (CI uses {RECOMMENDED_PYTHON[0]}.{RECOMMENDED_PYTHON[1]})",
        )
    else:
        print_status("OK", "python", f"{sys.executable} -> {version[0]}.{version[1]}.{version[2]}")

    current_venv = os.environ.get("VIRTUAL_ENV", "")
    current_python = Path(sys.executable).resolve()
    expected_venv_python = venv_python().resolve() if venv_python().exists() else None
    if expected_venv_python and current_python == expected_venv_python:
        print_status("OK", "venv", str(venv_dir()))
    elif current_venv:
        print_status("OK", "venv", current_venv)
    elif venv_python().exists():
        print_status("WARN", "venv", f".venv exists but current interpreter is outside it: {venv_python()}")
    else:
        print_status("WARN", "venv", "no .venv found yet, run: python scripts/dev_env.py bootstrap")

    for module_name in REQUIRED_MODULES:
        if importlib.util.find_spec(module_name):
            print_status("OK", f"module:{module_name}", "installed")
        else:
            print_status("FAIL", f"module:{module_name}", "missing")
            exit_code = 1

    version_path = desktop_qt_root() / "version.json"
    if version_path.exists():
        print_status("OK", "version.json", str(version_path))
    else:
        print_status("FAIL", "version.json", f"missing: {version_path}")
        exit_code = 1

    icon_path = desktop_qt_root().parent / "desktop" / "icons" / "icon.ico"
    if icon_path.exists():
        print_status("OK", "icon.ico", str(icon_path))
    else:
        print_status("FAIL", "icon.ico", f"missing: {icon_path}")
        exit_code = 1

    makensis = find_makensis()
    if makensis:
        print_status("OK", "makensis", makensis)
    elif args.build:
        print_status("FAIL", "makensis", "missing (required for installer packaging)")
        exit_code = 1
    else:
        print_status("WARN", "makensis", "missing (needed only for installer packaging)")

    return exit_code


def run_client(args: argparse.Namespace) -> int:
    return run_python_command(["main.py"], isolated=args.isolated)


def run_tests(args: argparse.Namespace) -> int:
    env = build_env(isolated=args.isolated)
    env.setdefault("QT_QPA_PLATFORM", "offscreen")
    return run_command(
        [str(python_for_commands()), "-m", "unittest", "discover", "-s", "tests", "-v"],
        cwd=desktop_qt_root(),
        env=env,
    )


def run_release_checks(args: argparse.Namespace) -> int:
    command = [str(python_for_commands()), "scripts/check_release.py"]
    if args.require_update_key:
        command.append("--require-update-key")
    return run_command(command, cwd=desktop_qt_root(), env=build_env(isolated=args.isolated))


def build_windows(args: argparse.Namespace) -> int:
    if not args.skip_installer and not find_makensis():
        raise SystemExit("makensis not found. Install NSIS first or use --skip-installer.")

    command = [str(python_for_commands()), "scripts/build_windows.py"]
    if args.clean:
        command.append("--clean")
    if args.skip_installer:
        command.append("--skip-installer")
    return run_command(command, cwd=desktop_qt_root(), env=build_env(isolated=args.isolated))


def python_for_commands() -> Path:
    candidate = venv_python()
    if venv_is_healthy():
        return candidate
    return Path(sys.executable)


def build_env(*, isolated: bool) -> dict[str, str]:
    env = os.environ.copy()
    temp_dir = temp_root()
    temp_dir.mkdir(parents=True, exist_ok=True)
    env.setdefault("TMP", str(temp_dir))
    env.setdefault("TEMP", str(temp_dir))
    env.setdefault("TMPDIR", str(temp_dir))
    if isolated:
        local_root = desktop_qt_root() / ".local"
        config_root = local_root / "config"
        cache_root = local_root / "cache"
        config_root.mkdir(parents=True, exist_ok=True)
        cache_root.mkdir(parents=True, exist_ok=True)
        env.setdefault("MISTRELAY_CONFIG_HOME", str(config_root))
        env.setdefault("MISTRELAY_CACHE_HOME", str(cache_root))
    return env


def find_makensis() -> str:
    candidates = [
        "makensis",
        r"C:\Program Files (x86)\NSIS\makensis.exe",
        r"C:\Program Files\NSIS\makensis.exe",
    ]
    for candidate in candidates:
        if Path(candidate).name == candidate:
            resolved = shutil.which(candidate)
            if resolved:
                return resolved
            continue
        if Path(candidate).exists():
            return candidate
    return ""


def venv_is_healthy() -> bool:
    python_executable = venv_python()
    if not python_executable.exists():
        return False
    completed = subprocess.run(
        [str(python_executable), "-m", "pip", "--version"],
        cwd=desktop_qt_root(),
        env=build_env(isolated=False),
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        check=False,
    )
    return completed.returncode == 0


def run_python_command(args: list[str], *, isolated: bool) -> int:
    command = [str(python_for_commands()), *args]
    return run_command(command, cwd=desktop_qt_root(), env=build_env(isolated=isolated))


def run_command(command: list[str], *, cwd: Path, env: dict[str, str] | None = None) -> int:
    print(f"$ {format_command(command)}")
    command_env = build_env(isolated=False)
    if env:
        command_env.update(env)
    completed = subprocess.run(command, cwd=cwd, env=command_env, check=False)
    if completed.returncode != 0:
        raise SystemExit(completed.returncode)
    return completed.returncode


def format_command(command: list[str]) -> str:
    if os.name == "nt":
        return subprocess.list2cmdline(command)
    return " ".join(command)


def print_status(status: str, label: str, message: str) -> None:
    print(f"[{status:<4}] {label}: {message}")


if __name__ == "__main__":
    raise SystemExit(main())
