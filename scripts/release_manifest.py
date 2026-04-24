from __future__ import annotations

import argparse
import base64
import hashlib
import json
import zipfile
from datetime import datetime, UTC
from pathlib import Path
from typing import Any

from nacl.signing import SigningKey, VerifyKey


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Generate or verify Qt desktop release manifests")
    subparsers = parser.add_subparsers(dest="command", required=True)

    generate = subparsers.add_parser("generate", help="Generate manifest and detached signature")
    generate.add_argument("--version", required=True)
    generate.add_argument("--installer", required=True, type=Path)
    generate.add_argument("--download-url", required=True)
    generate.add_argument("--output", required=True, type=Path)
    generate.add_argument("--signature-output", required=True, type=Path)
    generate.add_argument("--notes", default="")
    generate.add_argument("--private-key", default="")
    generate.add_argument("--patch", type=Path)
    generate.add_argument("--patch-url", default="")
    generate.add_argument("--patch-from-version", default="")

    verify = subparsers.add_parser("verify", help="Verify manifest signature and installer hash")
    verify.add_argument("--manifest", required=True, type=Path)
    verify.add_argument("--signature", required=True, type=Path)
    verify.add_argument("--installer", required=True, type=Path)
    verify.add_argument("--public-key", required=True)
    verify.add_argument("--version", default="")
    verify.add_argument("--download-url", default="")

    generate_patch = subparsers.add_parser("generate-patch", help="Generate a signed file patch zip")
    generate_patch.add_argument("--from-version", required=True)
    generate_patch.add_argument("--to-version", required=True)
    generate_patch.add_argument("--old-dir", required=True, type=Path)
    generate_patch.add_argument("--new-dir", required=True, type=Path)
    generate_patch.add_argument("--output", required=True, type=Path)
    generate_patch.add_argument("--download-url", default="")
    generate_patch.add_argument("--private-key", default="")

    verify_patch = subparsers.add_parser("verify-patch", help="Verify a file patch zip")
    verify_patch.add_argument("--patch", required=True, type=Path)
    verify_patch.add_argument("--public-key", required=True)
    verify_patch.add_argument("--from-version", default="")
    verify_patch.add_argument("--to-version", default="")

    keygen = subparsers.add_parser("keygen", help="Generate an Ed25519 signing keypair")
    keygen.add_argument("--output-dir", required=True, type=Path)

    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if args.command == "generate":
        return generate_manifest(args)
    if args.command == "verify":
        return verify_manifest(args)
    if args.command == "generate-patch":
        return generate_patch(args)
    if args.command == "verify-patch":
        return verify_patch(args)
    return generate_keypair(args)


def generate_manifest(args: argparse.Namespace) -> int:
    private_key = (args.private_key or "").strip()
    if not private_key:
        raise SystemExit("--private-key is required for generate")

    installer_path = args.installer.resolve()
    if not installer_path.exists():
        raise SystemExit(f"installer not found: {installer_path}")

    sha256 = file_sha256(installer_path)
    size = installer_path.stat().st_size
    payload = {
        "version": args.version,
        "notes": args.notes,
        "pub_date": datetime.now(UTC).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "platforms": {
            "windows-x86_64": {
                "url": args.download_url,
                "sha256": sha256,
                "size": size,
            }
        },
    }
    if args.patch and args.patch_url and args.patch_from_version:
        patch_manifest = read_patch_manifest_from_path(args.patch)
        payload["patches"] = {
            "windows-x86_64": {
                "from_version": args.patch_from_version,
                "to_version": args.version,
                "url": args.patch_url,
                "sha256": file_sha256(args.patch),
                "size": args.patch.stat().st_size,
                "signature": str(patch_manifest.get("signature") or ""),
                "requires_restart": bool(patch_manifest.get("requires_restart", False)),
                "reloadable_paths": patch_manifest.get("reloadable_paths") or [],
            }
        }

    manifest_bytes = (json.dumps(payload, indent=2, ensure_ascii=False) + "\n").encode("utf-8")
    args.output.write_bytes(manifest_bytes)

    signing_key = SigningKey(base64.b64decode(private_key))
    signature = signing_key.sign(manifest_bytes).signature
    args.signature_output.write_text(base64.b64encode(signature).decode("ascii") + "\n", encoding="utf-8")

    print(f"Manifest: {args.output}")
    print(f"Signature: {args.signature_output}")
    print(f"SHA256: {sha256}")
    return 0


