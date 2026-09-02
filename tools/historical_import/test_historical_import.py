from __future__ import annotations

import contextlib
import io
import sys
import tempfile
import unittest
from datetime import datetime
from pathlib import Path
from types import SimpleNamespace
from unittest.mock import patch

import historical_import


class HistoricalImportCliTests(unittest.TestCase):
    def test_main_reads_candidates_and_writes_review_csv(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            directory = Path(temporary_directory)
            input_path = directory / "input.csv"
            output_path = directory / "review.csv"
            input_path.write_text("test", encoding="utf-8")

            candidates = [
                SimpleNamespace(
                    import_status=SimpleNamespace(value="READY")
                ),
                SimpleNamespace(
                    import_status=SimpleNamespace(value="READY")
                ),
                SimpleNamespace(
                    import_status=SimpleNamespace(value="SKIP")
                ),
            ]

            arguments = [
                "historical_import.py",
                str(input_path),
                str(output_path),
                "--year",
                "2025",
                "--program-start-date",
                "2025-05-05",
            ]

            output = io.StringIO()

            with (
                patch.object(sys, "argv", arguments),
                patch.object(
                    historical_import,
                    "read_workout_candidates",
                    return_value=candidates,
                ) as read_candidates,
                patch.object(
                    historical_import,
                    "write_review_csv",
                ) as write_review,
                contextlib.redirect_stdout(output),
            ):
                historical_import.main()

            read_candidates.assert_called_once_with(
                input_path=input_path,
                year=2025,
                program_start_date=datetime(2025, 5, 5),
            )
            write_review.assert_called_once_with(
                candidates=candidates,
                output_path=output_path,
            )

            rendered_output = output.getvalue()
            self.assertIn(f"Created: {output_path}", rendered_output)
            self.assertIn("Candidates: 3", rendered_output)
            self.assertIn(
                "Program start date: 2025-05-05",
                rendered_output,
            )
            self.assertIn("READY: 2", rendered_output)
            self.assertIn("SKIP: 1", rendered_output)

    def test_main_rejects_invalid_program_start_date(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            input_path = Path(temporary_directory) / "input.csv"
            output_path = Path(temporary_directory) / "review.csv"
            input_path.write_text("test", encoding="utf-8")

            arguments = [
                "historical_import.py",
                str(input_path),
                str(output_path),
                "--year",
                "2025",
                "--program-start-date",
                "05/05/2025",
            ]

            error_output = io.StringIO()

            with (
                patch.object(sys, "argv", arguments),
                patch.object(
                    historical_import,
                    "read_workout_candidates",
                ) as read_candidates,
                contextlib.redirect_stderr(error_output),
                self.assertRaises(SystemExit) as raised,
            ):
                historical_import.main()

            self.assertEqual(raised.exception.code, 2)
            self.assertIn(
                "--program-start-date must use YYYY-MM-DD format",
                error_output.getvalue(),
            )
            read_candidates.assert_not_called()

    def test_main_rejects_missing_input_file(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            directory = Path(temporary_directory)
            input_path = directory / "missing.csv"
            output_path = directory / "review.csv"

            arguments = [
                "historical_import.py",
                str(input_path),
                str(output_path),
                "--year",
                "2025",
            ]

            error_output = io.StringIO()

            with (
                patch.object(sys, "argv", arguments),
                contextlib.redirect_stderr(error_output),
                self.assertRaises(SystemExit) as raised,
            ):
                historical_import.main()

            self.assertEqual(raised.exception.code, 2)
            self.assertIn(
                "Input file does not exist",
                error_output.getvalue(),
            )


if __name__ == "__main__":
    unittest.main()