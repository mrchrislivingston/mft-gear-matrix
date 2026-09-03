from __future__ import annotations

import csv
import re

from datetime import datetime, timedelta
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


_WEEK_RESULT_PATTERN = re.compile(
    r"^\s*WEEK\s+(?P<week>\d+)\s*$",
    re.IGNORECASE,
)

_WRITTEN_DATE_PATTERN = re.compile(
    r"\b(?P<month>"
    r"Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|"
    r"May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|"
    r"Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?"
    r")\s+"
    r"(?P<day>\d{1,2})(?:st|nd|rd|th)?\b",
    re.IGNORECASE,
)

_MONTHS = {
    "jan": 1,
    "feb": 2,
    "mar": 3,
    "apr": 4,
    "may": 5,
    "jun": 6,
    "jul": 7,
    "aug": 8,
    "sep": 9,
    "oct": 10,
    "nov": 11,
    "dec": 12,
}


def _cell(
    row: list[str],
    column_index: int,
) -> str:
    if column_index >= len(row):
        return ""

    return normalize_text(row[column_index])


def _is_programming_header(value: str) -> bool:
    return (
        has_supported_date_header(value)
        or has_week_day_header(value)
    )


def _week_number(program_day: str) -> int | None:
    match = re.fullmatch(
        r"W(?P<week>\d+)D\d+",
        program_day,
        re.IGNORECASE,
    )

    if match is None:
        return None

    return int(match.group("week"))


def _program_day_date(
    program_day: str,
    program_start_date: datetime | None,
) -> str:
    if program_start_date is None:
        return ""

    match = re.fullmatch(
        r"W(?P<week>\d+)D(?P<day>\d+)",
        program_day,
        re.IGNORECASE,
    )

    if match is None:
        return ""

    week = int(match.group("week"))
    day = int(match.group("day"))

    resolved = program_start_date + timedelta(
        days=((week - 1) * 7) + (day - 1),
    )

    return resolved.date().isoformat()


def _find_phase_start_date(
    rows: list[list[str]],
    year: int,
) -> datetime | None:
    for row in rows:
        if not row:
            continue

        header = normalize_text(row[0])

        if extract_program_day(header).upper() != "W1D1":
            continue

        match = _WRITTEN_DATE_PATTERN.search(header)

        if match is None:
            continue

        month = _MONTHS[match.group("month")[:3].casefold()]
        day = int(match.group("day"))

        return datetime(year, month, day)

    return None


def _result_rows(
    rows: list[list[str]],
    programming_row_index: int,
    column_index: int,
) -> list[tuple[int, str, str]]:
    values: list[tuple[int, str, str]] = []

    for row_index in range(
        programming_row_index + 1,
        len(rows),
    ):
        row = rows[row_index]
        label = normalize_text(row[0]) if row else ""

        if _is_programming_header(label):
            break

        result_text = _cell(row, column_index)

        if result_text:
            values.append(
                (
                    row_index + 1,
                    label,
                    result_text,
                ),
            )

    return values


def _select_result(
    result_rows: list[tuple[int, str, str]],
    program_day: str,
    previous_results: set[str],
) -> tuple[str, int, str, str]:
    target_week = _week_number(program_day)

    if target_week is not None:
        matching_week_rows = [
            row
            for row in result_rows
            if (
                (match := _WEEK_RESULT_PATTERN.fullmatch(row[1]))
                is not None
                and int(match.group("week")) == target_week
            )
        ]

        if len(matching_week_rows) == 1:
            row_number, _, result_text = matching_week_rows[0]

            return (
                result_text,
                row_number,
                "selected",
                f"Matched WEEK {target_week} result row",
            )

        if len(matching_week_rows) > 1:
            return (
                "",
                0,
                "needs_review",
                f"Multiple WEEK {target_week} result rows",
            )

    if len(result_rows) == 1:
        row_number, _, result_text = result_rows[0]

        return (
            result_text,
            row_number,
            "selected",
            "Single nonempty result row",
        )

    if len(result_rows) > 1:
        new_rows = [
            row
            for row in result_rows
            if row[2] not in previous_results
        ]

        if len(new_rows) == 1:
            row_number, _, result_text = new_rows[0]

            return (
                result_text,
                row_number,
                "selected",
                "Discarded an exact carried-forward result",
            )

        return (
            "",
            0,
            "needs_review",
            "Multiple possible result rows",
        )

    return (
        "",
        0,
        "missing",
        "No recorded benchmark result",
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

    if resolved_program_start_date is None:
        resolved_program_start_date = _find_phase_start_date(
            rows,
            year,
        )

    candidates: list[BenchmarkCandidate] = []
    previous_results: dict[
        tuple[str, str],
        set[str],
    ] = {}

    for row_index, row in enumerate(rows):
        if not row:
            continue

        date_header = normalize_text(row[0])

        if not _is_programming_header(date_header):
            continue

        parsed_date, date_status = _parse_or_infer_date(
            date_header=date_header,
            year=year,
            program_start_date=resolved_program_start_date,
        )

        program_day = extract_program_day(date_header)
        inferred_date = _program_day_date(
            program_day,
            resolved_program_start_date,
        )
        workout_date = inferred_date or parsed_date

        for column_index in range(1, len(row)):
            programming_text = _cell(row, column_index)

            if not programming_text:
                continue

            matches = find_benchmark_matches(programming_text)

            if not matches:
                continue

            possible_results = _result_rows(
                rows,
                row_index,
                column_index,
            )

            modality = "/".join(
                detect_candidate_modalities(
                    programming_text=programming_text,
                    result_text="\n".join(
                        value[2]
                        for value in possible_results
                    ),
                ),
            )

            for benchmark_match in matches:
                result_key = (
                    benchmark_match.key,
                    modality,
                )
                known_results = previous_results.setdefault(
                    result_key,
                    set(),
                )

                (
                    result_text,
                    result_source_row,
                    result_status,
                    result_reason,
                ) = _select_result(
                    possible_results,
                    program_day,
                    known_results,
                )

                if result_text:
                    known_results.add(result_text)

                source_id = " | ".join(
                    [
                        input_path.stem,
                        workout_date or f"row-{row_index + 1}",
                        f"column-{column_index + 1}",
                        "benchmark",
                        benchmark_match.key,
                        modality or "unknown",
                    ],
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
                        benchmark_key=benchmark_match.key,
                        benchmark_name=benchmark_match.display_name,
                        modality=modality,
                        programming_text=programming_text,
                        result_text=result_text,
                        result_source_row=result_source_row,
                        result_status=result_status,
                        result_reason=result_reason,
                    ),
                )

    return candidates
