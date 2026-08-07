from __future__ import annotations

import re


PACE_DISTANCE_PATTERN = re.compile(
    r"(?P<pace>\d{1,2}:?\d{2}(?:\.\d+)?)"
    r"\s*/\s*"
    r"(?P<distance>\.?\d+(?:\.\d+)?)"
    r"(?!:)"
    r"\s*(?P<unit>KM)?",
    re.IGNORECASE,
)


def _normalize_pace(value: str) -> str:
    if ":" in value:
        return value

    match = re.fullmatch(
        r"(\d)(\d{2}(?:\.\d+)?)",
        value,
    )

    if match is None:
        return value

    return (
        f"{match.group(1)}:"
        f"{match.group(2)}"
    )


def _normalize_distance(
    value: str,
    unit: str | None,
) -> str:
    if unit:
        kilometers = float(value)
        return str(round(kilometers * 1000))

    return value


def extract_pace_distance_intervals(
    result_text: str | None,
) -> list[dict[str, str]]:
    if not result_text:
        return []

    interval_text = re.split(
        r"\b(?:Avg|Average)\b",
        result_text,
        maxsplit=1,
        flags=re.IGNORECASE,
    )[0]

    intervals: list[dict[str, str]] = []

    for match in PACE_DISTANCE_PATTERN.finditer(
        interval_text,
    ):
        intervals.append(
            {
                "primaryMetric": _normalize_pace(
                    match.group("pace"),
                ),
                "distance": _normalize_distance(
                    match.group("distance"),
                    match.group("unit"),
                ),
            },
        )

    return intervals
