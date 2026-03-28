from __future__ import annotations

import contextlib
import io
import os
import tempfile
import time
import unittest
from pathlib import Path

from scripts.enforce_exclusion_zones import run_scan


class ExclusionZoneScanTests(unittest.TestCase):
    def _write_file(self, root: Path, relative_path: str, content: str) -> Path:
        path = root / relative_path
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_text(content, encoding="utf-8")
        return path

    def _touch_old(self, path: Path, age_hours: int = 72) -> None:
        timestamp = time.time() - (age_hours * 3600)
        os.utime(path, (timestamp, timestamp))

    def _capture_run(
        self,
        root: Path,
        spike_stale_hours: int = 48,
        fail_on_stale_spikes: bool = False,
    ) -> tuple[int, str, str]:
        stdout = io.StringIO()
        stderr = io.StringIO()
        with contextlib.redirect_stdout(stdout), contextlib.redirect_stderr(stderr):
            exit_code = run_scan(root, spike_stale_hours, fail_on_stale_spikes)
        return exit_code, stdout.getvalue(), stderr.getvalue()

    def test_clean_tree_passes(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            self._write_file(root, "lib/sample.dart", "void main() {}\n")

            exit_code, stdout, stderr = self._capture_run(root)

            self.assertEqual(exit_code, 0)
            self.assertIn("[OK] No exclusion zone violations detected.", stdout)
            self.assertIn(
                "[OK] No stale Spike Protocol artifacts older than 48 hours detected.",
                stdout,
            )
            self.assertEqual(stderr, "")

    def test_banned_reference_fails(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            banned_term = "legacy_api_" + "folder"
            self._write_file(root, "lib/sample.dart", f"const value = '{banned_term}';\n")

            exit_code, stdout, stderr = self._capture_run(root)

            self.assertEqual(exit_code, 1)
            self.assertIn("Exclusion zone violation detected", stderr)
            self.assertIn("Remove deprecated imports/references", stderr)
            self.assertIn("lib/sample.dart:1:const value", stdout)

    def test_stale_spike_warns_without_fail_flag(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            spike = self._write_file(root, "experimental/spike_notes.txt", "temporary")
            self._touch_old(spike)

            exit_code, stdout, stderr = self._capture_run(root, fail_on_stale_spikes=False)

            self.assertEqual(exit_code, 0)
            self.assertIn("Spike Protocol staleness detected", stdout)
            self.assertIn("experimental/spike_notes.txt", stdout)
            self.assertEqual(stderr, "")

    def test_stale_spike_fails_with_fail_flag(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            spike = self._write_file(root, "experimental/spike_notes.txt", "temporary")
            self._touch_old(spike)

            exit_code, stdout, stderr = self._capture_run(root, fail_on_stale_spikes=True)

            self.assertEqual(exit_code, 1)
            self.assertIn("Spike Protocol staleness detected", stdout)
            self.assertIn("Stale Spike Protocol artifacts found", stderr)


if __name__ == "__main__":
    unittest.main()
