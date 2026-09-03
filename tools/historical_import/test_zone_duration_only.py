from models import (
    DateStatus,
    ImportStatus,
    ResultDetail,
    WorkoutCandidate,
    WorkoutType,
)
from normalizer import normalize_candidate


def main() -> None:
    candidate = WorkoutCandidate(
        source_id="phase2-duration-only-zone",
        source_workbook="Phase II 2025_2026",
        source_row=85,
        source_column=10,
        date="2025-12-18",
        date_status=DateStatus.EXACT,
        workout_type=WorkoutType.ZONE,
        gear="",
        prescription="Z2",
        modality="row",
        import_status=ImportStatus.READY,
        status_reason="Single supported workout",
        result_detail=ResultDetail.RESULT_TEXT_ONLY,
        garmin_lookup=False,
        programming_text="Zone 2 - Row",
        result_text=(
            "No clue at all. PM5 kept messing up on me. "
            "Just rowed with HR below 132 for 50 min."
        ),
    )

    workout = normalize_candidate(candidate)

    assert workout.duration == "00:50:00"
    assert len(workout.intervals) == 1
    assert workout.intervals[0].values == {}
    assert workout.notes == candidate.result_text

    print("Zone duration-only test passed.")


if __name__ == "__main__":
    main()
