from __future__ import annotations

import sqlite3
import unittest

import sqlite_importer
from normalized_models import (
    ExecutionPlan,
    NormalizedInterval,
    NormalizedWorkout,
)


class SqliteImporterTests(unittest.TestCase):
    def setUp(self) -> None:
        self.connection = sqlite3.connect(":memory:")
        self.connection.execute("PRAGMA foreign_keys = ON")
        self.connection.executescript(
            """
            CREATE TABLE workouts (
                id INTEGER PRIMARY KEY AUTOINCREMENT,
                prescription_id TEXT NOT NULL,
                modality TEXT NOT NULL,
                workout_date TEXT NOT NULL,
                source_workbook TEXT NOT NULL DEFAULT '',
                program_day TEXT NOT NULL DEFAULT '',
                duration TEXT NOT NULL DEFAULT '',
                work_duration TEXT NOT NULL DEFAULT '',
                interval_count INTEGER NOT NULL DEFAULT 0,
                scoring_metric TEXT,
                notes TEXT NOT NULL DEFAULT ''
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
            """
        )

    def tearDown(self) -> None:
        self.connection.close()

    def _workout(
        self,
        *,
        source_workbook: str = "Test Workbook",
        program_day: str = "W1D1",
    ) -> NormalizedWorkout:
        return NormalizedWorkout(
            source_id="test-source",
            source_workbook=source_workbook,
            program_day=program_day,
            prescription_id="G5",
            modality="row",
            date="2026-01-15",
            execution_plan=ExecutionPlan(
                work_duration="3:30",
                interval_count=2,
            ),
            duration="",
            notes="Test notes",
            intervals=(
                NormalizedInterval(
                    interval_number=1,
                    values={
                        "distance": "1000",
                        "watts": "250",
                    },
                ),
                NormalizedInterval(
                    interval_number=2,
                    values={
                        "distance": "1025",
                        "watts": "255",
                    },
                ),
            ),
        )

    def test_validate_database_accepts_current_schema(self) -> None:
        sqlite_importer.validate_database(self.connection)

    def test_validate_database_rejects_missing_columns(self) -> None:
        incomplete = sqlite3.connect(":memory:")
        try:
            incomplete.executescript(
                """
                CREATE TABLE workouts (
                    id INTEGER PRIMARY KEY
                );

                CREATE TABLE workout_intervals (
                    id INTEGER PRIMARY KEY
                );

                CREATE TABLE interval_metrics (
                    id INTEGER PRIMARY KEY
                );
                """
            )

            with self.assertRaisesRegex(
                RuntimeError,
                "workouts table is missing required columns",
            ):
                sqlite_importer.validate_database(incomplete)
        finally:
            incomplete.close()

    def test_insert_workout_persists_parent_intervals_and_metrics(
        self,
    ) -> None:
        workout = self._workout()

        self.assertFalse(
            sqlite_importer.workout_exists(
                self.connection,
                workout,
            )
        )

        workout_id = sqlite_importer.insert_workout(
            self.connection,
            workout,
        )
        self.connection.commit()

        self.assertGreater(workout_id, 0)
        self.assertTrue(
            sqlite_importer.workout_exists(
                self.connection,
                workout,
            )
        )

        workout_row = self.connection.execute(
            """
            SELECT
                prescription_id,
                modality,
                workout_date,
                source_workbook,
                program_day,
                duration,
                work_duration,
                interval_count,
                scoring_metric,
                notes
            FROM workouts
            WHERE id = ?
            """,
            (workout_id,),
        ).fetchone()

        self.assertEqual(
            workout_row,
            (
                "G5",
                "row",
                "2026-01-15",
                "Test Workbook",
                "W1D1",
                "",
                "3:30",
                2,
                None,
                "Test notes",
            ),
        )

        interval_rows = self.connection.execute(
            """
            SELECT id, interval_number
            FROM workout_intervals
            WHERE workout_id = ?
            ORDER BY interval_number
            """,
            (workout_id,),
        ).fetchall()

        self.assertEqual(
            [row[1] for row in interval_rows],
            [1, 2],
        )

        metric_rows = self.connection.execute(
            """
            SELECT wi.interval_number, im.metric, im.value
            FROM interval_metrics AS im
            JOIN workout_intervals AS wi
              ON wi.id = im.interval_id
            WHERE wi.workout_id = ?
            ORDER BY wi.interval_number, im.metric
            """,
            (workout_id,),
        ).fetchall()

        self.assertEqual(
            metric_rows,
            [
                (1, "distance", "1000"),
                (1, "watts", "250"),
                (2, "distance", "1025"),
                (2, "watts", "255"),
            ],
        )

    def test_duplicate_identity_includes_execution_plan(self) -> None:
        workout = self._workout()
        sqlite_importer.insert_workout(self.connection, workout)

        changed_plan = NormalizedWorkout(
            source_id=workout.source_id,
            source_workbook=workout.source_workbook,
            program_day=workout.program_day,
            prescription_id=workout.prescription_id,
            modality=workout.modality,
            date=workout.date,
            execution_plan=ExecutionPlan(
                work_duration="4:00",
                interval_count=2,
            ),
            duration=workout.duration,
            notes=workout.notes,
            intervals=workout.intervals,
        )

        self.assertTrue(
            sqlite_importer.workout_exists(
                self.connection,
                workout,
            )
        )
        self.assertFalse(
            sqlite_importer.workout_exists(
                self.connection,
                changed_plan,
            )
        )

    def test_validate_provenance_rejects_missing_values(self) -> None:
        missing_workbook = self._workout(source_workbook=" ")
        missing_program_day = self._workout(program_day="")

        with self.assertRaisesRegex(
            RuntimeError,
            "source_workbook",
        ):
            sqlite_importer.validate_provenance(
                [missing_workbook]
            )

        with self.assertRaisesRegex(
            RuntimeError,
            "program_day",
        ):
            sqlite_importer.validate_provenance(
                [missing_program_day]
            )

    def test_validate_provenance_accepts_complete_values(self) -> None:
        sqlite_importer.validate_provenance([self._workout()])


if __name__ == "__main__":
    unittest.main()