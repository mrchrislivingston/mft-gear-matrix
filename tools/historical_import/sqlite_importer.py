from __future__ import annotations

import argparse
import shutil
import sqlite3
from pathlib import Path

from normalized_models import NormalizedWorkout
from normalizer import normalize_candidate
from review_reader import read_reviewed_candidates


DEFAULT_REVIEW_PATH = Path("review/offszn1_review_v3.csv")

DEFAULT_DATABASE_PATH = (
    Path.home()
    / "Library"
    / "Containers"
    / "com.example.mftGearMatrix"
    / "Data"
    / "Documents"
    / "mft_gear_matrix.db"
)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description=(
            "Import normalized historical workouts into the "
            "MFT Gear Matrix SQLite database."
        ),
    )

    parser.add_argument(
        "--review",
        type=Path,
        default=DEFAULT_REVIEW_PATH,
        help=(
            "Path to the reviewed historical-import CSV. "
            f"Default: {DEFAULT_REVIEW_PATH}"
        ),
    )

    parser.add_argument(
        "--database",
        type=Path,
        default=DEFAULT_DATABASE_PATH,
        help=(
            "Path to the MFT Gear Matrix SQLite database. "
            f"Default: {DEFAULT_DATABASE_PATH}"
        ),
    )

    parser.add_argument(
        "--commit",
        action="store_true",
        help=(
            "Actually write workouts to SQLite. "
            "Without this flag the importer performs a dry run."
        ),
    )

    return parser.parse_args()


def validate_database(connection: sqlite3.Connection) -> None:
    required_tables = {
        "workouts",
        "workout_intervals",
        "interval_metrics",
    }

    table_rows = connection.execute(
        """
        SELECT name
        FROM sqlite_master
        WHERE type = 'table'
        """
    ).fetchall()

    existing_tables = {
        row[0]
        for row in table_rows
    }

    missing_tables = required_tables - existing_tables

    if missing_tables:
        missing = ", ".join(sorted(missing_tables))

        raise RuntimeError(
            f"Database is missing required tables: {missing}"
        )

    workout_columns = {
        row[1]
        for row in connection.execute(
            "PRAGMA table_info(workouts)"
        ).fetchall()
    }

    required_workout_columns = {
        "id",
        "prescription_id",
        "modality",
        "workout_date",
        "source_workbook",
        "program_day",
        "duration",
        "work_duration",
        "interval_count",
        "scoring_metric",
        "notes",
    }

    missing_columns = (
        required_workout_columns - workout_columns
    )

    if missing_columns:
        missing = ", ".join(sorted(missing_columns))

        raise RuntimeError(
            f"workouts table is missing required columns: {missing}"
        )


def validate_provenance(
    workouts: list[NormalizedWorkout],
) -> None:
    missing: list[str] = []

    for workout in workouts:
        missing_fields: list[str] = []

        if not workout.source_workbook.strip():
            missing_fields.append("source_workbook")

        if not workout.program_day.strip():
            missing_fields.append("program_day")

        if not missing_fields:
            continue

        missing.append(
            f"{workout.date} "
            f"{workout.prescription_id} "
            f"{workout.modality}: "
            f"{', '.join(missing_fields)}"
        )

    if not missing:
        return

    details = "\n".join(
        f"  - {item}"
        for item in missing
    )

    raise RuntimeError(
        "Historical workout provenance is incomplete.\n"
        f"{details}\n\n"
        "Regenerate or update the review CSV before importing."
    )


def normalize_workouts(
    review_path: Path,
) -> list[NormalizedWorkout]:
    candidates = read_reviewed_candidates(review_path)

    workouts: list[NormalizedWorkout] = []

    for candidate in candidates:
        try:
            workout = normalize_candidate(candidate)
            workouts.append(workout)
        except ValueError as error:
            print()
            print("SKIPPED NORMALIZATION FAILURE")
            print("SOURCE:", candidate.source_id)
            print("DATE:", candidate.date)
            print("PRESCRIPTION:", candidate.prescription)
            print("GEAR:", candidate.gear)
            print("MODALITY:", candidate.modality)
            print("ERROR:", error)
            print()

    return workouts


def create_backup(database_path: Path) -> Path:
    backup_path = database_path.with_suffix(".db.backup")

    shutil.copy2(
        database_path,
        backup_path,
    )

    return backup_path


def workout_exists(
    connection: sqlite3.Connection,
    workout: NormalizedWorkout,
) -> bool:
    row = connection.execute(
        """
        SELECT id
        FROM workouts
        WHERE prescription_id = ?
          AND modality = ?
          AND substr(workout_date, 1, 10) = ?
          AND work_duration = ?
          AND interval_count = ?
          AND source_workbook = ?
          AND program_day = ?
        LIMIT 1
        """,
        (
            workout.prescription_id,
            workout.modality,
            workout.date,
            workout.execution_plan.work_duration,
            workout.execution_plan.interval_count,
            workout.source_workbook,
            workout.program_day,
        ),
    ).fetchone()

    return row is not None


