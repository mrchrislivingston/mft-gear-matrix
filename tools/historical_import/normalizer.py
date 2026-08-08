from __future__ import annotations

from distance_interval_parser import (
    extract_interval_distances,
)
from execution_plan_parser import extract_execution_plan
from interval_parser import (
    extract_interval_paces,
)
from metric_parser import (
    extract_average_metrics,
    extract_duration,
)
from models import WorkoutCandidate, WorkoutType
from normalized_models import (
    ExecutionPlan,
    NormalizedInterval,
    NormalizedWorkout,
)
from pace_distance_interval_parser import (
    extract_pace_distance_intervals,
)
from structured_interval_parser import (
    extract_watts_rpm_calories,
)


def _default_execution_plan(
    candidate: WorkoutCandidate,
) -> ExecutionPlan:
    if candidate.gear == "G1":
        return ExecutionPlan("15:00", 2)

    if candidate.gear == "G2":
        return ExecutionPlan("13:00", 2)

    if candidate.gear == "G3":
        return ExecutionPlan("8:00", 3)

    if candidate.gear == "G4":
        return ExecutionPlan("6:00", 3)

    if candidate.gear == "G5":
        return ExecutionPlan("4:00", 4)

    if candidate.gear == "G6":
        return ExecutionPlan("3:30", 4)

    if candidate.gear == "G7":
        return ExecutionPlan("2:30", 5)

    if candidate.gear == "G8":
        return ExecutionPlan("1:30", 7)

    return ExecutionPlan("", 1)


def normalize_candidate(
    candidate: WorkoutCandidate,
) -> NormalizedWorkout:
    if not candidate.date:
        raise ValueError(
            "Candidate requires a resolved workout date",
        )

    if candidate.workout_type is WorkoutType.ZONE:
        if candidate.prescription not in {
            "Z1",
            "Z2",
        }:
            raise ValueError(
                "Zone candidate requires a Z1 or Z2 prescription",
            )

        if candidate.modality not in {
            "bikeErg",
            "run",
            "row",
        }:
            raise ValueError(
                "Unsupported Zone modality",
            )

        duration = extract_duration(
            candidate.result_text,
        )

        if not duration:
            duration = extract_duration(
                candidate.programming_text,
            )

        if not duration:
            raise ValueError(
                "Zone workout duration could not be extracted",
            )

    elif candidate.workout_type in (
        WorkoutType.GEAR,
        WorkoutType.POWER,
    ):
        duration = ""

    else:
        raise ValueError(
            "Unsupported workout type",
        )

    parsed_execution_plan = extract_execution_plan(
        candidate.programming_text,
    )

    if parsed_execution_plan is not None:
        execution_plan = ExecutionPlan(
            work_duration=parsed_execution_plan.work_duration,
            interval_count=parsed_execution_plan.interval_count,
        )
    else:
        execution_plan = _default_execution_plan(
            candidate,
        )

    pace_distance_intervals = (
        extract_pace_distance_intervals(
            candidate.result_text,
        )
    )

    if pace_distance_intervals:
        intervals = tuple(
            NormalizedInterval(
                interval_number=index + 1,
                values=values,
            )
            for index, values in enumerate(
                pace_distance_intervals,
            )
        )

    else:
        interval_paces = extract_interval_paces(
            candidate.result_text,
        )

        if interval_paces:
            intervals = tuple(
                NormalizedInterval(
                    interval_number=index + 1,
                    values={
                        "primaryMetric": pace,
                    },
                )
                for index, pace in enumerate(
                    interval_paces,
                )
            )

        else:
            structured_intervals = (
                extract_watts_rpm_calories(
                    candidate.result_text,
                )
            )

            if structured_intervals:
                intervals = tuple(
                    NormalizedInterval(
                        interval_number=index + 1,
                        values=values,
                    )
                    for index, values in enumerate(
                        structured_intervals,
                    )
                )

            else:
                distance_intervals = (
                    extract_interval_distances(
                        candidate.result_text,
                    )
                )

                if distance_intervals:
                    intervals = tuple(
                        NormalizedInterval(
                            interval_number=index + 1,
                            values=values,
                        )
                        for index, values in enumerate(
                            distance_intervals,
                        )
                    )

                else:
                    metric_values = extract_average_metrics(
                        candidate.result_text,
                    )

                    if not metric_values:
                        raise ValueError(
                            "No supported workout metrics could be extracted",
                        )

                    intervals = (
                        NormalizedInterval(
                            interval_number=1,
                            values=metric_values,
                        ),
                    )

    return NormalizedWorkout(
        source_id=candidate.source_id,
        source_workbook=candidate.source_workbook,
        program_day=candidate.program_day,
        prescription_id=(
            candidate.gear
            or candidate.prescription
        ),
        modality=candidate.modality,
        date=candidate.date,
        execution_plan=execution_plan,
        duration=duration,
        notes=candidate.result_text,
        intervals=intervals,
    )