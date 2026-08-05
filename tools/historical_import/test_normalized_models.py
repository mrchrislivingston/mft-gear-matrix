from __future__ import annotations

from normalized_models import (
    ExecutionPlan,
    NormalizedInterval,
    NormalizedWorkout,
)


def main() -> None:
    workout = NormalizedWorkout(
        source_id="source-1",
        prescription_id="G5",
        modality="bikeErg",
        date="2025-04-18",
        execution_plan=ExecutionPlan(
            work_duration="4:00",
            interval_count=4,
        ),
        duration="",
        notes="Sample workout",
        intervals=(
            NormalizedInterval(
                interval_number=1,
                values={
                    "primaryMetric": "1:49.5",
                },
            ),
        ),
    )

    assert workout.source_id == "source-1"
    assert workout.prescription_id == "G5"
    assert workout.modality == "bikeErg"
    assert workout.date == "2025-04-18"

    assert workout.execution_plan.work_duration == "4:00"
    assert workout.execution_plan.interval_count == 4

    assert workout.notes == "Sample workout"

    assert workout.intervals[0].interval_number == 1
    assert (
        workout.intervals[0]
        .values["primaryMetric"]
        == "1:49.5"
    )

    print(
        "All normalized model tests passed."
    )


if __name__ == "__main__":
    main()