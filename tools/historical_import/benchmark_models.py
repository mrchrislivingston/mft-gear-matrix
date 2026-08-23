from __future__ import annotations

from dataclasses import dataclass


@dataclass(frozen=True)
class NormalizedBenchmarkAttempt:
    benchmark_id: str
    date: str
    score: str
    source_workbook: str
    program_day: str
    details: str = ""
    notes: str = ""
