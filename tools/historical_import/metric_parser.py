from __future__ import annotations

import re


DURATION_PATTERN = re.compile(
    r"\b(\d{1,3})\s*(?:min|minutes?)\b",
    re.IGNORECASE,
)

AVERAGE_WATTS_PATTERN = re.compile(
    r"\b(?:avg|average)\s+"
    r"(?:watt|watts|power)\s*[-:]?\s*(\d+(?:\.\d+)?)\b",
    re.IGNORECASE,
)

AVERAGE_HEART_RATE_PATTERN = re.compile(
    r"\b(?:avg|average)\s+"
    r"(?:hr|heart\s*rate)\s*[-:]?\s*(\d+(?:\.\d+)?)\b",
    re.IGNORECASE,
)

AVERAGE_PACE_PATTERN = re.compile(
    r"\b(?:avg|average)\s+pace\s*[-:]?\s*"
    r"(\d+:\d+(?:\.\d+)?)",
    re.IGNORECASE,
)

PACE_PER_MILE_PATTERN = re.compile(
    r"\b(\d+:\d+)\s*/\s*mile\s+average\b",
    re.IGNORECASE,
)

PACE_AVG_SUFFIX_PATTERN = re.compile(
    r"\b(\d+:\d+(?:\.\d+)?)\s+avg\b",
    re.IGNORECASE,
)

ACTUAL_RUN_PATTERN = re.compile(
    r"Actual\s*-\s*"
    r"(\d+:\d+)"
    r"\s*pace\s*/\s*"
    r"([0-9.]+)"
    r"\s*miles?",
    re.IGNORECASE,
)


def extract_duration(
    result_text: str,
) -> str:
    match = DURATION_PATTERN.search(
        result_text,
    )

    if match is None:
        return ""

    minutes = int(match.group(1))
    hours, remaining_minutes = divmod(
        minutes,
        60,
    )

    return (
        f"{hours:02d}:"
        f"{remaining_minutes:02d}:00"
    )


def extract_average_watts(
    result_text: str,
) -> dict[str, str]:
    match = AVERAGE_WATTS_PATTERN.search(
        result_text,
    )

    if match is None:
        return {}

    return {
        "watts": match.group(1),
    }


def extract_average_heart_rate(
    result_text: str,
) -> dict[str, str]:
    match = (
        AVERAGE_HEART_RATE_PATTERN.search(
            result_text,
        )
    )

    if match is None:
        return {}

    return {
        "heartRate": match.group(1),
    }


def extract_actual_run(
    result_text: str,
) -> dict[str, str]:
    match = ACTUAL_RUN_PATTERN.search(
        result_text,
    )

    if match is None:
        return {}

    return {
        "primaryMetric": match.group(1),
        "distance": match.group(2),
    }


def extract_average_pace(
    result_text: str,
) -> dict[str, str]:
    actual = extract_actual_run(
        result_text,
    )

    if actual:
        return actual

    for pattern in (
        AVERAGE_PACE_PATTERN,
        PACE_PER_MILE_PATTERN,
        PACE_AVG_SUFFIX_PATTERN,
    ):
        match = pattern.search(
            result_text,
        )

        if match is not None:
            return {
                "primaryMetric": match.group(1),
            }

    return {}


def extract_average_metrics(
    result_text: str,
) -> dict[str, str]:
    values: dict[str, str] = {}

    for extractor in (
        extract_average_watts,
        extract_average_heart_rate,
        extract_average_pace,
    ):
        values.update(
            extractor(result_text),
        )

    return values