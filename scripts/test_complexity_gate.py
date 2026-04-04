from __future__ import annotations

import contextlib
import io
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from scripts.complexity_gate import detect_high_risk_changes, main


class ComplexityGateTests(unittest.TestCase):
    def _capture_main(self, file_list: Path) -> tuple[int, str]:
        stdout = io.StringIO()
        with contextlib.redirect_stdout(stdout):
            with patch(
                "sys.argv",
                ["complexity_gate.py", "--file-list", str(file_list)],
            ):
                exit_code = main()
        return exit_code, stdout.getvalue()

    def test_schema_path_is_high_risk(self) -> None:
        with tempfile.TemporaryDirectory() as tmpdir:
            root = Path(tmpdir)
            file_list = root / "changed.txt"
            file_list.write_text("schemas/policy_snapshot.schema.json\n", encoding="utf-8")

            exit_code, stdout = self._capture_main(file_list)

            self.assertEqual(exit_code, 1)
            self.assertIn("[AUDIT ROUTE] Stop-and-Think (high-risk override).", stdout)
            self.assertIn("schemas/policy_snapshot.schema.json", stdout)

    def test_schema_path_detects_in_helper(self) -> None:
        matches = detect_high_risk_changes(["schemas/policy_snapshot.schema.json"])

        self.assertEqual(matches, ["schemas/policy_snapshot.schema.json"])


if __name__ == "__main__":
    unittest.main()
