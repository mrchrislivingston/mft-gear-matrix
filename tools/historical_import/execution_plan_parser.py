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

    if match is None:
        return None

    return ExecutionPlan(
        interval_count=int(
            match.group("interval_count"),
        ),
        work_duration=match.group(
            "work_duration",
        ),
    )