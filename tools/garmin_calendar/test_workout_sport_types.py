import unittest

from garmin_workout_builder import (
    build_gear_workout,
    build_power_workout,
)


class WorkoutSportTypeTest(unittest.TestCase):
    def test_run_gear_uses_running(self):
        workout = build_gear_workout(
            {
                "prescription": "G3",
                "modality": "Run",
                "workout_date": "2026-09-09",
                "rounds": 4,
                "work_seconds": 360,
                "rest_seconds": 90,
            }
        )

        self.assertEqual(
            workout["sportType"]["sportTypeKey"],
            "running",
        )
        self.assertEqual(
            workout["workoutSegments"][0]
            ["sportType"]["sportTypeKey"],
            "running",
        )

    def test_c2_bike_power_uses_cycling(self):
        workout = build_power_workout(
            {
                "prescription": "P1",
                "modality": "C2 Bike",
                "workout_date": "2026-09-09",
                "rounds": 5,
                "work_seconds": 30,
                "recovery_seconds": 150,
            }
        )

        self.assertEqual(
            workout["sportType"]["sportTypeKey"],
            "cycling",
        )

    def test_row_power_uses_cardio(self):
        workout = build_power_workout(
            {
                "prescription": "P1",
                "modality": "Row",
                "workout_date": "2026-09-08",
                "rounds": 5,
                "work_seconds": 30,
                "recovery_seconds": 150,
            }
        )

        self.assertEqual(
            workout["sportType"]["sportTypeKey"],
            "cardio_training",
        )


if __name__ == "__main__":
    unittest.main()
