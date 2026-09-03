from __future__ import annotations

import re


_NUMBERED_DISTANCE_PATTERN = re.compile(
    r"(?:^|[,\n]\s*)"
    r"(?P<interval_number>\d+)\s*[-:]\s*"
    r"(?P<distance>\d{2,5})"
    r"(?=\s*(?:,|$))",
    re.MULTILINE,
)

_DISTANCE_BLOCK_PATTERN = re.compile(
    r"Distances?\s+in\s+Km.*?\n(?P<values>[0-9./\s]+)",
    re.IGNORECASE | re.DOTALL,
)

_DISTANCE_PATTERN = re.compile(r"\d+\.\d+")


def _km_to_meters(value: str) -> str:
    kilometers = float(value)
    meters = round(kilometers * 1000)
    return str(meters)


def _extract_numbered_distances(
    result_text: str,
) -> list[dict[str, str]]:
    matches = list(
        _NUMBERED_DISTANCE_PATTERN.finditer(result_text),
    )

    if len(matches) < 2:
        return []

    interval_numbers = [
        int(match.group("interval_number"))
        for match in matches
    ]

    if interval_numbers != list(range(1, len(matches) + 1)):
        return []

    return [
        {"distance": match.group("distance")}
        for match in matches
    ]


def extract_interval_distances(
    result_text: str | None,
) -> list[dict[str, str]]:
    if not result_text:
        return []

    numbered_distances = _extract_numbered_distances(
        result_text,
    )

    if numbered_distances:
        return numbered_distances

    block_match = _DISTANCE_BLOCK_PATTERN.search(
        result_text,
    )

    if block_match is None:
        return []

    values = _DISTANCE_PATTERN.findall(
        block_match.group("values"),
    )

    return [
        {"distance": _km_to_meters(value)}
        for value in values
    ]
