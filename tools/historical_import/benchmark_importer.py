from __future__ import annotations

import argparse
import shutil
import sqlite3
from pathlib import Path

from benchmark_models import NormalizedBenchmarkAttempt


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
            "Import normalized historical benchmark attempts into the "
            "MFT Gear Matrix SQLite database."
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
            "Actually write benchmark attempts to SQLite. "
            "Without this flag the importer performs a dry run."
        ),
    )

    return parser.parse_args()


def validate_database(connection: sqlite3.Connection) -> None:
    required_tables = {
        "benchmarks",
        "benchmark_attempts",
    }

    table_rows = connection.execute(
        """
        SELECT name
        FROM sqlite_master
        WHERE type = 'table'
        """
    ).fetchall()

    existing_tables = {row[0] for row in table_rows}

    missing_tables = required_tables - existing_tables

    if missing_tables:
        missing = ", ".join(sorted(missing_tables))
        raise RuntimeError(
            f"Database is missing required tables: {missing}"
        )


def create_backup(database_path: Path) -> Path:
    backup_path = database_path.with_suffix(".db.backup")
    shutil.copy2(database_path, backup_path)
    return backup_path


def benchmark_exists(
    connection: sqlite3.Connection,
    benchmark_id: str,
) -> bool:
    row = connection.execute(
        """
        SELECT id
        FROM benchmarks
        WHERE id = ?
        LIMIT 1
        """,
        (benchmark_id,),
    ).fetchone()

    return row is not None


def attempt_exists(
    connection: sqlite3.Connection,
    attempt: NormalizedBenchmarkAttempt,
) -> bool:
    row = connection.execute(
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
            attempt.benchmark_id,
            attempt.date,
            attempt.source_workbook,
            attempt.program_day,
        ),
    ).fetchone()

    return row is not None


def insert_attempt(
    connection: sqlite3.Connection,
    attempt: NormalizedBenchmarkAttempt,
) -> int:
    cursor = connection.execute(
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
        VALUES (?, ?, ?, ?, ?, ?, ?)
        """,
        (
            attempt.benchmark_id,
            attempt.date,
            attempt.score,
            attempt.source_workbook,
            attempt.program_day,
            attempt.details,
            attempt.notes,
        ),
    )

    attempt_id = cursor.lastrowid

    if attempt_id is None:
        raise RuntimeError(
            "SQLite did not return a benchmark attempt ID."
        )

    return attempt_id


def configured_attempts() -> list[NormalizedBenchmarkAttempt]:
    return [
        NormalizedBenchmarkAttempt(
            benchmark_id="matt_row",
            date="2025-09-22",
            score="183",
            source_workbook="Chris Livingston - Remote Coaching - Phase 1 2026",
            program_day="W4D1",
            details="Avg Pace - 2:04\nAvg Cals/Hr - 930",
        ),
        NormalizedBenchmarkAttempt(
            benchmark_id="echo_bike_cube_test",
            date="2025-10-07",
            score="316",
            source_workbook="Chris Livingston - Remote Coaching - Phase 1 2026",
            program_day="W6D2",
            details=(
                "Round 1 - 72 cal / 70 RPM / 370 W\n"
                "Round 2 - 80 cal / 72 RPM / 403 W\n"
                "Round 3 - 81 cal / 72 RPM / 403 W\n"
                "Round 4 - 83 cal / 73 RPM / 420 W"
            ),
        ),
        NormalizedBenchmarkAttempt(
            benchmark_id="matt_row",
            date="2025-10-28",
            score="195",
            source_workbook="Chris Livingston - Remote Coaching - Phase 1 2026",
            program_day="W9D1",
            details="Avg Pace - 2:01.4\nAvg Cals/Hr - 971",
        ),
        NormalizedBenchmarkAttempt(
            benchmark_id="echo_bike_cube_test",
            date="2025-10-31",
            score="321",
            source_workbook="Chris Livingston - Remote Coaching - Phase 1 2026",
            program_day="W9D5",
            details=(
                "Round 1 - 81 cal / 72 RPM / 403 W\n"
                "Round 2 - 80 cal / 72 RPM / 403 W\n"
                "Round 3 - 80 cal / 72 RPM / 403 W\n"
                "Round 4 - 80 cal / 72 RPM / 403 W"
            ),
        ),
    ]


def main() -> None:
    args = parse_args()
    database_path: Path = args.database

    if not database_path.exists():
        raise FileNotFoundError(
            f"Database not found: {database_path}"
        )

    connection = sqlite3.connect(database_path)

    try:
        connection.execute("PRAGMA foreign_keys = ON")
        validate_database(connection)

        print(f"Database: {database_path}")
        print("Database schema: OK")
        attempts = configured_attempts()

        print()
        print(f"Configured benchmark attempts: {len(attempts)}")
        print()

        ready_attempts: list[NormalizedBenchmarkAttempt] = []
        duplicate_count = 0

        for attempt in attempts:
            if not benchmark_exists(
                connection,
                attempt.benchmark_id,
            ):
                raise RuntimeError(
                    "Benchmark definition not found: "
                    f"{attempt.benchmark_id}"
                )

            duplicate = attempt_exists(
                connection,
                attempt,
            )

            status = "SKIP" if duplicate else "READY"

            print(
                f"{status:<5} "
                f"{attempt.benchmark_id:<20} "
                f"{attempt.date:<10} "
                f"{attempt.program_day:<5} "
                f"score={attempt.score}"
            )

            if duplicate:
                duplicate_count += 1
            else:
                ready_attempts.append(attempt)

        print()
        print("-" * 78)
        print(f"Ready:      {len(ready_attempts)}")
        print(f"Duplicates: {duplicate_count}")
        print()

        if not args.commit:
            print("DRY RUN ONLY")
            print(
                f"{len(ready_attempts)} benchmark attempts are ready "
                "for SQLite import."
            )
            print(
                f"{duplicate_count} existing benchmark attempts "
                "will be skipped."
            )
            print("No database changes were made.")
            return

        if not ready_attempts:
            print("Nothing to import.")
            print("Database was not changed.")
            return

        backup_path = create_backup(database_path)
        print(f"Backup created: {backup_path}")
        print()

        connection.execute("BEGIN")

        try:
            imported = 0

            for attempt in ready_attempts:
                if attempt_exists(
                    connection,
                    attempt,
                ):
                    continue

                insert_attempt(
                    connection,
                    attempt,
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
