def timed_step(order, step_type, seconds):
    return {
        "type": "ExecutableStepDTO",
        "stepOrder": order,
        "stepType": {
            "stepTypeId": step_type,
        },
        "endCondition": {
            "conditionTypeId": 2,
            "conditionTypeKey": "time",
        },
        "endConditionValue": seconds,
        "targetType": {
            "workoutTargetTypeId": 1,
            "workoutTargetTypeKey": "no.target",
        },
    }


def hr_step(order, step_type, seconds, low=None, high=None):
    step = timed_step(order, step_type, seconds)

    if low is not None or high is not None:
        step["targetType"] = {
            "workoutTargetTypeId": 4,
            "workoutTargetTypeKey": "heart.rate.zone",
        }

        if low is not None:
            step["targetValueOne"] = low

        if high is not None:
            step["targetValueTwo"] = high

    return step




def sport_type_for_modality(modality):
    normalized = modality.lower()

    if "run" in normalized:
        return {
            "sportTypeId": 1,
            "sportTypeKey": "running",
        }

    if "c2 bike" in normalized or normalized == "bike":
        return {
            "sportTypeId": 2,
            "sportTypeKey": "cycling",
        }

    return {
        "sportTypeId": 6,
        "sportTypeKey": "cardio_training",
    }

def build_matt_row_workout(workout_date):
    return {
        "workoutName": "M.A.T.T. Row Test",
        "estimatedDurationInSecs": 2400,
        "sportType": {
            "sportTypeId": 6,
            "sportTypeKey": "fitness_equipment",
        },
        "workoutSegments": [
            {
                "segmentOrder": 1,
                "sportType": {
                    "sportTypeId": 6,
                    "sportTypeKey": "fitness_equipment",
                },
                "workoutSteps": [
                    timed_step(1, 3, 600.0),
                    timed_step(2, 3, 1200.0),
                    timed_step(3, 3, 600.0),
                ],
            }
        ],
    }


def build_z2_steps(candidate, age):
    steps = []
    order = 1

    hr_160 = 160 - age
    hr_165 = 165 - age
    hr_170 = 170 - age
    hr_180 = 180 - age

    # Warm up: build progressively toward 160/165/170 - age.
    steps.append(hr_step(order, 1, 300, low=100, high=hr_160))
    order += 1

    steps.append(hr_step(order, 1, 300, low=hr_160, high=hr_165))
    order += 1

    steps.append(hr_step(order, 1, 300, low=hr_165, high=hr_170))
    order += 1

    # Working window: 170 - age through 180 - age.
    steps.append(
        hr_step(
            order,
            3,
            candidate["work_seconds"],
            low=hr_170,
            high=hr_180,
        )
    )
    order += 1

    # Cool down: reverse the warm-up progression.
    steps.append(hr_step(order, 2, 300, low=hr_165, high=hr_170))
    order += 1

    steps.append(hr_step(order, 2, 300, low=hr_160, high=hr_165))
    order += 1

    steps.append(hr_step(order, 2, 300, low=100, high=hr_160))

    return steps



def build_z2_workout(candidate, age):
    steps = build_z2_steps(candidate, age)

    modality = candidate["modality"].lower()

    if "run" in modality:
        sport_type = {
            "sportTypeId": 1,
            "sportTypeKey": "running",
        }
    elif "bike" in modality:
        sport_type = {
            "sportTypeId": 2,
            "sportTypeKey": "cycling",
        }
    else:
        sport_type = {
            "sportTypeId": 6,
            "sportTypeKey": "cardio_training",
        }

    return {
        "workoutName": f"Z2 {candidate['modality']} - {candidate['workout_date']}",
        "sportType": sport_type,
        "workoutSegments": [
            {
                "segmentOrder": 1,
                "sportType": sport_type,
                "workoutSteps": steps,
            }
        ],
    }



def pace_to_speed(pace, distance_meters):
    parts = pace.strip().split(":")

    if len(parts) != 2:
        raise ValueError(f"Invalid pace: {pace}")

    minutes = int(parts[0])
    seconds = float(parts[1])
    total_seconds = minutes * 60 + seconds

    if total_seconds <= 0:
        raise ValueError(f"Invalid pace: {pace}")

    return distance_meters / total_seconds


def pace_to_meters_per_second(pace):
    return pace_to_speed(pace, 1609.344)


def apply_run_pace_target(step, low_pace, high_pace):
    speeds = [
        pace_to_meters_per_second(low_pace),
        pace_to_meters_per_second(high_pace),
    ]

    step["targetType"] = {
        "workoutTargetTypeId": 6,
        "workoutTargetTypeKey": "pace.zone",
    }
    step["targetValueOne"] = max(speeds)
    step["targetValueTwo"] = min(speeds)
    return step


def format_gear_target(target):
    low = target["low"]
    high = target["high"]
    value = low if low == high else f"{low}-{high}"

    units = {
        "minPerMile": "min/mile",
        "minPer500m": "min/500m",
        "minPer1000m": "min/1000m",
        "rpm": "RPM",
    }

    return f"Target {value} {units[target['metric']]}"


