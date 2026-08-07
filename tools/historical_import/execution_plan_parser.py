from __future__ import annotations

import re
from dataclasses import dataclass


@dataclass(frozen=True)
class ExecutionPlan:
    interval_count: int
    work_duration: str


_COUNT_FIRST_PATTERN = re.compile(
    r"\b(?P<interval_count>\d+)\s*[x×]\s*"
    r"(?P<work_duration>\d{1,2}:\d{2})\b",
    re.IGNORECASE,
)

_DURATION_FIRST_PATTERN = re.compile(
    r"\b(?P<work_duration>\d{1,2}:\d{2})\s*[x×]\s*"
    r"(?P<interval_count>\d+)\b",
    re.IGNORECASE,
)

_POWER_ROUNDS_PATTERN = re.compile(
    r"\bEvery\s+\d{1,2}:\d{2}\s+for\s+"
    r"(?P<interval_count>\d+)\s+Rounds?\b",
    re.IGNORECASE,
)

_POWER_WORK_DURATION_PATTERN = re.compile(
    r"\bin\s+(?P<work_duration>:\d{2})\b",
    re.IGNORECASE,
)


def extract_execution_plan(
    programming_text: str | None,
) -> ExecutionPlan | None:
    if not programming_text:
        return None

    match = _COUNT_FIRST_PATTERN.search(
        programming_text,
    )

    if match is None:
        match = _DURATION_FIRST_PATTERN.search(
            programming_text,
        )

    if match is not None:
        return ExecutionPlan(
            interval_count=int(
                match.group("interval_count"),
            ),
            work_duration=match.group(
                "work_duration",
            ),
        )

    power_rounds_match = _POWER_ROUNDS_PATTERN.search(
        programming_text,
    )

    power_duration_match = (
        _POWER_WORK_DURATION_PATTERN.search(
            programming_text,
        )
    )

    if (
        power_rounds_match is not None
        and power_duration_match is not None
    ):
        return ExecutionPlan(
            interval_count=int(
                power_rounds_match.group(
                    "interval_count",
                ),
            ),
            work_duration=power_duration_match.group(
                "work_duration",
            ),
        )

    return None