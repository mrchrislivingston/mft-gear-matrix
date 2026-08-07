from __future__ import annotations

from dataclasses import asdict, dataclass
from enum import Enum


class ImportStatus(str, Enum):
    READY = "READY"
    REVIEW = "REVIEW"
    TBD_LATER = "TBD_LATER"
    SKIP = "SKIP"


class WorkoutType(str, Enum):
    GEAR = "gear"
    POWER = "power"
    ZONE = "zone"
    UNKNOWN = "unknown"


class ResultDetail(str, Enum):
    NONE = "none"
    WORKOUT_AVERAGE = "workout_average"
    INTERVAL_RESULTS = "interval_results"
    MIXED = "mixed"
    RESULT_TEXT_ONLY = "result_text_only"


class DateStatus(str, Enum):
    EXACT = "exact"
    INFERRED = "inferred"
    UNRESOLVED = "unresolved"


@dataclass(frozen=True)
class WorkoutCandidate:
    source_id: str
    source_workbook: str
    source_row: int
    source_column: int

    date: str
    date_status: DateStatus

    workout_type: WorkoutType
    gear: str
    prescription: str
    modality: str

    import_status: ImportStatus
    status_reason: str

    result_detail: ResultDetail
    garmin_lookup: bool

    programming_text: str
    result_text: str

    review_decision: str = ""
    review_notes: str = ""

    # Original program-position identifier from the source
    # workbook, for example W5D2.
    program_day: str = ""

    def to_dict(self) -> dict[str, object]:
        data = asdict(self)

        data["date_status"] = self.date_status.value
        data["workout_type"] = self.workout_type.value
        data["import_status"] = self.import_status.value
        data["result_detail"] = self.result_detail.value
        data["garmin_lookup"] = (
            "yes" if self.garmin_lookup else ""
        )

        return data