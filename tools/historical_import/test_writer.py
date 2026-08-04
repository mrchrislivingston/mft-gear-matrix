from __future__ import annotations

import csv
from pathlib import Path
from tempfile import TemporaryDirectory

from models import (
    DateStatus,
    ImportStatus,
    ResultDetail,
    WorkoutCandidate,
    WorkoutType,
)
from writer import OUTPUT_FIELDS, write_review_csv


def main() -> None:
    candidate = WorkoutCandidate(
        source_id="sample | 2025-04-14 | G5 | run",
        source_workbook="sample",
        source_row=1,
        source_column=2,
        date="2025-04-14",
        date_status=DateStatus.EXACT,
        workout_type=WorkoutType.GEAR,
        gear="G5",
        prescription="",
        modality="run",
        import_status=ImportStatus.READY,
        status_reason="Single supported workout",
        result_detail=ResultDetail.WORKOUT_AVERAGE,
        garmin_lookup=True,
        programming_text="Run - 5th Gear",
        result_text="Average pace 7:35",
    )

    with TemporaryDirectory() as temp_directory:
        output_path = (
            Path(temp_directory) / "review.csv"
        )

        write_review_csv(
            candidates=[candidate],
            output_path=output_path,
        )

        with output_path.open(
            "r",
            encoding="utf-8",
            newline="",
        ) as output_file:
            rows = list(csv.DictReader(output_file))

    assert len(rows) == 1
    assert list(rows[0].keys()) == OUTPUT_FIELDS
    assert rows[0]["date"] == "2025-04-14"
    assert rows[0]["workout_type"] == "gear"
    assert rows[0]["gear"] == "G5"
    assert rows[0]["import_status"] == "READY"
    assert rows[0]["garmin_lookup"] == "yes"
    assert rows[0]["review_decision"] == ""

    print("All writer tests passed.")


if __name__ == "__main__":
    main()