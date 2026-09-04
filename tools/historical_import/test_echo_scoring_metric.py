from models import (
    DateStatus,
    ImportStatus,
    ResultDetail,
    WorkoutCandidate,
    WorkoutType,
)
from normalizer import normalize_candidate


def candidate(
    programming_text: str,
    result_text: str,
) -> WorkoutCandidate:
    return WorkoutCandidate(
        source_id="phase3-test",
        source_workbook="Phase III 2026",
        source_row=1,
        source_column=10,
        date="2026-02-04",
        date_status=DateStatus.EXACT,
        workout_type=WorkoutType.GEAR,
        gear="G7",
        prescription="",
        modality="echo",
        import_status=ImportStatus.REVIEW,
        status_reason="Partial workout",
        result_detail=ResultDetail.INTERVAL_RESULTS,
        garmin_lookup=False,
        programming_text=programming_text,
        result_text=result_text,
        program_day="W5D3",
    )


def test_echo_for_meters_scores_distance() -> None:
    workout = normalize_candidate(
        candidate(
            programming_text=(
                "Build Echo - 7th Gear\n"
                "AMRAP 2:30 x 5\n"
                "Echo Bike for Meters @ 7th Gear"
            ),
            result_text=(
                "RPM/Cals/Watts/KM\n"
                "73/54/434/1.84KM\n"
                "74/56/451/1.86KM\n"
                "74/56/451/1.86KM"
            ),
        ),
    )

    assert workout.scoring_metric == "distance"
    assert len(workout.intervals) == 3
    assert workout.intervals[0].values == {
        "rpm": "73",
        "calories": "54",
        "watts": "434",
        "distance": "1840",
    }


def test_echo_defaults_to_calorie_scoring() -> None:
    workout = normalize_candidate(
        candidate(
            programming_text="Echo Bike P2",
            result_text=(
                "Avg Watts/Avg RPM/Cals\n"
                "Rd1 - 691/87/18, Rd2 - 683/87/20"
            ),
        ),
    )

    assert workout.scoring_metric == "calories"
    assert workout.intervals[0].values["rpm"] == "87"


if __name__ == "__main__":
    test_echo_for_meters_scores_distance()
    test_echo_defaults_to_calorie_scoring()
    print("All Echo scoring metric tests passed.")
