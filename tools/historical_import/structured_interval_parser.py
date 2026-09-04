from __future__ import annotations

import re


STANDARD_ROUND_PATTERN = re.compile(
    r"Rd\s*\d+\s*[-:]\s*"
    r"(\d+)\s*/\s*(\d+)\s*/\s*(\d+)",
    re.IGNORECASE,
)

MAX_ROUND_PATTERN = re.compile(
    r"Rd\s*\d+\s+"
    r"(\d+)\s*/\s*(\d+)\s*/\s*(\d+)",
    re.IGNORECASE,
)

BIKEERG_PATTERN = re.compile(
    r"(?<![\d:.])"
    r"(\d{3,4})\s*/\s*"
    r"(\d+:\d{2}(?:\.\d+)?|\d{3}(?:\.\d+)?)"
    r"\s*/\s*"
    r"(\d{2,3})"
    r"(?![\d:.])"
)

CALORIE_SEQUENCE_PATTERN = re.compile(
    r"\b(\d+(?:\s*/\s*\d+){2,})\b",
)

CALORIES_PER_HOUR_PATTERN = re.compile(
    r"(\d+)\s*/\s*(\d+)"
)

CALORIES_RPM_PATTERN = re.compile(
    r"(\d+)\s*/\s*(\d+)"
)

LABELED_CALORIES_RPM_PATTERN = re.compile(
    r"Rd\s*\d+\s*[-:]\s*"
    r"Cals?\s*(\d+)\s*,?\s*"
    r"(?:Avg\s*)?RPMs?\s*(\d+)",
    re.IGNORECASE,
)

DISTANCE_WATTS_CALORIES_PACE_HEADER_PATTERN = re.compile(
    r"\bDist(?:ance)?\s*/\s*Watts?\s*/\s*Cals?\s*/\s*Pace\b",
    re.IGNORECASE,
)
DISTANCE_WATTS_CALORIES_PACE_ROW_PATTERN = re.compile(
    r"^\s*(\d+(?:\.\d+)?)\s*/\s*(\d+)\s*/\s*(\d+)\s*/\s*"
    r"(\d{1,2}:\d{2}(?:\.\d+)?)\s*$",
    re.IGNORECASE | re.MULTILINE,
)
RPM_CALORIES_WATTS_DISTANCE_HEADER_PATTERN = re.compile(
    r"\bRPMs?\s*/\s*Cals?\s*/\s*Watts?\s*/\s*KM\b",
    re.IGNORECASE,
)
RPM_CALORIES_WATTS_DISTANCE_ROW_PATTERN = re.compile(
    r"^\s*(\d+)\s*/\s*(\d+)\s*/\s*(\d+)\s*/\s*"
    r"(\d+(?:\.\d+)?)\s*KM\s*$",
    re.IGNORECASE | re.MULTILINE,
)

CALORIES_RPM_WATTS_HEADER_PATTERN = re.compile(
    r"\bCals?\s*/\s*RPMs?\s*/\s*Watts?\b",
    re.IGNORECASE,
)

CALORIES_RPM_WATTS_ROUND_PATTERN = re.compile(
    r"^\s*(?:Rd\s*)?\d+\s*[-:]\s*"
    r"(\d+)\s*/\s*(\d+)\s*/\s*(\d+)\s*$",
    re.IGNORECASE | re.MULTILINE,
)


def _extract_three_metric_matches(
    pattern: re.Pattern[str],
    result_text: str,
) -> list[dict[str, str]]:
    intervals: list[dict[str, str]] = []

    for match in pattern.finditer(result_text):
        intervals.append(
            {
                "watts": match.group(1),
                "rpm": match.group(2),
                "calories": match.group(3),
            },
        )

    return intervals


def _extract_distance_watts_calories_pace(
    result_text: str,
) -> list[dict[str, str]]:
    if not DISTANCE_WATTS_CALORIES_PACE_HEADER_PATTERN.search(
        result_text,
    ):
        return []

    return [
        {
            "distance": match.group(1),
            "watts": match.group(2),
            "calories": match.group(3),
            "primaryMetric": match.group(4),
        }
        for match in DISTANCE_WATTS_CALORIES_PACE_ROW_PATTERN.finditer(
            result_text,
        )
    ]


def _extract_rpm_calories_watts_distance(
    result_text: str,
) -> list[dict[str, str]]:
    if not RPM_CALORIES_WATTS_DISTANCE_HEADER_PATTERN.search(
        result_text,
    ):
        return []

    return [
        {
            "rpm": match.group(1),
            "calories": match.group(2),
            "watts": match.group(3),
            "distance": str(round(float(match.group(4)) * 1000)),
        }
        for match in RPM_CALORIES_WATTS_DISTANCE_ROW_PATTERN.finditer(
            result_text,
        )
    ]


