from __future__ import annotations

import csv
import re
from datetime import datetime, timedelta
from pathlib import Path

from models import (
    DateStatus,
    ImportStatus,
    WorkoutCandidate,
    WorkoutType,
)
from parser import (
    classify_candidate,
    detect_candidate_modalities,
    detect_gears,
    detect_power_prescriptions,
    detect_result_detail,
    detect_workout_type,
    detect_zone_prescriptions,
    is_relevant_workout,
    normalize_text,
)


WRITTEN_DATE_PATTERN = re.compile(
    r"\b("
    r"Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|"
    r"May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|"
    r"Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?"
    r")\s+(\d{1,2})\b",
    re.IGNORECASE,
)

NUMERIC_DATE_PATTERN = re.compile(
    r"\b(\d{1,2})/(\d{1,2})\b",
)

WEEK_DAY_PATTERN = re.compile(
    r"\bW(\d+)D(\d+)\b",
    re.IGNORECASE,
)


def has_supported_date_header(date_header: str) -> bool:
    return bool(
        WRITTEN_DATE_PATTERN.search(date_header)
        or NUMERIC_DATE_PATTERN.search(date_header)
    )


def has_week_day_header(date_header: str) -> bool:
    return WEEK_DAY_PATTERN.search(date_header) is not None


def parse_date_header(
    date_header: str,
    year: int,
) -> tuple[str, DateStatus]:
    written_match = WRITTEN_DATE_PATTERN.search(
        date_header,
    )

    if written_match is not None:
        month_text = written_match.group(1)
        day = int(written_match.group(2))

        parsed_date = datetime.strptime(
            f"{month_text[:3]} {day} {year}",
            "%b %d %Y",
        )

        return (
            parsed_date.date().isoformat(),
            DateStatus.EXACT,
        )

    numeric_match = NUMERIC_DATE_PATTERN.search(
        date_header,
    )

    if numeric_match is not None:
        month = int(numeric_match.group(1))
        day = int(numeric_match.group(2))

        parsed_date = datetime(
            year=year,
            month=month,
            day=day,
        )

        return (
            parsed_date.date().isoformat(),
            DateStatus.EXACT,
        )

    return "", DateStatus.UNRESOLVED


def _find_program_start_date(
    rows: list[list[str]],
    year: int,
) -> datetime | None:
    for row in rows:
        if not row:
            continue

        date_header = normalize_text(row[0])
        week_day_match = WEEK_DAY_PATTERN.search(
            date_header,
        )

        if week_day_match is None:
            continue

        if not has_supported_date_header(date_header):
            continue

        exact_date_text, _ = parse_date_header(
            date_header,
            year,
        )

        if not exact_date_text:
            continue

        exact_date = datetime.fromisoformat(
            exact_date_text,
        )

        week_number = int(week_day_match.group(1))
        day_number = int(week_day_match.group(2))

        offset_days = (
            (week_number - 1) * 7
            + (day_number - 1)
        )

        return exact_date - timedelta(
            days=offset_days,
        )

    return None


def _parse_or_infer_date(
    date_header: str,
    year: int,
    program_start_date: datetime | None,
) -> tuple[str, DateStatus]:
    exact_date, exact_status = parse_date_header(
        date_header,
        year,
    )

    if exact_date:
        return exact_date, exact_status

    week_day_match = WEEK_DAY_PATTERN.search(
        date_header,
    )

    if (
        week_day_match is None
        or program_start_date is None
    ):
        return "", DateStatus.UNRESOLVED

    week_number = int(week_day_match.group(1))
    day_number = int(week_day_match.group(2))

    offset_days = (
        (week_number - 1) * 7
        + (day_number - 1)
    )

    inferred_date = program_start_date + timedelta(
        days=offset_days,
    )

    return (
        inferred_date.date().isoformat(),
        DateStatus.INFERRED,
    )


def _gear_text(programming_text: str) -> str:
    return "/".join(
        f"G{gear}"
        for gear in detect_gears(programming_text)
    )


def _prescription_text(
    programming_text: str,
    workout_type: WorkoutType,
) -> str:
    if workout_type is WorkoutType.POWER:
        return "/".join(
            f"P{number}"
            for number in detect_power_prescriptions(
                programming_text,
            )
        )

    if workout_type is WorkoutType.ZONE:
        return "/".join(
            f"Z{number}"
            for number in detect_zone_prescriptions(
                programming_text,
            )
        )

    return ""


def _modality_text(
    programming_text: str,
    result_text: str,
) -> str:
    return "/".join(
        detect_candidate_modalities(
            programming_text=programming_text,
            result_text=result_text,
        ),
    )


def read_workout_candidates(
    input_path: Path,
    year: int,
) -> list[WorkoutCandidate]:
    with input_path.open(
        "r",
        encoding="utf-8-sig",
        newline="",
    ) as input_file:
        rows = list(csv.reader(input_file))

    program_start_date = _find_program_start_date(
        rows,
        year,
    )

    candidates: list[WorkoutCandidate] = []

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

        workout_date, date_status = (
            _parse_or_infer_date(
                date_header=date_header,
                year=year,
                program_start_date=program_start_date,
            )
        )

        max_columns = max(
            len(row),
            len(result_row),
        )

        for column_index in range(1, max_columns):
            programming_text = normalize_text(
                row[column_index]
                if column_index < len(row)
                else "",
            )

            if not programming_text:
                continue

            if not is_relevant_workout(programming_text):
                continue

            result_text = normalize_text(
                result_row[column_index]
                if column_index < len(result_row)
                else "",
            )

            workout_type = detect_workout_type(
                programming_text,
            )

            import_status, status_reason = (
                classify_candidate(
                    programming_text=programming_text,
                    result_text=result_text,
                )
            )

            gear = _gear_text(programming_text)
            prescription = _prescription_text(
                programming_text,
                workout_type,
            )
            modality = _modality_text(
                programming_text,
                result_text,
            )

            if (
                import_status is ImportStatus.READY
                and date_status is DateStatus.UNRESOLVED
            ):
                import_status = ImportStatus.REVIEW
                status_reason = "Workout date is unresolved"

            source_id = " | ".join(
                [
                    input_path.stem,
                    workout_date or f"row-{row_index + 1}",
                    f"column-{column_index + 1}",
                    workout_type.value,
                    gear or prescription or "unknown",
                    modality or "unknown",
                ],
            )

            candidates.append(
                WorkoutCandidate(
                    source_id=source_id,
                    source_workbook=input_path.stem,
                    source_row=row_index + 1,
                    source_column=column_index + 1,
                    date=workout_date,
                    date_status=date_status,
                    workout_type=workout_type,
                    gear=gear,
                    prescription=prescription,
                    modality=modality,
                    import_status=import_status,
                    status_reason=status_reason,
                    result_detail=detect_result_detail(
                        result_text,
                    ),
                    garmin_lookup=False,
                    programming_text=programming_text,
                    result_text=result_text,
                ),
            )

    return candidates