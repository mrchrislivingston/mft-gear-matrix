from __future__ import annotations

from dataclasses import asdict, dataclass

from models import DateStatus


@dataclass(frozen=True)
class BenchmarkCandidate:
    source_id: str
    source_workbook: str
    source_row: int
    source_column: int
    program_day: str
    date: str
    date_status: DateStatus
    benchmark_key: str
    benchmark_name: str
    modality: str
    programming_text: str
    result_text: str

    def to_dict(self) -> dict[str, object]:
        data = asdict(self)
        data["date_status"] = self.date_status.value
        return data


@dataclass(frozen=True)
class NormalizedBenchmarkAttempt:
    benchmark_id: str
    date: str
    score: str
    source_workbook: str
    program_day: str
    details: str = ""
    notes: str = ""