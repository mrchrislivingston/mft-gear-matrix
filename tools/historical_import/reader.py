from __future__ import annotations

import csv
from dataclasses import replace
import re
from datetime import datetime, timedelta
from pathlib import Path

from models import (
    DateStatus,
    ImportStatus,
    ResultDetail,
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


def extract_program_day(
    date_header: str,
) -> str:
    match = WEEK_DAY_PATTERN.search(
        date_header,
    )

    if match is None:
        return ""

    week_number = int(match.group(1))
    day_number = int(match.group(2))

    return f"W{week_number}D{day_number}"


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

    week_day_match = WEEK_DAY_PATTERN.search(
        date_header,
    )

    if (
        week_day_match is None
        or program_start_date is None
    ):
        if exact_date:
            return exact_date, exact_status
        return "", DateStatus.UNRESOLVED

    week_number = int(week_day_match.group(1))
    day_number = int(week_day_match.group(2))

    offset_days = (
        (week_number - 1) * 7
        + (day_number - 1)
    )

    calendar_date = program_start_date + timedelta(
        days=offset_days,
    )
    calendar_date_text = calendar_date.date().isoformat()

    if not exact_date:
        return (
            calendar_date_text,
            DateStatus.INFERRED,
        )

    parsed_explicit_date = datetime.fromisoformat(
        exact_date,
    )

    explicit_date_options = []
    for candidate_year in (
        calendar_date.year - 1,
        calendar_date.year,
        calendar_date.year + 1,
    ):
        try:
            explicit_date_options.append(
                parsed_explicit_date.replace(
                    year=candidate_year,
                ),
            )
        except ValueError:
            continue

    explicit_date = min(
        explicit_date_options,
        key=lambda candidate_date: abs(
            (
                candidate_date.date()
                - calendar_date.date()
            ).days,
        ),
    )
    difference_days = abs(
        (explicit_date.date() - calendar_date.date()).days,
    )

    if difference_days == 0:
        return calendar_date_text, exact_status

    if difference_days == 1:
        return (
            calendar_date_text,
            DateStatus.CORRECTED,
        )

    program_day = (
        f"W{week_number}D{day_number}"
    )
    raise ValueError(
        f"{program_day} date conflicts with the program calendar",
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


def _resolve_ambiguous_erg_modality(
    workout_type: WorkoutType,
    modality: str,
    result_text: str,
) -> str | None:
    if (
        workout_type is not WorkoutType.ZONE
        or set(modality.split("/")) != {"row", "bikeErg"}
    ):
        return None

    duration_match = re.search(
        r"\b(\d{1,3}):(\d{2})\s+in\s+(?:zone\s*)?z?2\b",
        result_text,
        re.IGNORECASE,
    )
    pace_match = re.search(
        r"\bAvg\s+Pace\s*[-:]\s*"
        r"(\d{1,2}):(\d{2}(?:\.\d+)?)\b",
        result_text,
        re.IGNORECASE,
    )
    distance_match = re.search(
        r"\bDistance\s*[-:]\s*"
        r"(\d+(?:\.\d+)?)\s*KM\b",
        result_text,
        re.IGNORECASE,
    )

    if not all((duration_match, pace_match, distance_match)):
        return None

    assert duration_match is not None
    assert pace_match is not None
    assert distance_match is not None

    duration_seconds = (
        int(duration_match.group(1)) * 60
        + int(duration_match.group(2))
    )
    pace_seconds = (
        int(pace_match.group(1)) * 60
        + float(pace_match.group(2))
    )
    recorded_kilometers = float(distance_match.group(1))

    if (
        duration_seconds <= 0
        or pace_seconds <= 0
        or recorded_kilometers <= 0
    ):
        return None

    expected_bike_kilometers = duration_seconds / pace_seconds
    expected_row_kilometers = expected_bike_kilometers * 0.5

    bike_error = (
        abs(recorded_kilometers - expected_bike_kilometers)
        / recorded_kilometers
    )
    row_error = (
        abs(recorded_kilometers - expected_row_kilometers)
        / recorded_kilometers
    )

    tolerance = 0.08

    if bike_error <= tolerance and bike_error < row_error:
        return "bikeErg"

    if row_error <= tolerance and row_error < bike_error:
        return "row"

    return None


def _expand_mixed_gear_candidate(
    candidate: WorkoutCandidate,
) -> list[WorkoutCandidate]:
    if (
        candidate.workout_type is not WorkoutType.GEAR
        or candidate.import_status is not ImportStatus.TBD_LATER
        or candidate.status_reason != "Mixed-gear workout"
        or not candidate.modality
        or "/" in candidate.modality
    ):
        return [candidate]

    gears = detect_gears(candidate.programming_text)
    plan_matches = list(
        re.finditer(
            r"\bAMRAP\s+(\d{1,2}:\d{2})\s*[x×]\s*(\d+)\b",
            candidate.programming_text,
            re.IGNORECASE,
        ),
    )
    has_supported_header = re.search(
        r"\bDist(?:ance)?\s*/\s*Watts?\s*/\s*"
        r"Cals?\s*/\s*Pace\b",
        candidate.result_text,
        re.IGNORECASE,
    )
    result_matches = list(
        re.finditer(
            r"^\s*(\d+(?:\.\d+)?)\s*/\s*(\d+)\s*/\s*"
            r"(\d+)\s*/\s*"
            r"(\d{1,2}:\d{2}(?:\.\d+)?)\s*$",
            candidate.result_text,
            re.IGNORECASE | re.MULTILINE,
        ),
    )

    if (
        has_supported_header is None
        or len(gears) < 2
        or len(gears) != len(plan_matches)
    ):
        return [candidate]

    expected_result_count = sum(
        int(match.group(2))
        for match in plan_matches
    )

    if len(result_matches) != expected_result_count:
        return [candidate]

    trailing_notes = candidate.result_text[
        result_matches[-1].end():
    ].strip()
    heading = candidate.programming_text.splitlines()[0]
    expanded: list[WorkoutCandidate] = []
    result_index = 0

    for index, gear_number in enumerate(gears):
        plan_match = plan_matches[index]
        interval_count = int(plan_match.group(2))
        selected_results = result_matches[
            result_index:result_index + interval_count
        ]
        result_index += interval_count

        next_plan_start = (
            plan_matches[index + 1].start()
            if index + 1 < len(plan_matches)
            else len(candidate.programming_text)
        )
        programming_section = candidate.programming_text[
            plan_match.start():next_plan_start
        ].strip()

        split_result_lines = [
            "Dist/Watts/Cals/Pace",
            *[
                match.group(0).strip()
                for match in selected_results
            ],
        ]

        if trailing_notes:
            split_result_lines.append(trailing_notes)

        gear = f"G{gear_number}"

        expanded.append(
            replace(
                candidate,
                source_id=f"{candidate.source_id} | split-{gear}",
                gear=gear,
                import_status=ImportStatus.READY,
                status_reason="Split from a mixed-gear workout",
                result_detail=ResultDetail.INTERVAL_RESULTS,
                programming_text=(
                    f"{heading}\n{programming_section}"
                ),
                result_text="\n".join(split_result_lines),
            ),
        )

    return expanded


def read_workout_candidates(
    input_path: Path,
    year: int,
    program_start_date: datetime | None = None,
) -> list[WorkoutCandidate]:
    with input_path.open(
        "r",
        encoding="utf-8-sig",
        newline="",
    ) as input_file:
        rows = list(csv.reader(input_file))

    resolved_program_start_date = (
        program_start_date
        if program_start_date is not None
        else _find_program_start_date(
            rows,
            year,
        )
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
                program_start_date=(
                    resolved_program_start_date
                ),
            )
        )

        program_day = extract_program_day(
            date_header,
        )

        if not program_day and workout_date and resolved_program_start_date:
            workout_datetime = datetime.fromisoformat(
                workout_date,
            )

            offset_days = (
                workout_datetime.date()
                - resolved_program_start_date.date()
            ).days

            if offset_days >= 0:
                week_number = (offset_days // 7) + 1
                day_number = (offset_days % 7) + 1
                program_day = f"W{week_number}D{day_number}"

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

            if not is_relevant_workout(
                programming_text,
            ):
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

            gear = _gear_text(
                programming_text,
            )

            prescription = _prescription_text(
                programming_text,
                workout_type,
            )

            modality = _modality_text(
                programming_text,
                result_text,
            )

            resolved_erg_modality = (
                _resolve_ambiguous_erg_modality(
                    workout_type,
                    modality,
                    result_text,
                )
            )

            if resolved_erg_modality is not None:
                modality = resolved_erg_modality

                if import_status is ImportStatus.TBD_LATER:
                    import_status = ImportStatus.READY
                    status_reason = (
                        "Result duration, pace, and distance "
                        "identify the modality"
                    )

            if (
                import_status is ImportStatus.READY
                and date_status is DateStatus.UNRESOLVED
            ):
                import_status = ImportStatus.REVIEW
                status_reason = (
                    "Workout date is unresolved"
                )

            source_id = " | ".join(
                [
                    input_path.stem,
                    workout_date
                    or f"row-{row_index + 1}",
                    f"column-{column_index + 1}",
                    workout_type.value,
                    gear
                    or prescription
                    or "unknown",
                    modality or "unknown",
                ],
            )

            candidate = WorkoutCandidate(
                source_id=source_id,
                source_workbook=input_path.stem,
                source_row=row_index + 1,
                source_column=column_index + 1,
                program_day=program_day,
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
            )

            candidates.extend(
                _expand_mixed_gear_candidate(candidate),
            )

    return candidates
