from __future__ import annotations

import csv
from datetime import datetime
from pathlib import Path
from tempfile import TemporaryDirectory

from models import DateStatus, ImportStatus, WorkoutType
from reader import (
    has_supported_date_header,
    has_week_day_header,
    parse_date_header,
    read_workout_candidates,
)


def test_date_parsing() -> None:
    parsed_date, date_status = parse_date_header(
        "Monday April 14",
        2025,
    )

    assert parsed_date == "2025-04-14"
    assert date_status is DateStatus.EXACT

    parsed_date, date_status = parse_date_header(
        "Mon - W1D1\n\n7/21",
        2025,
    )

    assert parsed_date == "2025-07-21"
    assert date_status is DateStatus.EXACT

    assert has_supported_date_header(
        "Mon - W1D1\n\n7/21",
    )

    assert has_week_day_header(
        "Mon - W2D1",
    )

    assert not has_supported_date_header(
        "Notes / Results",
    )


def test_exact_and_inferred_candidates() -> None:
    with TemporaryDirectory() as temp_directory:
        input_path = (
            Path(temp_directory) / "sample.csv"
        )

        with input_path.open(
            "w",
            encoding="utf-8",
            newline="",
        ) as output_file:
            writer = csv.writer(output_file)

            writer.writerow(
                [
                    "Mon - W1D1\n\n7/21",
                    "Run - 5th Gear",
                    "Zone 2 C2 Bike",
                ],
            )

            writer.writerow(
                [
                    "Notes / Results",
                    "Average pace 7:35",
                    "Completed 45 minutes",
                ],
            )

            writer.writerow(
                [
                    "Mon - W2D1",
                    "P2 Echo Bike",
                    "",
                ],
            )

            writer.writerow(
                [
                    "Notes / Results",
                    "Completed",
                    "",
                ],
            )

        candidates = read_workout_candidates(
            input_path=input_path,
            year=2025,
        )

    assert len(candidates) == 3

    run_candidate = candidates[0]

    assert run_candidate.date == "2025-07-21"
    assert run_candidate.date_status is DateStatus.EXACT
    assert run_candidate.workout_type is WorkoutType.GEAR
    assert run_candidate.gear == "G5"
    assert run_candidate.modality == "run"
    assert (
        run_candidate.import_status
        is ImportStatus.READY
    )

    zone_candidate = candidates[1]

    assert zone_candidate.date == "2025-07-21"
    assert zone_candidate.date_status is DateStatus.EXACT
    assert zone_candidate.workout_type is WorkoutType.ZONE
    assert zone_candidate.prescription == "Z2"
    assert zone_candidate.modality == "bikeErg"
    assert (
        zone_candidate.import_status
        is ImportStatus.READY
    )

    inferred_candidate = candidates[2]

    assert inferred_candidate.date == "2025-07-28"
    assert (
        inferred_candidate.date_status
        is DateStatus.INFERRED
    )
    assert (
        inferred_candidate.workout_type
        is WorkoutType.POWER
    )
    assert inferred_candidate.prescription == "P2"
    assert inferred_candidate.modality == "echo"
    assert (
        inferred_candidate.import_status
        is ImportStatus.READY
    )


def test_unresolved_date_requires_review() -> None:
    with TemporaryDirectory() as temp_directory:
        input_path = (
            Path(temp_directory)
            / "unresolved_date.csv"
        )

        with input_path.open(
            "w",
            encoding="utf-8",
            newline="",
        ) as output_file:
            writer = csv.writer(output_file)

            writer.writerow(
                [
                    "Mon - W1D1",
                    "Zone 2 C2 Bike",
                ],
            )

            writer.writerow(
                [
                    "Notes / Results",
                    (
                        "45:00 in Z2\n"
                        "Avg HR - 128\n"
                        "Avg Watts - 167"
                    ),
                ],
            )

        candidates = read_workout_candidates(
            input_path=input_path,
            year=2025,
        )

    assert len(candidates) == 1

    candidate = candidates[0]

    assert candidate.date == ""
    assert (
        candidate.date_status
        is DateStatus.UNRESOLVED
    )
    assert (
        candidate.workout_type
        is WorkoutType.ZONE
    )
    assert candidate.prescription == "Z2"
    assert candidate.modality == "bikeErg"
    assert (
        candidate.import_status
        is ImportStatus.REVIEW
    )
    assert candidate.status_reason == (
        "Workout date is unresolved"
    )


def test_explicit_program_start_date() -> None:
    with TemporaryDirectory() as temp_directory:
        input_path = (
            Path(temp_directory)
            / "explicit_start_date.csv"
        )

        with input_path.open(
            "w",
            encoding="utf-8",
            newline="",
        ) as output_file:
            writer = csv.writer(output_file)

            writer.writerow(
                [
                    "Sat - W5D6",
                    "Zone 2 C2 Bike",
                ],
            )

            writer.writerow(
                [
                    "Notes / Results",
                    (
                        "35:00 today\n"
                        "Avg HR - 127\n"
                        "Avg Watts - 167"
                    ),
                ],
            )

            writer.writerow(
                [
                    "Fri - W9D5",
                    "Zone 2 Row",
                ],
            )

            writer.writerow(
                [
                    "Notes / Results",
                    "45:00 Zone 2",
                ],
            )

        candidates = read_workout_candidates(
            input_path=input_path,
            year=2025,
            program_start_date=datetime(
                2025,
                9,
                1,
            ),
        )

    assert len(candidates) == 2

    week_five_candidate = candidates[0]

    assert week_five_candidate.date == "2025-10-04"
    assert (
        week_five_candidate.date_status
        is DateStatus.INFERRED
    )

    week_nine_candidate = candidates[1]

    assert week_nine_candidate.date == "2025-10-31"
    assert (
        week_nine_candidate.date_status
        is DateStatus.INFERRED
    )


def main() -> None:
    test_date_parsing()
    test_exact_and_inferred_candidates()
    test_unresolved_date_requires_review()
    test_explicit_program_start_date()

    print("All reader tests passed.")


if __name__ == "__main__":
    main()