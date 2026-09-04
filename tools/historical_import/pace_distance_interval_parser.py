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

DISTANCE_PACE_DASH_PATTERN = re.compile(
    r"\b(?:Rd\s*)?\d+\s*-\s*"
    r"(?P<distance>\d+(?:\.\d+)?)\s*m\s*-\s*"
    r"(?P<pace>\d{1,2}:\d{2}(?:\.\d+)?)",
    re.IGNORECASE,
)

DISTANCE_PACE_SLASH_PATTERN = re.compile(
    r"(?P<distance>\d+(?:\.\d+)?)\s*m\s*/\s*"
    r"(?P<pace>\d{1,2}:\d{2}(?:\.\d+)?)",
    re.IGNORECASE,
)

DISTANCE_PACE_TABLE_PATTERN = re.compile(
    r"(?P<distance>\d+(?:\.\d+)?)\s*m\s*,\s*"
    r"(?P<pace>\d{1,2}:\d{2}(?:\.\d+)?)"
    r"\s*min\s*/\s*mile",
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

    return f"{match.group(1)}:{match.group(2)}"


def _normalize_distance(
    value: str,
    unit: str | None,
) -> str:
    if unit:
        kilometers = float(value)
        return str(round(kilometers * 1000))

    return value


def _without_summary_lines(result_text: str) -> str:
    return "\n".join(
        line
        for line in result_text.splitlines()
        if not re.match(
            r"^\s*Total\b",
            line,
            re.IGNORECASE,
        )
    )


def _extract_distance_first(
    pattern: re.Pattern[str],
    interval_text: str,
) -> list[dict[str, str]]:
    return [
        {
            "primaryMetric": _normalize_pace(
                match.group("pace"),
            ),
            "distance": match.group("distance"),
        }
        for match in pattern.finditer(interval_text)
    ]


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

    interval_text = _without_summary_lines(
        interval_text,
    )

    intervals = _extract_distance_first(
        DISTANCE_PACE_TABLE_PATTERN,
        interval_text,
    )
    if intervals:
        return intervals

    intervals = _extract_distance_first(
        DISTANCE_PACE_DASH_PATTERN,
        interval_text,
    )
    if intervals:
        return intervals

    intervals = _extract_distance_first(
        DISTANCE_PACE_SLASH_PATTERN,
        interval_text,
    )
    if intervals:
        return intervals

    return [
        {
            "primaryMetric": _normalize_pace(
                match.group("pace"),
            ),
            "distance": _normalize_distance(
                match.group("distance"),
                match.group("unit"),
            ),
        }
        for match in PACE_DISTANCE_PATTERN.finditer(
            interval_text,
        )
    ]