def insert_workout(
    connection: sqlite3.Connection,
    workout: NormalizedWorkout,
) -> int:
    cursor = connection.execute(
        """
        INSERT INTO workouts (
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
        )
        VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?)
        """,
        (
            workout.prescription_id,
            workout.modality,
            workout.date,
            workout.source_workbook,
            workout.program_day,
            workout.duration,
            workout.execution_plan.work_duration,
            workout.execution_plan.interval_count,
            workout.scoring_metric,
            workout.notes,
        ),
    )

    workout_id = cursor.lastrowid

    if workout_id is None:
        raise RuntimeError(
            "SQLite did not return a workout ID."
        )

    for interval in workout.intervals:
        interval_cursor = connection.execute(
            """
            INSERT INTO workout_intervals (
                workout_id,
                interval_number
            )
            VALUES (?, ?)
            """,
            (
                workout_id,
                interval.interval_number,
            ),
        )

        interval_id = interval_cursor.lastrowid

        if interval_id is None:
            raise RuntimeError(
                "SQLite did not return an interval ID."
            )

        for metric, value in interval.values.items():
            connection.execute(
                """
                INSERT INTO interval_metrics (
                    interval_id,
                    metric,
                    value
                )
                VALUES (?, ?, ?)
                """,
                (
                    interval_id,
                    metric,
                    value,
                ),
            )

    return workout_id


def print_workout(
    workout: NormalizedWorkout,
    duplicate: bool,
) -> None:
    status = "SKIP" if duplicate else "READY"

    print(
        f"{status:<5} "
        f"{workout.prescription_id:<3} "
        f"{workout.modality:<8} "
        f"{workout.date:<10} "
        f"{workout.program_day:<5} "
        f"work={workout.execution_plan.work_duration:<5} "
        f"expected={workout.execution_plan.interval_count:<2} "
        f"captured={len(workout.intervals)}"
    )


def main() -> None:
    args = parse_args()

    review_path: Path = args.review
    database_path: Path = args.database
    commit: bool = args.commit

    if not review_path.exists():
        raise FileNotFoundError(
            f"Review file not found: {review_path}"
        )

    if not database_path.exists():
        raise FileNotFoundError(
            f"Database not found: {database_path}"
        )

    workouts = normalize_workouts(review_path)

    print(f"Review file: {review_path}")
    print(f"Database:    {database_path}")
    print()

    connection = sqlite3.connect(database_path)

    try:
        connection.execute(
            "PRAGMA foreign_keys = ON"
        )

        validate_database(connection)

        print("Database schema: OK")
        print()

        print(f"Normalized workouts: {len(workouts)}")
        print()

        validate_provenance(workouts)

        source_workbooks = sorted(
            {
                workout.source_workbook
                for workout in workouts
            }
        )

        print(
            "Source workbook(s): "
            f"{', '.join(source_workbooks)}"
        )
        print()

        ready_workouts: list[NormalizedWorkout] = []
        duplicate_count = 0

        for workout in workouts:
            duplicate = workout_exists(
                connection,
                workout,
            )

            print_workout(
                workout,
                duplicate,
            )

            if duplicate:
                duplicate_count += 1
            else:
                ready_workouts.append(workout)

        print()
        print("-" * 78)
        print(f"Ready:      {len(ready_workouts)}")
        print(f"Duplicates: {duplicate_count}")
        print()

        if not commit:
            print("DRY RUN ONLY")
            print(
                f"{len(ready_workouts)} workouts are ready "
                "for SQLite import."
            )
            print(
                f"{duplicate_count} existing workouts "
                "will be skipped."
            )
            print("No database changes were made.")
            return

        if not ready_workouts:
            print("Nothing to import.")
            print("Database was not changed.")
            return

        backup_path = create_backup(database_path)

        print(f"Backup created: {backup_path}")
        print()

        connection.execute("BEGIN")

        try:
            imported = 0

            for workout in ready_workouts:
                # Recheck inside the transaction in case the
                # database changed after the initial scan.
                if workout_exists(
                    connection,
                    workout,
                ):
                    continue

                insert_workout(
                    connection,
                    workout,
                )

                imported += 1

            connection.commit()

        except Exception:
            connection.rollback()
            raise

        print(f"Imported: {imported}")
        print("SQLite transaction committed.")

    finally:
        connection.close()


if __name__ == "__main__":
    main()