from __future__ import annotations

import csv
from pathlib import Path

from models import WorkoutCandidate


OUTPUT_FIELDS = [
    "source_id",
    "source_workbook",
    "source_row",
    "source_column",
    "date",
    "date_status",
    "workout_type",
    "gear",
    "prescription",
    "modality",
    "import_status",
    "status_reason",
    "result_detail",
    "garmin_lookup",
    "programming_text",
    "result_text",
    "review_decision",
    "review_notes",
]


def write_review_csv(
    candidates: list[WorkoutCandidate],
    output_path: Path,
) -> None:
    output_path.parent.mkdir(
        parents=True,
        exist_ok=True,
    )

    with output_path.open(
        "w",
        encoding="utf-8",
        newline="",
    ) as output_file:
        writer = csv.DictWriter(
            output_file,
            fieldnames=OUTPUT_FIELDS,
        )

        writer.writeheader()

        for candidate in candidates:
            writer.writerow(candidate.to_dict())