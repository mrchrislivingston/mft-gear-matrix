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
    r"(\d+)\s*/\s*"
    r"(\d+:\d+(?:\.\d+)?|\d{3}(?:\.\d+)?)"
    r"\s*/\s*"
    r"(\d+)"
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


def extract_watts_rpm_calories(
    result_text: str,
) -> list[dict[str, str]]:
    structured_text = _max_section_only(
        result_text,
    )

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

    return _extract_bikeerg_matches(
        result_text,
    )