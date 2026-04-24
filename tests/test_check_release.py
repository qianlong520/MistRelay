from __future__ import annotations

import os
import sys
import json
import unittest
import zipfile
from pathlib import Path
from unittest import mock


PROJECT_ROOT = Path(__file__).resolve().parents[1]
if str(PROJECT_ROOT) not in sys.path:
    sys.path.insert(0, str(PROJECT_ROOT))

from scripts import check_release, release_manifest


class CheckReleaseVerifyKeyTests(unittest.TestCase):
    def test_expected_release_feed_points_to_current_repository(self) -> None:
        self.assertEqual(
            check_release.EXPECTED_RELEASE_FEED_URL,
            "https://api.github.com/repos/qianlong520/MistRelay/releases?per_page=100",
        )

    def test_resolve_verify_key_uses_version_payload_when_env_is_missing(self) -> None:
        with mock.patch.dict(os.environ, {}, clear=True):
            self.assertEqual(
                check_release.resolve_verify_key({"verify_key": "repo-public-key"}),
                "repo-public-key",
            )

    def test_resolve_verify_key_prefers_explicit_env_override(self) -> None:
        with mock.patch.dict(
            os.environ,
            {"QT_UPDATE_VERIFY_KEY": "env-public-key"},
            clear=True,
        ):
            self.assertEqual(
                check_release.resolve_verify_key({"verify_key": "repo-public-key"}),
                "env-public-key",
            )

    def test_resolve_verify_key_prefers_mistrelay_env_override(self) -> None:
        with mock.patch.dict(
            os.environ,
            {
                "QT_UPDATE_VERIFY_KEY": "generic-env-public-key",
                "MISTRELAY_QT_UPDATE_VERIFY_KEY": "mistrelay-env-public-key",
            },
            clear=True,
        ):
            self.assertEqual(
                check_release.resolve_verify_key({"verify_key": "repo-public-key"}),
                "mistrelay-env-public-key",
            )

    def test_missing_verify_key_message_mentions_env_and_version_file(self) -> None:
        with mock.patch.dict(os.environ, {}, clear=True):
            self.assertEqual(check_release.resolve_verify_key({"verify_key": ""}), "")
        self.assertIn("MISTRELAY_QT_UPDATE_VERIFY_KEY", check_release.missing_verify_key_message())
        self.assertIn("desktop-qt/version.json", check_release.missing_verify_key_message())


class ReleaseManifestPatchToolTests(unittest.TestCase):
    def test_generate_and_verify_patch_zip(self) -> None:
        from nacl.signing import SigningKey

        signing_key = SigningKey.generate()
        private_key = release_manifest.base64.b64encode(bytes(signing_key)).decode("ascii")
        public_key = release_manifest.base64.b64encode(bytes(signing_key.verify_key)).decode("ascii")
        root = PROJECT_ROOT / "build" / "tmp" / "release-manifest-patch"
        if root.exists():
            import shutil
            shutil.rmtree(root)
        old_dir = root / "old"
        new_dir = root / "new"
        old_file = old_dir / "mistrelay_qt" / "qml" / "Main.qml"
        new_file = new_dir / "mistrelay_qt" / "qml" / "Main.qml"
        old_file.parent.mkdir(parents=True)
        new_file.parent.mkdir(parents=True)
        old_file.write_text("old", encoding="utf-8")
        new_file.write_text("new", encoding="utf-8")
        patch_path = root / "qt-patch-1.0.0-to-1.0.1.zip"

        args = mock.Mock(
            from_version="1.0.0",
            to_version="1.0.1",
            old_dir=old_dir,
            new_dir=new_dir,
            output=patch_path,
            download_url="https://example.invalid/patch.zip",
            private_key=private_key,
        )
        self.assertEqual(release_manifest.generate_patch(args), 0)
        self.assertEqual(
            release_manifest.verify_patch(
                mock.Mock(
                    patch=patch_path,
                    public_key=public_key,
                    from_version="1.0.0",
                    to_version="1.0.1",
                )
            ),
            0,
        )
        with zipfile.ZipFile(patch_path, "r") as archive:
            manifest = json.loads(archive.read("patch-manifest.json").decode("utf-8"))
        self.assertEqual(manifest["files"][0]["path"], "mistrelay_qt/qml/Main.qml")
        self.assertIn("signature", manifest)


if __name__ == "__main__":
    unittest.main()
