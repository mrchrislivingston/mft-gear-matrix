from __future__ import annotations

import csv
from datetime import datetime
from pathlib import Path

from benchmark_models import BenchmarkCandidate
from benchmark_registry import find_benchmark_matches
from parser import detect_candidate_modalities, normalize_text
from reader import (
    _find_program_start_date,
    _parse_or_infer_date,
    extract_program_day,
    has_supported_date_header,
    has_week_day_header,
)


def read_benchmark_candidates(
    input_path: Path,
    year: int,
    program_start_date: datetime | None = None,
) -> list[BenchmarkCandidate]:
    with input_path.open(
        "r",
        encoding="utf-8-sig",
        newline="",
    ) as input_file:
        rows = list(csv.reader(input_file))

    resolved_program_start_date = (
        program_start_date
        if program_start_date is not None
        else _find_program_start_date(rows, year)
    )

    candidates: list[BenchmarkCandidate] = []

    for row_index, row in enumerate(rows):
        if not row:
            continue

        date_header = normalize_text(row[0])

        if not (
            has_supported_date_header(date_header)
            or has_week_day_header(date_header)
        ):
            continue

        result_row_index = row_index + 1
        if result_row_index >= len(rows):
            continue

        result_row = rows[result_row_index]

        workout_date, date_status = _parse_or_infer_date(
            date_header=date_header,
            year=year,
            program_start_date=resolved_program_start_date,
        )

        program_day = extract_program_day(date_header)

        if (
            not program_day
            and workout_date
            and resolved_program_start_date
        ):
            workout_datetime = datetime.fromisoformat(workout_date)
            offset_days = (
                workout_datetime.date()
                - resolved_program_start_date.date()
            ).days

            if offset_days >= 0:
                week_number = (offset_days // 7) + 1
                day_number = (offset_days % 7) + 1
                program_day = f"W{week_number}D{day_number}"

        max_columns = max(len(row), len(result_row))

        for column_index in range(1, max_columns):
            programming_text = normalize_text(
                row[column_index]
                if column_index < len(row)
                else ""
            )
            result_text = normalize_text(
                result_row[column_index]
                if column_index < len(result_row)
                else ""
            )

            if not programming_text and not result_text:
                continue

            matches = find_benchmark_matches(
                programming_text
            )

            if not matches:
                continue

            modality = "/".join(
                detect_candidate_modalities(
                    programming_text=programming_text,
                    result_text=result_text,
                )
            )

            for match in matches:
                source_id = " | ".join(
                    [
                        input_path.stem,
                        workout_date or f"row-{row_index + 1}",
                        f"column-{column_index + 1}",
                        "benchmark",
                        match.key,
                        modality or "unknown",
                    ]
                )

                candidates.append(
                    BenchmarkCandidate(
                        source_id=source_id,
                        source_workbook=input_path.stem,
                        source_row=row_index + 1,
                        source_column=column_index + 1,
                        program_day=program_day,
                        date=workout_date,
                        date_status=date_status,
                        benchmark_key=match.key,
                        benchmark_name=match.display_name,
                        modality=modality,
                        programming_text=programming_text,
                        result_text=result_text,
                    )
                )

    return candidates