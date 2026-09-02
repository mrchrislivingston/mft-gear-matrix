from __future__ import annotations

import sqlite3
import subprocess
import sys
import tempfile
import unittest
from pathlib import Path

import benchmark_reclassifier


SCRIPT_PATH = Path(__file__).with_name("benchmark_reclassifier.py")


class BenchmarkReclassifierTests(unittest.TestCase):
    def setUp(self) -> None:
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.database_path = (
            Path(self.temporary_directory.name) / "mft_gear_matrix.db"
        )
        self._create_database()

    def tearDown(self) -> None:
        self.temporary_directory.cleanup()

    def _create_database(self) -> None:
        connection = sqlite3.connect(self.database_path)
        connection.execute("PRAGMA foreign_keys = ON")

        try:
            connection.executescript(
                """
                CREATE TABLE workouts (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    prescription_id TEXT NOT NULL,
                    modality TEXT NOT NULL,
                    workout_date TEXT NOT NULL,
                    source_workbook TEXT NOT NULL DEFAULT '',
                    program_day TEXT NOT NULL DEFAULT ''
                );

                CREATE TABLE workout_intervals (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    workout_id INTEGER NOT NULL,
                    interval_number INTEGER NOT NULL,
                    FOREIGN KEY (workout_id)
                        REFERENCES workouts (id)
                        ON DELETE CASCADE
                );

                CREATE TABLE interval_metrics (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    interval_id INTEGER NOT NULL,
                    metric TEXT NOT NULL,
                    value TEXT NOT NULL,
                    FOREIGN KEY (interval_id)
                        REFERENCES workout_intervals (id)
                        ON DELETE CASCADE
                );

                CREATE TABLE benchmarks (
                    id TEXT PRIMARY KEY,
                    name TEXT NOT NULL,
                    description TEXT NOT NULL DEFAULT '',
                    score_type TEXT NOT NULL
                );

                CREATE TABLE benchmark_attempts (
                    id INTEGER PRIMARY KEY AUTOINCREMENT,
                    benchmark_id TEXT NOT NULL,
                    attempt_date TEXT NOT NULL,
                    score TEXT NOT NULL,
                    source_workbook TEXT NOT NULL DEFAULT '',
                    program_day TEXT NOT NULL DEFAULT '',
                    details TEXT NOT NULL DEFAULT '',
                    notes TEXT NOT NULL DEFAULT '',
                    FOREIGN KEY (benchmark_id)
                        REFERENCES benchmarks (id)
                        ON DELETE CASCADE
                );
                """
            )

            for item in benchmark_reclassifier.RECLASSIFICATIONS:
                connection.execute(
                    """
                    INSERT INTO benchmarks (
                        id,
                        name,
                        description,
                        score_type
                    )
                    VALUES (?, ?, '', 'test')
                    """,
                    (item.benchmark_id, item.benchmark_id),
                )

                connection.execute(
                    """
                    INSERT INTO benchmark_attempts (
                        benchmark_id,
                        attempt_date,
                        score,
                        source_workbook,
                        program_day,
                        details,
                        notes
                    )
                    VALUES (?, ?, 'test-score', ?, ?, '', '')
                    """,
                    (
                        item.benchmark_id,
                        item.date,
                        item.source_workbook,
                        item.program_day,
                    ),
                )

                cursor = connection.execute(
                    """
                    INSERT INTO workouts (
                        prescription_id,
                        modality,
                        workout_date,
                        source_workbook,
                        program_day
                    )
                    VALUES (?, ?, ?, ?, ?)
                    """,
                    (
                        item.prescription_id,
                        item.modality,
                        item.date,
                        item.source_workbook,
                        item.program_day,
                    ),
                )
                workout_id = cursor.lastrowid

                interval_cursor = connection.execute(
                    """
                    INSERT INTO workout_intervals (
                        workout_id,
                        interval_number
                    )
                    VALUES (?, 1)
                    """,
                    (workout_id,),
                )
                interval_id = interval_cursor.lastrowid

                connection.execute(
                    """
                    INSERT INTO interval_metrics (
                        interval_id,
                        metric,
                        value
                    )
                    VALUES (?, 'test_metric', 'test_value')
                    """,
                    (interval_id,),
                )

            connection.commit()
        finally:
            connection.close()

    def _run_reclassifier(
        self,
        *,
        commit: bool = False,
    ) -> subprocess.CompletedProcess[str]:
        command = [
            sys.executable,
            str(SCRIPT_PATH),
            "--database",
            str(self.database_path),
        ]

        if commit:
            command.append("--commit")

        return subprocess.run(
            command,
            capture_output=True,
            text=True,
        )

    def _row_count(self, table_name: str) -> int:
        connection = sqlite3.connect(self.database_path)
        try:
            row = connection.execute(
                f"SELECT COUNT(*) FROM {table_name}"
            ).fetchone()
            assert row is not None
            return int(row[0])
        finally:
            connection.close()

    def test_dry_run_makes_no_changes(self) -> None:
        result = self._run_reclassifier()

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Ready to reclassify: 2", result.stdout)
        self.assertIn("DRY RUN ONLY", result.stdout)
        self.assertEqual(self._row_count("workouts"), 2)
        self.assertEqual(self._row_count("benchmark_attempts"), 2)

    def test_commit_reclassifies_and_is_idempotent(self) -> None:
        result = self._run_reclassifier(commit=True)

        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("Reclassified: 2", result.stdout)
        self.assertIn("SQLite transaction committed.", result.stdout)

        self.assertEqual(self._row_count("workouts"), 0)
        self.assertEqual(self._row_count("workout_intervals"), 0)
        self.assertEqual(self._row_count("interval_metrics"), 0)
        self.assertEqual(self._row_count("benchmark_attempts"), 2)

        backups = list(
            self.database_path.parent.glob(
                "mft_gear_matrix."
                "before_benchmark_reclassification.*.db"
            )
        )
        self.assertEqual(len(backups), 1)

        second_result = self._run_reclassifier()

        self.assertEqual(
            second_result.returncode,
            0,
            second_result.stderr,
        )
        self.assertIn("Ready to reclassify: 0", second_result.stdout)
        self.assertIn("Already complete:     2", second_result.stdout)


if __name__ == "__main__":
    unittest.main()