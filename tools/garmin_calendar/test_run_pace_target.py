import unittest

from bridge import parse_run_pace_targets
from garmin_workout_builder import (
    build_gear_workout,
    pace_to_meters_per_second,
)


class RunPaceTargetTest(unittest.TestCase):
    def test_converts_minutes_per_mile_to_speed(self):
        self.assertAlmostEqual(
            pace_to_meters_per_second("7:30"),
            3.57632,
            places=5,
        )
        self.assertAlmostEqual(
            pace_to_meters_per_second("7:45"),
            3.4609548,
            places=5,
        )

    def test_parses_bridge_target_argument(self):
        targets = parse_run_pace_targets(
            ["G3=7:30,7:45"]
        )

        self.assertEqual(
            targets["G3"],
            {
                "metric": "minPerMile",
                "low": "7:30",
                "high": "7:45",
            },
        )

    def test_applies_pace_to_each_run_work_step(self):
        workout = build_gear_workout(
            {
                "prescription": "G3",
                "modality": "Run",
                "workout_date": "2026-09-09",
                "rounds": 4,
                "work_seconds": 360,
                "rest_seconds": 90,
                "pace_low": "7:30",
                "pace_high": "7:45",
            }
        )

        steps = workout["workoutSegments"][0][
            "workoutSteps"
        ]
        work_steps = [
            step
            for step in steps
            if step["stepType"]["stepTypeId"] == 3
        ]
        recovery_steps = [
            step
            for step in steps
            if step["stepType"]["stepTypeId"] == 4
        ]

        self.assertEqual(len(work_steps), 4)
        self.assertEqual(len(recovery_steps), 3)

        for step in work_steps:
            self.assertEqual(
                step["targetType"]["workoutTargetTypeKey"],
                "pace.zone",
            )
            self.assertAlmostEqual(
                step["targetValueOne"],
                3.57632,
                places=5,
            )
            self.assertAlmostEqual(
                step["targetValueTwo"],
                3.4609548,
                places=5,
            )

        for step in recovery_steps:
            self.assertEqual(
                step["targetType"]["workoutTargetTypeKey"],
                "no.target",
            )


if __name__ == "__main__":
    unittest.main()
