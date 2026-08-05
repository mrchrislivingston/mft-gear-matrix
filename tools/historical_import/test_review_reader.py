from __future__ import annotations

import csv
import tempfile
from pathlib import Path

from review_reader import read_reviewed_candidates


FIELDNAMES = [
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


def test_reads_ready_rows_only() -> None:
    rows = [
        {
            "source_id": "ready-row",
            "source_workbook": "test.csv",
            "source_row": "10",
            "source_column": "2",
            "date": "2025-10-01",
            "date_status": "exact",
            "workout_type": "gear",
            "gear": "G1",
            "prescription": "G1",
            "modality": "row",
            "import_status": "READY",
            "status_reason": "",
            "result_detail": "interval_results",
            "garmin_lookup": "yes",
            "programming_text": "Test programming",
            "result_text": "Test result",
            "review_decision": "READY",
            "review_notes": "Approved",
        },
        {
            "source_id": "skipped-row",
            "source_workbook": "test.csv",
            "source_row": "20",
            "source_column": "2",
            "date": "2025-10-02",
            "date_status": "exact",
            "workout_type": "gear",
            "gear": "G2",
            "prescription": "G2",
            "modality": "run",
            "import_status": "READY",
            "status_reason": "",
            "result_detail": "workout_average",
            "garmin_lookup": "",
            "programming_text": "Other programming",
            "result_text": "Other result",
            "review_decision": "SKIP",
            "review_notes": "",
        },
    ]

    with tempfile.TemporaryDirectory() as directory:
        review_path = Path(directory) / "review.csv"

        with review_path.open(
            "w",
            encoding="utf-8",
            newline="",
        ) as review_file:
            writer = csv.DictWriter(
                review_file,
                fieldnames=FIELDNAMES,
            )

            writer.writeheader()
            writer.writerows(rows)

        candidates = read_reviewed_candidates(
            review_path,
        )

    assert len(candidates) == 1

    candidate = candidates[0]

    assert candidate.source_id == "ready-row"
    assert candidate.review_decision == "READY"
    assert candidate.modality == "row"
    assert candidate.garmin_lookup is True


if __name__ == "__main__":
    test_reads_ready_rows_only()

    print("All review reader tests passed.")