def verify_manifest(args: argparse.Namespace) -> int:
    manifest_bytes = args.manifest.read_bytes()
    signature_text = args.signature.read_text(encoding="utf-8").strip()
    verify_key = VerifyKey(base64.b64decode(args.public_key.strip()))
    verify_key.verify(manifest_bytes, base64.b64decode(signature_text))

    payload = json.loads(manifest_bytes.decode("utf-8"))
    platform = payload.get("platforms", {}).get("windows-x86_64")
    if not isinstance(platform, dict):
        raise SystemExit("manifest is missing platforms.windows-x86_64")

    if args.version and str(payload.get("version") or "") != args.version:
        raise SystemExit(
            f"manifest version mismatch: expected {args.version}, got {payload.get('version')}"
        )

    if args.download_url and str(platform.get("url") or "") != args.download_url:
        raise SystemExit(
            f"manifest url mismatch: expected {args.download_url}, got {platform.get('url')}"
        )

    actual_sha256 = file_sha256(args.installer)
    if str(platform.get("sha256") or "").lower() != actual_sha256:
        raise SystemExit("manifest sha256 does not match installer")

    actual_size = args.installer.stat().st_size
    if int(platform.get("size") or 0) != actual_size:
        raise SystemExit("manifest size does not match installer")

    print(f"Verified manifest: {args.manifest}")
    return 0


def generate_keypair(args: argparse.Namespace) -> int:
    args.output_dir.mkdir(parents=True, exist_ok=True)
    signing_key = SigningKey.generate()
    verify_key = signing_key.verify_key

    private_key = base64.b64encode(bytes(signing_key)).decode("ascii")
    public_key = base64.b64encode(bytes(verify_key)).decode("ascii")

    (args.output_dir / "qt-update-private.key").write_text(private_key + "\n", encoding="utf-8")
    (args.output_dir / "qt-update-public.key").write_text(public_key + "\n", encoding="utf-8")
    print(f"Private key: {args.output_dir / 'qt-update-private.key'}")
    print(f"Public key: {args.output_dir / 'qt-update-public.key'}")
    return 0


def generate_patch(args: argparse.Namespace) -> int:
    private_key = (args.private_key or "").strip()
    if not private_key:
        raise SystemExit("--private-key is required for generate-patch")

    old_dir = args.old_dir.resolve()
    new_dir = args.new_dir.resolve()
    if not old_dir.is_dir():
        raise SystemExit(f"old dir not found: {old_dir}")
    if not new_dir.is_dir():
        raise SystemExit(f"new dir not found: {new_dir}")

    entries = build_patch_entries(old_dir, new_dir)
    manifest = {
        "format": 1,
        "from_version": args.from_version,
        "to_version": args.to_version,
        "created_at": datetime.now(UTC).strftime("%Y-%m-%dT%H:%M:%SZ"),
        "download_url": args.download_url,
        "requires_restart": any(is_restart_required(entry["path"]) for entry in entries),
        "reloadable_paths": [entry["path"] for entry in entries if is_reloadable_path(entry["path"])],
        "files": entries,
    }
    manifest_bytes = canonical_json(manifest)
    signature = SigningKey(base64.b64decode(private_key)).sign(manifest_bytes).signature
    manifest["signature"] = base64.b64encode(signature).decode("ascii")
    manifest_bytes = canonical_json(manifest)

    args.output.parent.mkdir(parents=True, exist_ok=True)
    with zipfile.ZipFile(args.output, "w", compression=zipfile.ZIP_DEFLATED) as archive:
        archive.writestr("patch-manifest.json", manifest_bytes.decode("utf-8"))
        for entry in entries:
            if entry["action"] == "delete":
                continue
            archive.write(new_dir / entry["path"], f"files/{entry['path']}")

    print(f"Patch: {args.output}")
    print(f"SHA256: {file_sha256(args.output)}")
    return 0