def _extract_calories_rpm_watts(
    result_text: str,
) -> list[dict[str, str]]:
    if not CALORIES_RPM_WATTS_HEADER_PATTERN.search(
        result_text,
    ):
        return []

    intervals: list[dict[str, str]] = []

    for match in CALORIES_RPM_WATTS_ROUND_PATTERN.finditer(
        result_text,
    ):
        intervals.append(
            {
                "calories": match.group(1),
                "rpm": match.group(2),
                "watts": match.group(3),
            },
        )

    return intervals


def _max_section_only(
    result_text: str,
) -> str:
    has_max_section = re.search(
        r"\bMax\b",
        result_text,
        re.IGNORECASE,
    )

    if has_max_section is None:
        return result_text

    average_section = re.search(
        r"\b(?:Avg|Average)\b",
        result_text[has_max_section.end():],
        re.IGNORECASE,
    )

    if average_section is None:
        return result_text

    split_position = (
        has_max_section.end()
        + average_section.start()
    )

    return result_text[:split_position]


def _normalize_bikeerg_pace(
    pace: str,
) -> str:
    if ":" in pace:
        return pace

    match = re.fullmatch(
        r"(\d)(\d{2}(?:\.\d+)?)",
        pace,
    )

    if match is None:
        return pace

    return (
        f"{match.group(1)}:"
        f"{match.group(2)}"
    )


def _extract_bikeerg_matches(
    result_text: str,
) -> list[dict[str, str]]:
    intervals: list[dict[str, str]] = []

    interval_text = re.split(
        r"\bAverage\b",
        result_text,
        maxsplit=1,
        flags=re.IGNORECASE,
    )[0]

    for match in BIKEERG_PATTERN.finditer(
        interval_text,
    ):
        intervals.append(
            {
                "watts": match.group(1),
                "primaryMetric": _normalize_bikeerg_pace(
                    match.group(2),
                ),
                "rpm": match.group(3),
            },
        )

    return intervals


def _extract_calories_per_hour(
    result_text: str,
) -> list[dict[str, str]]:
    if not re.search(
        r"cals/hr/cals",
        result_text,
        re.IGNORECASE,
    ):
        return []

    values = re.findall(
        CALORIES_PER_HOUR_PATTERN,
        result_text,
    )

    return [
        {
            "caloriesPerHour": calories_per_hour,
            "calories": calories,
        }
        for calories_per_hour, calories in values
    ]


def _extract_labeled_calories_rpm(
    result_text: str,
) -> list[dict[str, str]]:
    return [
        {
            "calories": match.group(1),
            "rpm": match.group(2),
        }
        for match in LABELED_CALORIES_RPM_PATTERN.finditer(
            result_text,
        )
    ]


def _extract_calories_rpm(
    result_text: str,
) -> list[dict[str, str]]:
    labeled_intervals = _extract_labeled_calories_rpm(
        result_text,
    )

    if labeled_intervals:
        return labeled_intervals

    if not re.search(
        r"cals/rpms",
        result_text,
        re.IGNORECASE,
    ):
        return []

    values = re.findall(
        CALORIES_RPM_PATTERN,
        result_text,
    )

    return [
        {
            "calories": calories,
            "rpm": rpm,
        }
        for calories, rpm in values
    ]


def _extract_calorie_sequence(
    result_text: str,
) -> list[dict[str, str]]:
    match = CALORIE_SEQUENCE_PATTERN.search(
        result_text,
    )

    if match is None:
        return []

    values = [
        value.strip()
        for value in match.group(1).split("/")
        if value.strip()
    ]

    return [
        {
            "calories": value,
        }
        for value in values
    ]


def extract_watts_rpm_calories(
    result_text: str,
) -> list[dict[str, str]]:
    structured_text = _max_section_only(
        result_text,
    )

    intervals = _extract_distance_watts_calories_pace(
        result_text,
    )
    if intervals:
        return intervals

    intervals = _extract_rpm_calories_watts_distance(
        result_text,
    )
    if intervals:
        return intervals

    intervals = _extract_calories_rpm_watts(
        result_text,
    )

    if intervals:
        return intervals

    intervals = _extract_three_metric_matches(
        STANDARD_ROUND_PATTERN,
        structured_text,
    )

    if intervals:
        return intervals

    intervals = _extract_three_metric_matches(
        MAX_ROUND_PATTERN,
        structured_text,
    )

    if intervals:
        return intervals

    intervals = _extract_bikeerg_matches(
        result_text,
    )

    if intervals:
        return intervals

    intervals = _extract_calories_per_hour(
        result_text,
    )

    if intervals:
        return intervals

    intervals = _extract_calories_rpm(
        result_text,
    )

    if intervals:
        return intervals

    return _extract_calorie_sequence(
        result_text,
    )