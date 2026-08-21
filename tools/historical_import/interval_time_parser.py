from __future__ import annotations

import re


INTERVAL_TIME_PATTERN = re.compile(
    r"\b(\d+:\d+(?:\.\d+)?)\s*/",
)


def extract_interval_times(
    result_text: str,
) -> list[str]:
    """
    Extract interval completion times.

    Example:
        4:47.4/1:53.4

    Returns:
        [
            "4:47.4",
        ]
    """

    return [
        match.group(1)
        for match in INTERVAL_TIME_PATTERN.finditer(
            result_text,
        )
    ]