def verify_patch(args: argparse.Namespace) -> int:
    with zipfile.ZipFile(args.patch, "r") as archive:
        manifest = read_patch_manifest(archive)
        verify_patch_manifest_signature(manifest, args.public_key)
        if args.from_version and manifest.get("from_version") != args.from_version:
            raise SystemExit("patch from_version mismatch")
        if args.to_version and manifest.get("to_version") != args.to_version:
            raise SystemExit("patch to_version mismatch")
        for entry in patch_entries(manifest):
            relative_path = entry["path"]
            validate_patch_path(relative_path)
            action = entry["action"]
            if action == "delete":
                continue
            if action not in {"add", "replace"}:
                raise SystemExit(f"unknown patch action: {action}")
            archive_name = f"files/{relative_path}"
            try:
                payload = archive.read(archive_name)
            except KeyError as exc:
                raise SystemExit(f"patch missing file: {archive_name}") from exc
            if hashlib.sha256(payload).hexdigest().lower() != entry["sha256"]:
                raise SystemExit(f"patch file sha256 mismatch: {relative_path}")
            if len(payload) != int(entry.get("size") or 0):
                raise SystemExit(f"patch file size mismatch: {relative_path}")

    print(f"Verified patch: {args.patch}")
    return 0


def build_patch_entries(old_dir: Path, new_dir: Path) -> list[dict[str, Any]]:
    old_files = collect_files(old_dir)
    new_files = collect_files(new_dir)
    entries: list[dict[str, Any]] = []
    for relative_path in sorted(set(old_files) | set(new_files)):
        validate_patch_path(relative_path)
        old_path = old_files.get(relative_path)
        new_path = new_files.get(relative_path)
        if old_path and not new_path:
            entries.append({"path": relative_path, "action": "delete", "sha256": "", "size": 0})
            continue
        if not new_path:
            continue
        digest = file_sha256(new_path)
        if old_path and file_sha256(old_path) == digest:
            continue
        entries.append(
            {
                "path": relative_path,
                "action": "replace" if old_path else "add",
                "sha256": digest,
                "size": new_path.stat().st_size,
            }
        )
    return entries


def collect_files(root: Path) -> dict[str, Path]:
    files: dict[str, Path] = {}
    for path in root.rglob("*"):
        if path.is_file():
            relative_path = path.relative_to(root).as_posix()
            validate_patch_path(relative_path)
            files[relative_path] = path
    return files


def canonical_json(payload: dict[str, Any]) -> bytes:
    return (json.dumps(payload, ensure_ascii=False, sort_keys=True, separators=(",", ":")) + "\n").encode("utf-8")


def read_patch_manifest(archive: zipfile.ZipFile) -> dict[str, Any]:
    try:
        payload = json.loads(archive.read("patch-manifest.json").decode("utf-8"))
    except KeyError as exc:
        raise SystemExit("patch missing patch-manifest.json") from exc
    if not isinstance(payload, dict):
        raise SystemExit("patch manifest must be an object")
    return payload


def read_patch_manifest_from_path(path: Path) -> dict[str, Any]:
    with zipfile.ZipFile(path, "r") as archive:
        return read_patch_manifest(archive)


def verify_patch_manifest_signature(manifest: dict[str, Any], public_key: str) -> None:
    signature = str(manifest.get("signature") or "").strip()
    if not signature:
        raise SystemExit("patch manifest missing signature")
    unsigned = dict(manifest)
    unsigned.pop("signature", None)
    VerifyKey(base64.b64decode(public_key.strip())).verify(canonical_json(unsigned), base64.b64decode(signature))


def patch_entries(manifest: dict[str, Any]) -> list[dict[str, Any]]:
    files = manifest.get("files")
    if not isinstance(files, list):
        raise SystemExit("patch manifest files must be a list")
    entries: list[dict[str, Any]] = []
    for item in files:
        if not isinstance(item, dict):
            raise SystemExit("patch file entry must be an object")
        entries.append(item)
    return entries


def validate_patch_path(relative_path: str) -> None:
    candidate = Path(relative_path)
    if not relative_path or candidate.is_absolute() or ".." in candidate.parts or "\\" in relative_path:
        raise SystemExit(f"unsafe patch path: {relative_path}")


def is_reloadable_path(relative_path: str) -> bool:
    lowered = relative_path.lower()
    return lowered.endswith(('.qml', '.png', '.jpg', '.jpeg', '.svg', '.json')) and not is_restart_required(relative_path)


def is_restart_required(relative_path: str) -> bool:
    lowered = relative_path.lower()
    return lowered.endswith(('.exe', '.dll', '.pyd', '.zip')) or lowered.startswith('python')


def file_sha256(path: Path) -> str:
    digest = hashlib.sha256()
    with path.open("rb") as handle:
        while True:
            chunk = handle.read(1024 * 256)
            if not chunk:
                break
            digest.update(chunk)
    return digest.hexdigest().lower()


if __name__ == "__main__":
    raise SystemExit(main())
