from __future__ import annotations

import argparse
import sqlite3
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path


DEFAULT_DATABASE_PATH = (
    Path.home()
    / "Library"
    / "Containers"
    / "com.example.mftGearMatrix"
    / "Data"
    / "Documents"
    / "mft_gear_matrix.db"
)


@dataclass(frozen=True)
class Reclassification:
    benchmark_id: str
    date: str
    prescription_id: str
    modality: str
    source_workbook: str
    program_day: str


RECLASSIFICATIONS = (
    Reclassification(
        benchmark_id="matt_row",
        date="2025-09-22",
        prescription_id="Z2",
        modality="row",
        source_workbook="Chris Livingston - Remote Coaching - Phase 1 2026",
        program_day="W4D1",
    ),
    Reclassification(
        benchmark_id="echo_bike_cube_test",
        date="2025-10-07",
        prescription_id="G6",
        modality="echo",
        source_workbook="Chris Livingston - Remote Coaching - Phase 1 2026",
        program_day="W6D2",
    ),
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Remove Matrix workout rows that have already been imported "
            "as benchmark attempts."
        ),
    )
    parser.add_argument(
        "--database",
        type=Path,
        default=DEFAULT_DATABASE_PATH,
    )
    parser.add_argument(
        "--commit",
        action="store_true",
        help="Commit the reclassification. Default behavior is a dry run.",
    )
    return parser.parse_args()


def validate_database(connection: sqlite3.Connection) -> None:
    required_tables = {
        "workouts",
        "workout_intervals",
        "interval_metrics",
        "benchmarks",
        "benchmark_attempts",
    }

    rows = connection.execute(
        """
        SELECT name
        FROM sqlite_master
        WHERE type = 'table'
        """
    ).fetchall()

    existing_tables = {row[0] for row in rows}
    missing_tables = required_tables - existing_tables

    if missing_tables:
        raise RuntimeError(
            "Database is missing required tables: "
            + ", ".join(sorted(missing_tables))
        )


def find_workout_rows(
    connection: sqlite3.Connection,
    item: Reclassification,
) -> list[sqlite3.Row]:
    return connection.execute(
        """
        SELECT id, prescription_id, modality, workout_date
        FROM workouts
        WHERE prescription_id = ?
          AND modality = ?
          AND substr(workout_date, 1, 10) = ?
          AND source_workbook = ?
          AND program_day = ?
        ORDER BY id
        """,
        (
            item.prescription_id,
            item.modality,
            item.date,
            item.source_workbook,
            item.program_day,
        ),
    ).fetchall()


def find_benchmark_attempt(
    connection: sqlite3.Connection,
    item: Reclassification,
) -> sqlite3.Row | None:
    return connection.execute(
        """
        SELECT id
        FROM benchmark_attempts
        WHERE benchmark_id = ?
          AND substr(attempt_date, 1, 10) = ?
          AND source_workbook = ?
          AND program_day = ?
        LIMIT 1
        """,
        (
            item.benchmark_id,
            item.date,
            item.source_workbook,
            item.program_day,
        ),
    ).fetchone()


def create_backup(
    connection: sqlite3.Connection,
    database_path: Path,
) -> Path:
    timestamp = datetime.now().strftime("%Y%m%d-%H%M%S")
    backup_path = database_path.with_name(
        f"{database_path.stem}."
        f"before_benchmark_reclassification."
        f"{timestamp}{database_path.suffix}"
    )

    backup_connection = sqlite3.connect(backup_path)
    try:
        connection.backup(backup_connection)
    finally:
        backup_connection.close()

    return backup_path


def main() -> None:
    args = parse_args()
    database_path: Path = args.database

    if not database_path.exists():
        raise FileNotFoundError(f"Database not found: {database_path}")

    connection = sqlite3.connect(database_path)
    connection.row_factory = sqlite3.Row

    try:
        connection.execute("PRAGMA foreign_keys = ON")
        validate_database(connection)

        print(f"Database: {database_path}")
        print("Database schema: OK")
        print()

        ready: list[tuple[Reclassification, int]] = []

        for item in RECLASSIFICATIONS:
            attempt = find_benchmark_attempt(connection, item)
            workouts = find_workout_rows(connection, item)

            if attempt is None:
                raise RuntimeError(
                    "Required benchmark attempt is missing: "
                    f"{item.benchmark_id} {item.date} {item.program_day}"
                )

            if len(workouts) > 1:
                raise RuntimeError(
                    "Multiple matching Matrix workouts found: "
                    f"{item.prescription_id} {item.modality} "
                    f"{item.date} {item.program_day}"
                )

            if workouts:
                status = "READY"
                workout_id = int(workouts[0]["id"])
                ready.append((item, workout_id))
            else:
                status = "DONE"
                workout_id = 0

            print(
                f"{status:<5} "
                f"{item.prescription_id:<3} "
                f"{item.modality:<5} "
                f"{item.date} "
                f"{item.program_day:<5} "
                f"-> {item.benchmark_id}"
                + (f" (workout id {workout_id})" if workout_id else "")
            )

        print()
        print(f"Ready to reclassify: {len(ready)}")
        print(f"Already complete:     {len(RECLASSIFICATIONS) - len(ready)}")
        print()

        if not args.commit:
            print("DRY RUN ONLY")
            print("No database changes were made.")
            return

        if not ready:
            print("Nothing to reclassify.")
            print("Database was not changed.")
            return

        backup_path = create_backup(connection, database_path)
        print(f"Backup created: {backup_path}")
        print()

        connection.execute("BEGIN IMMEDIATE")
        try:
            deleted = 0

            for item, expected_workout_id in ready:
                if find_benchmark_attempt(connection, item) is None:
                    raise RuntimeError(
                        "Benchmark attempt disappeared before deletion: "
                        f"{item.benchmark_id} {item.date}"
                    )

                workouts = find_workout_rows(connection, item)
                workout_ids = [int(row["id"]) for row in workouts]

                if workout_ids != [expected_workout_id]:
                    raise RuntimeError(
                        "Matrix workout changed before deletion: "
                        f"{item.prescription_id} {item.date}"
                    )

                cursor = connection.execute(
                    "DELETE FROM workouts WHERE id = ?",
                    (expected_workout_id,),
                )

                if cursor.rowcount != 1:
                    raise RuntimeError(
                        f"Expected to delete workout {expected_workout_id}"
                    )

                deleted += 1

            connection.commit()
        except Exception:
            connection.rollback()
            raise

        print(f"Reclassified: {deleted}")
        print("SQLite transaction committed.")
    finally:
        connection.close()


if __name__ == "__main__":
    main()