def modality_uses_structured_target(modality):
    normalized = modality.lower()

    return (
        "run" in normalized
        or "row" in normalized
        or "bike" in normalized
    ) and "echo" not in normalized


def apply_gear_target(
    step,
    target,
    enforce=True,
):
    metric = target["metric"]
    low = target["low"]
    high = target["high"]

    step["description"] = format_gear_target(target)

    if not enforce:
        return step

    if metric == "minPerMile":
        apply_run_pace_target(step, low, high)

    elif metric in {"minPer500m", "minPer1000m"}:
        distance = 500 if metric == "minPer500m" else 1000
        speeds = [
            pace_to_speed(low, distance),
            pace_to_speed(high, distance),
        ]

        step["targetType"] = {
            "workoutTargetTypeId": 5,
            "workoutTargetTypeKey": "speed.zone",
        }
        step["targetValueOne"] = min(speeds)
        step["targetValueTwo"] = max(speeds)

    else:
        raise ValueError(
            f"Structured target is not supported for metric: {metric}"
        )

    return step


def build_gear_steps(candidate):
    steps = []
    order = 1

    for round_number in range(candidate["rounds"]):
        work_step = timed_step(
            order,
            3,
            candidate["work_seconds"],
        )

        target = candidate.get("gear_target")

        if target:
            apply_gear_target(
                work_step,
                target,
                enforce=modality_uses_structured_target(
                    candidate["modality"]
                ),
            )

        elif (
            candidate["modality"].lower() == "run"
            and candidate.get("pace_low")
            and candidate.get("pace_high")
        ):
            apply_run_pace_target(
                work_step,
                candidate["pace_low"],
                candidate["pace_high"],
            )

        steps.append(work_step)
        order += 1

        # No recovery after the final work interval.
        if round_number < candidate["rounds"] - 1:
            steps.append(
                timed_step(order, 4, candidate["rest_seconds"])
            )
            order += 1

    return steps


def build_gear_workout(candidate):
    steps = build_gear_steps(candidate)

    sport_type = sport_type_for_modality(
        candidate["modality"]
    )

    return {
        "workoutName": (
            f"{candidate['prescription']} {candidate['modality']} - {candidate['workout_date']}"
        ),
        "sportType": sport_type,
        "estimatedDurationInSecs": sum(
            step["endConditionValue"] for step in steps
        ),
        "workoutSegments": [
            {
                "segmentOrder": 1,
                "sportType": sport_type,
                "workoutSteps": steps,
            }
        ],
    }


def build_mixed_gear_workout(candidate):
    workout_steps = []

    for order, candidate_step in enumerate(
        candidate["steps"],
        start=1,
    ):
        is_work = candidate_step["kind"] == "work"
        step = timed_step(
            order,
            3 if is_work else 4,
            candidate_step["seconds"],
        )

        modality = candidate_step.get("modality") or "Recovery"
        target = candidate_step.get("gear_target")

        if is_work and target:
            apply_gear_target(
                step,
                target,
                enforce=modality_uses_structured_target(modality),
            )
            step["description"] = (
                f"{modality} - {format_gear_target(target)}"
            )
        else:
            step["description"] = modality

        workout_steps.append(step)

    sport_type = {
        "sportTypeId": 6,
        "sportTypeKey": "cardio_training",
    }

    return {
        "workoutName": (
            f"{candidate['prescription']} "
            f"{candidate['modality']} - "
            f"{candidate['workout_date']}"
        ),
        "sportType": sport_type,
        "estimatedDurationInSecs": sum(
            step["endConditionValue"]
            for step in workout_steps
        ),
        "workoutSegments": [
            {
                "segmentOrder": 1,
                "sportType": sport_type,
                "workoutSteps": workout_steps,
            }
        ],
    }


def build_power_steps(candidate):
    steps = []
    order = 1

    for round_number in range(candidate["rounds"]):
        steps.append(
            timed_step(order, 3, candidate["work_seconds"])
        )
        order += 1

        # Recovery is the remainder of the "Every X:XX" interval.
        # No recovery is needed after the final work interval.
        if (
            round_number < candidate["rounds"] - 1
            and candidate["recovery_seconds"] > 0
        ):
            steps.append(
                timed_step(order, 4, candidate["recovery_seconds"])
            )
            order += 1

    return steps


def build_power_workout(candidate):
    steps = build_power_steps(candidate)

    sport_type = sport_type_for_modality(
        candidate["modality"]
    )

    return {
        "workoutName": (
            f"{candidate['prescription']} {candidate['modality']} - {candidate['workout_date']}"
        ),
        "sportType": sport_type,
        "estimatedDurationInSecs": sum(
            step["endConditionValue"] for step in steps
        ),
        "workoutSegments": [
            {
                "segmentOrder": 1,
                "sportType": sport_type,
                "workoutSteps": steps,
            }
        ],
    }
