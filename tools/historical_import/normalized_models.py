from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class ExecutionPlan:
    work_duration: str
    interval_count: int


@dataclass(frozen=True)
class NormalizedInterval:
    interval_number: int
    values: dict[str, str]


@dataclass(frozen=True)
class NormalizedWorkout:
    source_id: str

    prescription_id: str
    modality: str

    date: str

    execution_plan: ExecutionPlan

    duration: str

    notes: str

    intervals: tuple[NormalizedInterval, ...]