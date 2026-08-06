from __future__ import annotations

from models import (
    DateStatus,
    ImportStatus,
    ResultDetail,
    WorkoutCandidate,
    WorkoutType,
)
from metric_parser import (
    extract_average_heart_rate,
    extract_average_metrics,
    extract_average_pace,
    extract_average_watts,
    extract_duration,
)
from normalizer import normalize_candidate


def test_metric_extractors() -> None:
    bike_text = (
        "30 min avg watt - 170\n"
        "30 min avg hr - 128"
    )

    assert extract_duration(bike_text) == "00:30:00"

    assert extract_average_watts(bike_text) == {
        "watts": "170",
    }

    assert extract_average_heart_rate(bike_text) == {
        "heartRate": "128",
    }

    assert extract_average_metrics(bike_text) == {
        "watts": "170",
        "heartRate": "128",
    }

    run_text = (
        "Outdoor run. Probably a little too hot "
        "for what I imagine Gear 1 should be, "
        "but kept a 9:34/mile average."
    )

    assert extract_average_pace(run_text) == {
        "primaryMetric": "9:34",
    }


def test_zone_two_bike_workout() -> None:
    candidate = WorkoutCandidate(
        source_id="offszn1-row-8",
        source_workbook="OffSZN 1",
        source_row=8,
        source_column=2,
        date="2025-04-17",
        date_status=DateStatus.EXACT,
        workout_type=WorkoutType.ZONE,
        gear="",
        prescription="Z2",
        modality="bikeErg",
        import_status=ImportStatus.READY,
        status_reason="Single supported workout",
        result_detail=ResultDetail.WORKOUT_AVERAGE,
        garmin_lookup=False,
        programming_text="Zone 2 C2 Bike",
        result_text=(
            "30 min avg watt - 170\n"
            "30 min avg hr - 128"
        ),
    )

    workout = normalize_candidate(candidate)

    assert workout.prescription_id == "Z2"
    assert workout.duration == "00:30:00"
    assert workout.intervals[0].values == {
        "watts": "170",
        "heartRate": "128",
    }


def test_gear_one_run_workout() -> None:
    candidate = WorkoutCandidate(
        source_id="offszn1-row-51",
        source_workbook="OffSZN 1",
        source_row=51,
        source_column=2,
        date="2025-05-10",
        date_status=DateStatus.EXACT,
        workout_type=WorkoutType.GEAR,
        gear="G1",
        prescription="",
        modality="run",
        import_status=ImportStatus.READY,
        status_reason="Single supported workout",
        result_detail=ResultDetail.WORKOUT_AVERAGE,
        garmin_lookup=False,
        programming_text="Run - 1st Gear",
        result_text=(
            "Outdoor run. Probably a little too hot "
            "for what I imagine Gear 1 should be, "
            "but kept a 9:34/mile average."
        ),
    )

    workout = normalize_candidate(candidate)

    assert workout.prescription_id == "G1"
    assert workout.intervals[0].values == {
        "primaryMetric": "9:34",
    }


def test_gear_one_bike_interval_workout() -> None:
    candidate = WorkoutCandidate(
        source_id="offszn1-row-77",
        source_workbook="OffSZN 1",
        source_row=77,
        source_column=2,
        date="2025-05-24",
        date_status=DateStatus.EXACT,
        workout_type=WorkoutType.GEAR,
        gear="G1",
        prescription="",
        modality="bikeErg",
        import_status=ImportStatus.READY,
        status_reason="Single supported workout",
        result_detail=ResultDetail.INTERVAL_RESULTS,
        garmin_lookup=False,
        programming_text="BikeErg - 1st Gear",
        result_text=(
            "Definitely burned. Lowered the damper to 4.5 after Rd 1.\n"
            "Averaged out to 1:50/km\n"
            "Per Rd - 1:50.4/1:50.0/1:50.8/1:50.4"
        ),
    )

    workout = normalize_candidate(candidate)

    assert len(workout.intervals) == 4

    assert [
        interval.values["primaryMetric"]
        for interval in workout.intervals
    ] == [
        "1:50.4",
        "1:50.0",
        "1:50.8",
        "1:50.4",
    ]


def test_programming_execution_plan_overrides_default() -> None:
    candidate = WorkoutCandidate(
        source_id="offszn1-execution-plan-test",
        source_workbook="OffSZN 1",
        source_row=100,
        source_column=2,
        date="2025-05-25",
        date_status=DateStatus.EXACT,
        workout_type=WorkoutType.GEAR,
        gear="G6",
        prescription="",
        modality="bikeErg",
        import_status=ImportStatus.READY,
        status_reason="Single supported workout",
        result_detail=ResultDetail.WORKOUT_AVERAGE,
        garmin_lookup=False,
        programming_text=(
            "BikeErg - 6th Gear\n"
            "8×1:45"
        ),
        result_text="Average pace 1:42/km",
    )

    workout = normalize_candidate(candidate)

    assert workout.execution_plan.work_duration == "1:45"
    assert workout.execution_plan.interval_count == 8


def test_power_echo_structured_intervals() -> None:
    candidate = WorkoutCandidate(
        source_id="offszn1-row-49",
        source_workbook="OffSZN 1",
        source_row=49,
        source_column=2,
        date="2025-05-09",
        date_status=DateStatus.EXACT,
        workout_type=WorkoutType.POWER,
        gear="",
        prescription="P2",
        modality="echo",
        import_status=ImportStatus.READY,
        status_reason="Single supported workout",
        result_detail=ResultDetail.MIXED,
        garmin_lookup=False,
        programming_text="Echo Bike P2",
        result_text=(
            "Avg Watts/Avg RPM/Cals\n"
            "Rd1 - 691/87/18, "
            "Rd2 - 683/87/20, "
            "Rd3 - 934/96/20, "
            "Rd4 - 871/94/19"
        ),
    )

    workout = normalize_candidate(candidate)

    assert workout.prescription_id == "P2"
    assert workout.modality == "echo"

    assert len(workout.intervals) == 4

    assert workout.intervals[0].values == {
        "watts": "691",
        "rpm": "87",
        "calories": "18",
    }

    assert workout.intervals[1].values == {
        "watts": "683",
        "rpm": "87",
        "calories": "20",
    }

    assert workout.intervals[2].values == {
        "watts": "934",
        "rpm": "96",
        "calories": "20",
    }

    assert workout.intervals[3].values == {
        "watts": "871",
        "rpm": "94",
        "calories": "19",
    }


def main() -> None:
    test_metric_extractors()
    test_zone_two_bike_workout()
    test_gear_one_run_workout()
    test_gear_one_bike_interval_workout()
    test_programming_execution_plan_overrides_default()
    test_power_echo_structured_intervals()

    print("All normalizer tests passed.")


if __name__ == "__main__":
    main()