from __future__ import annotations

import sqlite3
import unittest
from dataclasses import replace

import benchmark_importer
from benchmark_models import NormalizedBenchmarkAttempt


class BenchmarkImporterTests(unittest.TestCase):
    def setUp(self) -> None:
        self.connection = sqlite3.connect(":memory:")
        self.connection.execute(
            """
            CREATE TABLE benchmarks (
                id TEXT PRIMARY KEY,
                name TEXT NOT NULL,
                description TEXT NOT NULL DEFAULT '',
                score_type TEXT NOT NULL
            )
            """
        )
        self.connection.execute(
            """
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
            )
            """
        )

        for benchmark_id in {
            attempt.benchmark_id
            for attempt in benchmark_importer.configured_attempts()
        }:
            self.connection.execute(
                """
                INSERT INTO benchmarks (
                    id,
                    name,
                    description,
                    score_type
                )
                VALUES (?, ?, '', 'test')
                """,
                (benchmark_id, benchmark_id),
            )

        self.connection.commit()

    def tearDown(self) -> None:
        self.connection.close()

    def test_configured_attempts_contains_expected_history(self) -> None:
        attempts = benchmark_importer.configured_attempts()

        self.assertEqual(len(attempts), 8)

        matt = next(
            attempt
            for attempt in attempts
            if attempt.benchmark_id == "matt_row"
            and attempt.date == "2025-09-22"
        )
        self.assertEqual(matt.score, "183")
        self.assertEqual(matt.program_day, "W4D1")
        self.assertIn("2:04", matt.details)
        self.assertIn("930", matt.details)

        cube = next(
            attempt
            for attempt in attempts
            if attempt.benchmark_id == "echo_bike_cube_test"
            and attempt.date == "2025-10-07"
        )
        self.assertEqual(cube.score, "316")
        self.assertEqual(cube.program_day, "W6D2")
        self.assertIn("Round 4 - 83 cal", cube.details)

    def test_insert_detect_update_lifecycle(self) -> None:
        attempt = benchmark_importer.configured_attempts()[0]

        self.assertTrue(
            benchmark_importer.benchmark_exists(
                self.connection,
                attempt.benchmark_id,
            )
        )
        self.assertFalse(
            benchmark_importer.attempt_exists(
                self.connection,
                attempt,
            )
        )

        attempt_id = benchmark_importer.insert_attempt(
            self.connection,
            attempt,
        )

        self.assertGreater(attempt_id, 0)
        self.assertTrue(
            benchmark_importer.attempt_exists(
                self.connection,
                attempt,
            )
        )
        self.assertFalse(
            benchmark_importer.attempt_needs_update(
                self.connection,
                attempt,
            )
        )

        changed_attempt = replace(
            attempt,
            score="999",
            details="Updated details",
            notes="Updated notes",
        )

        self.assertTrue(
            benchmark_importer.attempt_needs_update(
                self.connection,
                changed_attempt,
            )
        )

        benchmark_importer.update_attempt(
            self.connection,
            changed_attempt,
        )

        self.assertFalse(
            benchmark_importer.attempt_needs_update(
                self.connection,
                changed_attempt,
            )
        )

        row = self.connection.execute(
            """
            SELECT score, details, notes
            FROM benchmark_attempts
            WHERE id = ?
            """,
            (attempt_id,),
        ).fetchone()

        self.assertEqual(
            row,
            ("999", "Updated details", "Updated notes"),
        )

    def test_normalized_attempt_defaults(self) -> None:
        attempt = NormalizedBenchmarkAttempt(
            benchmark_id="test",
            date="2026-01-01",
            score="100",
            source_workbook="Workbook",
            program_day="W1D1",
        )

        self.assertEqual(attempt.details, "")
        self.assertEqual(attempt.notes, "")

    def test_validate_database_rejects_missing_tables(self) -> None:
        incomplete = sqlite3.connect(":memory:")
        try:
            incomplete.execute(
                "CREATE TABLE benchmarks (id TEXT PRIMARY KEY)"
            )

            with self.assertRaisesRegex(
                RuntimeError,
                "benchmark_attempts",
            ):
                benchmark_importer.validate_database(incomplete)
        finally:
            incomplete.close()


if __name__ == "__main__":
    unittest.main()