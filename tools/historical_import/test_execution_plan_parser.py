from __future__ import annotations

from execution_plan_parser import extract_execution_plan


def test_multiplication_symbol_format() -> None:
    plan = extract_execution_plan(
        "BikeErg - 6th Gear\n8×1:45"
    )

    assert plan is not None
    assert plan.interval_count == 8
    assert plan.work_duration == "1:45"


def test_lowercase_x_format() -> None:
    plan = extract_execution_plan(
        "Run - 6th Gear\n4x3:30"
    )

    assert plan is not None
    assert plan.interval_count == 4
    assert plan.work_duration == "3:30"


def test_uppercase_x_with_spaces() -> None:
    plan = extract_execution_plan(
        "SkiErg - 5th Gear\n4 X 3:30"
    )

    assert plan is not None
    assert plan.interval_count == 4
    assert plan.work_duration == "3:30"


def test_duration_first_format() -> None:
    plan = extract_execution_plan(
        """Build Bike

AMRAP 1:45 x 8
C2 Bike for Meters @ 6th Gear
Rest 1:45
"""
    )

    assert plan is not None
    assert plan.interval_count == 8
    assert plan.work_duration == "1:45"


def test_multiple_lines_uses_first_execution_plan() -> None:
    plan = extract_execution_plan(
        """BikeErg - 6th Gear

8×1:45

Maintain pace.

Then cooldown 10:00.
"""
    )

    assert plan is not None
    assert plan.interval_count == 8
    assert plan.work_duration == "1:45"


def test_power_rounds_format() -> None:
    plan = extract_execution_plan(
        """Power - Air Bike

Every 5:00 for 3 Rounds
Max Calorie Air Bike in :25 @ P3
Recover in Remaining Time
"""
    )

    assert plan is not None
    assert plan.interval_count == 3
    assert plan.work_duration == ":25"


def test_power_p1_format() -> None:
    plan = extract_execution_plan(
        """Power - Air Bike

Every 3:00 for 5 Rounds
Max Calorie Air Bike in :15 @ P1
"""
    )

    assert plan is not None
    assert plan.interval_count == 5
    assert plan.work_duration == ":15"


def test_power_p2_format() -> None:
    plan = extract_execution_plan(
        """Power - Air Bike

Every 4:00 for 4 Rounds
Max Calorie Air Bike in :20 @ P2
"""
    )

    assert plan is not None
    assert plan.interval_count == 4
    assert plan.work_duration == ":20"


def test_unstructured_programming_returns_none() -> None:
    plan = extract_execution_plan(
        "BikeErg - 1st Gear"
    )

    assert plan is None


def main() -> None:
    test_multiplication_symbol_format()
    test_lowercase_x_format()
    test_uppercase_x_with_spaces()
    test_duration_first_format()
    test_multiple_lines_uses_first_execution_plan()
    test_power_rounds_format()
    test_power_p1_format()
    test_power_p2_format()
    test_unstructured_programming_returns_none()

    print("All execution plan parser tests passed.")


if __name__ == "__main__":
    main()