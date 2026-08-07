from __future__ import annotations

import csv
from pathlib import Path

from models import (
    DateStatus,
    ImportStatus,
    ResultDetail,
    WorkoutCandidate,
    WorkoutType,
)


def read_reviewed_candidates(
    review_path: Path,
) -> list[WorkoutCandidate]:
    candidates: list[WorkoutCandidate] = []

    with review_path.open(
        "r",
        encoding="utf-8",
        newline="",
    ) as review_file:
        reader = csv.DictReader(review_file)

        for row in reader:
            review_decision = (
                row.get("review_decision", "")
                .strip()
                .upper()
            )

            import_status = ImportStatus(
                row["import_status"],
            )

            # Human review overrides parser.
            #
            # Blank review_decision means:
            # "Use the parser's recommendation."
            if review_decision:
                if review_decision != ImportStatus.READY.value:
                    continue
            elif import_status is not ImportStatus.READY:
                continue

            candidates.append(
                WorkoutCandidate(
                    source_id=row["source_id"],
                    source_workbook=row["source_workbook"],
                    source_row=int(row["source_row"]),
                    source_column=int(row["source_column"]),
                    program_day=row.get(
                        "program_day",
                        "",
                    ).strip(),
                    date=row["date"],
                    date_status=DateStatus(
                        row["date_status"],
                    ),
                    workout_type=WorkoutType(
                        row["workout_type"],
                    ),
                    gear=row["gear"],
                    prescription=row["prescription"],
                    modality=row["modality"],
                    import_status=import_status,
                    status_reason=row["status_reason"],
                    result_detail=ResultDetail(
                        row["result_detail"],
                    ),
                    garmin_lookup=(
                        row["garmin_lookup"]
                        .strip()
                        .lower()
                        == "yes"
                    ),
                    programming_text=row["programming_text"],
                    result_text=row["result_text"],
                    review_decision=row["review_decision"],
                    review_notes=row["review_notes"],
                )
            )

    return candidates