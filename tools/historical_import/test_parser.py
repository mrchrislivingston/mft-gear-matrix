from __future__ import annotations

from models import ImportStatus, ResultDetail, WorkoutType
from parser import (
    classify_candidate,
    detect_gears,
    detect_modalities,
    detect_power_prescriptions,
    detect_result_detail,
    detect_workout_type,
    detect_zone_prescriptions,
    is_relevant_workout,
)


def main() -> None:
    assert detect_gears("Run - 5th Gear") == [5]
    assert detect_gears("G4 into G5") == [4, 5]

    assert detect_power_prescriptions(
        "P2 Echo Bike",
    ) == [2]

    assert detect_power_prescriptions(
        (
            "Max Calorie C2 Bike in :20 @ P2\n"
            "Use P3 session from last week for comparison."
        ),
    ) == [2]

    assert detect_power_prescriptions(
        (
            "Max Calorie C2 Bike in :15 @ P1\n"
            "Goal is faster than P2."
        ),
    ) == [1]

    assert detect_zone_prescriptions(
        "Zone 2 C2 Bike",
    ) == [2]

    assert detect_modalities(
        "Run and Row",
    ) == ["run", "row"]

    assert detect_modalities(
        "C2 Bike",
    ) == ["bikeErg"]

    assert detect_modalities(
        "Bike 45:00 w/ Heart Rate",
    ) == ["bikeErg"]

    assert detect_modalities(
        (
            "Again, can be swapped into a C2 Bike piece\n\n"
            "Aerobic - Run\n\n"
            "AMRAP 4:00 x 5\n"
            "Run for Meters @ 3rd Gear"
        ),
    ) == ["run"]

    assert detect_modalities(
        (
            "Zone 2 - C2 Bike or Run\n\n"
            "15:00 Zone 2 Warm Up\n"
            "55:00 C2 Bike @ Zone 2\n"
            "15:00 Zone 2 Cool Down"
        ),
    ) == ["bikeErg"]

    assert detect_workout_type(
        "Run - 5th Gear",
    ) is WorkoutType.GEAR

    assert detect_workout_type(
        "P3 SkiErg",
    ) is WorkoutType.POWER

    assert detect_workout_type(
        "Zone 2 Run",
    ) is WorkoutType.ZONE

    assert detect_result_detail(
        "",
    ) is ResultDetail.NONE

    assert detect_result_detail(
        "Average pace 7:35",
    ) is ResultDetail.WORKOUT_AVERAGE

    assert detect_result_detail(
        "Round 1: 7:40\nRound 2: 7:35",
    ) is ResultDetail.INTERVAL_RESULTS

    assert detect_result_detail(
        "Average 7:35\nRound 1: 7:40",
    ) is ResultDetail.MIXED

    assert is_relevant_workout(
        "Zone 2 Run",
    )

    assert not is_relevant_workout(
        "Back Squat 5 x 5",
    )

    status, reason = classify_candidate(
        programming_text="Run - 5th Gear",
        result_text="Average pace 7:35",
    )
    assert status is ImportStatus.READY
    assert reason == "Single supported workout"

    status, reason = classify_candidate(
        programming_text="G4 into G5 Run",
        result_text="Completed",
    )
    assert status is ImportStatus.TBD_LATER
    assert reason == "Mixed-gear workout"

    status, reason = classify_candidate(
        programming_text="Zone 2 Run and Row",
        result_text="Completed",
    )
    assert status is ImportStatus.TBD_LATER
    assert reason == "Mixed-modality workout"

    status, reason = classify_candidate(
        programming_text=(
            "Max Calorie Ski in :20 @ P2\n"
            "Max Calorie Ski in :10 @ P3"
        ),
        result_text="Completed",
    )
    assert status is ImportStatus.TBD_LATER
    assert reason == "Multiple power prescriptions"

    status, reason = classify_candidate(
        programming_text="P2",
        result_text="Completed",
    )
    assert status is ImportStatus.REVIEW
    assert reason == "Modality could not be detected"

    status, reason = classify_candidate(
        programming_text="P2 Echo Bike",
        result_text="Skipped because sick",
    )
    assert status is ImportStatus.SKIP
    assert reason == (
        "Result indicates workout was not completed"
    )

    status, reason = classify_candidate(
        programming_text="Zone 2 C2 Bike",
        result_text="",
    )
    assert status is ImportStatus.SKIP
    assert reason == "No result recorded"

    status, reason = classify_candidate(
        programming_text=(
            "Zone 2 - C2 Bike or Run\n\n"
            "15:00 Zone 2 Warm Up\n"
            "55:00 C2 Bike @ Zone 2\n"
            "15:00 Zone 2 Cool Down"
        ),
        result_text="55:00 Avg HR 124 Avg Watt 176",
    )
    assert status is ImportStatus.READY
    assert reason == "Single supported workout"

    status, reason = classify_candidate(
        programming_text=(
            "Zone 2\n\n"
            "Bike 45:00 w/ Heart Rate @ or below 180-age"
        ),
        result_text=(
            "Focused on higher RPMs and lower density.\n"
            "Avg Watt 158 Avg HR 122"
        ),
    )
    assert status is ImportStatus.READY
    assert reason == "Single supported workout"

    print("All parser tests passed.")


if __name__ == "__main__":
    main()