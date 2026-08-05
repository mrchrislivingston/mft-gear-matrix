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
    r"(\d+:\d+(?:\.\d+)?)\s*/\s*"
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


def _extract_bikeerg_matches(
    result_text: str,
) -> list[dict[str, str]]:
    intervals: list[dict[str, str]] = []

    for match in BIKEERG_PATTERN.finditer(
        result_text,
    ):
        intervals.append(
            {
                "watts": match.group(1),
                "primaryMetric": match.group(2),
                "rpm": match.group(3),
            },
        )

    return intervals


def extract_watts_rpm_calories(
    result_text: str,
) -> list[dict[str, str]]:
    intervals = _extract_three_metric_matches(
        STANDARD_ROUND_PATTERN,
        result_text,
    )

    if intervals:
        return intervals

    intervals = _extract_three_metric_matches(
        MAX_ROUND_PATTERN,
        result_text,
    )

    if intervals:
        return intervals

    return _extract_bikeerg_matches(
        result_text,
    )