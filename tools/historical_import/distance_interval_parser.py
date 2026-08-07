from __future__ import annotations

import re


_DISTANCE_BLOCK_PATTERN = re.compile(
    r"Distances?\s+in\s+Km.*?\n(?P<values>[0-9./\s]+)",
    re.IGNORECASE | re.DOTALL,
)

_DISTANCE_PATTERN = re.compile(
    r"\d+\.\d+"
)


def _km_to_meters(value: str) -> str:
    kilometers = float(value)
    meters = round(kilometers * 1000)

    return str(meters)


def extract_interval_distances(
    result_text: str | None,
) -> list[dict[str, str]]:
    if not result_text:
        return []

    block_match = _DISTANCE_BLOCK_PATTERN.search(
        result_text,
    )

    if block_match is None:
        return []

    values = _DISTANCE_PATTERN.findall(
        block_match.group("values"),
    )

    return [
        {
            "distance": _km_to_meters(value),
        }
        for value in values
    ]