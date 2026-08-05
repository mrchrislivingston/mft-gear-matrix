from __future__ import annotations

import re


PER_ROUND_PATTERN = re.compile(
    r"Per\s+Rd\s*-\s*([0-9:\./]+)",
    re.IGNORECASE,
)

PACE_SEQUENCE_PATTERN = re.compile(
    r"(\d+:\d+(?:\.\d+)?(?:/\d+:\d+(?:\.\d+)?){3,})",
)


def _split_paces(
    pace_text: str,
) -> list[str]:
    return [
        pace.strip()
        for pace in pace_text.split("/")
        if pace.strip()
    ]


def extract_interval_paces(
    result_text: str,
) -> list[str]:
    match = PER_ROUND_PATTERN.search(
        result_text,
    )

    if match is not None:
        return _split_paces(match.group(1))

    matches = PACE_SEQUENCE_PATTERN.findall(
        result_text,
    )

    if not matches:
        return []

    longest = max(
        matches,
        key=len,
    )

    return _split_paces(longest)