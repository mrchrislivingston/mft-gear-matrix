from pathlib import Path

from models import ImportStatus
from normalizer import normalize_candidate
from reader import read_workout_candidates


INPUT_PATH = (
    Path(__file__).parent
    / "input"
    / "Chris Livingston - Remote Coaching - Phase III 2026.csv"
)


def phase_three_candidates():
    return read_workout_candidates(
        input_path=INPUT_PATH,
        year=2026,
    )


def test_resolves_zone_two_to_bikeerg() -> None:
    candidates = [
        candidate
        for candidate in phase_three_candidates()
        if candidate.program_day == "W5D4"
        and candidate.source_column == 10
    ]

    assert len(candidates) == 1
    candidate = candidates[0]

    assert candidate.prescription == "Z2"
    assert candidate.modality == "bikeErg"
    assert candidate.import_status is ImportStatus.READY

    workout = normalize_candidate(candidate)

    assert workout.duration == "00:45:00"
    assert workout.intervals[0].values["watts"] == "173"
    assert workout.intervals[0].values["heartRate"] == "126"
    assert workout.intervals[0].values["primaryMetric"] == "2:01"
    assert workout.intervals[0].values["distance"] == "22.40"


def test_splits_mixed_gear_row() -> None:
    candidates = [
        candidate
        for candidate in phase_three_candidates()
        if candidate.program_day == "W6D3"
        and candidate.source_column == 10
    ]

    assert len(candidates) == 2
    assert [candidate.gear for candidate in candidates] == [
        "G7",
        "G8",
    ]
    assert all(
        candidate.import_status is ImportStatus.READY
        for candidate in candidates
    )

    workouts = [
        normalize_candidate(candidate)
        for candidate in candidates
    ]

    assert workouts[0].execution_plan.work_duration == "2:30"
    assert workouts[0].execution_plan.interval_count == 3
    assert [
        interval.values["distance"]
        for interval in workouts[0].intervals
    ] == ["692", "703", "709"]

    assert workouts[1].execution_plan.work_duration == "1:30"
    assert workouts[1].execution_plan.interval_count == 3
    assert [
        interval.values["distance"]
        for interval in workouts[1].intervals
    ] == ["443", "454", "461"]


if __name__ == "__main__":
    test_resolves_zone_two_to_bikeerg()
    test_splits_mixed_gear_row()
    print("All Phase III Matrix candidate resolution tests passed.")
