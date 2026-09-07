import unittest

from bridge import parse_gear_targets
from garmin_workout_builder import (
    build_gear_workout,
    build_mixed_gear_workout,
)


class NonRunTargetTest(unittest.TestCase):
    def test_parses_generic_target_arguments(self):
        targets = parse_gear_targets(
            [
                "G1:echo:rpm=63,63",
                "G4:ski:minPer500m=1:58,1:58",
                "G4:bikeErg:minPer1000m=1:47,1:48",
            ]
        )

        self.assertEqual(
            targets[("G1", "echo")],
            {
                "metric": "rpm",
                "low": "63",
                "high": "63",
            },
        )
        self.assertEqual(
            targets[("G4", "ski")]["metric"],
            "minPer500m",
        )
        self.assertEqual(
            targets[("G4", "bikeErg")]["high"],
            "1:48",
        )

    def test_puts_echo_target_in_description_only(self):
        workout = build_gear_workout(
            {
                "prescription": "G1",
                "modality": "Echo Bike",
                "workout_date": "2026-09-11",
                "rounds": 2,
                "work_seconds": 450,
                "rest_seconds": 30,
                "gear_target": {
                    "metric": "rpm",
                    "low": "63",
                    "high": "63",
                },
            }
        )

        steps = workout["workoutSegments"][0]["workoutSteps"]
        work_steps = [
            step
            for step in steps
            if step["stepType"]["stepTypeId"] == 3
        ]

        for step in work_steps:
            self.assertEqual(
                step["targetType"]["workoutTargetTypeKey"],
                "no.target",
            )
            self.assertNotIn("targetValueOne", step)
            self.assertNotIn("targetValueTwo", step)
            self.assertEqual(
                step["description"],
                "Target 63 RPM",
            )

    def test_applies_mixed_machine_speed_targets(self):
        workout = build_mixed_gear_workout(
            {
                "prescription": "G4",
                "modality": "Ski + C2 Bike",
                "workout_date": "2026-09-12",
                "steps": [
                    {
                        "kind": "work",
                        "modality": "Ski",
                        "seconds": 120,
                        "gear_target": {
                            "metric": "minPer500m",
                            "low": "1:58",
                            "high": "1:58",
                        },
                    },
                    {
                        "kind": "recovery",
                        "modality": None,
                        "seconds": 120,
                    },
                    {
                        "kind": "work",
                        "modality": "C2 Bike",
                        "seconds": 120,
                        "gear_target": {
                            "metric": "minPer1000m",
                            "low": "1:47",
                            "high": "1:48",
                        },
                    },
                ],
            }
        )

        steps = workout["workoutSegments"][0]["workoutSteps"]

        self.assertEqual(
            steps[0]["targetType"]["workoutTargetTypeKey"],
            "no.target",
        )
        self.assertNotIn("targetValueOne", steps[0])
        self.assertNotIn("targetValueTwo", steps[0])
        self.assertEqual(
            steps[0]["description"],
            "Ski - Target 1:58 min/500m",
        )

        self.assertEqual(
            steps[1]["targetType"]["workoutTargetTypeKey"],
            "no.target",
        )

        self.assertEqual(
            steps[2]["targetType"]["workoutTargetTypeKey"],
            "speed.zone",
        )
        self.assertAlmostEqual(
            steps[2]["targetValueOne"],
            1000 / 108,
            places=5,
        )
        self.assertAlmostEqual(
            steps[2]["targetValueTwo"],
            1000 / 107,
            places=5,
        )
        self.assertEqual(
            steps[2]["description"],
            "C2 Bike - Target 1:47-1:48 min/1000m",
        )


if __name__ == "__main__":
    unittest.main()
