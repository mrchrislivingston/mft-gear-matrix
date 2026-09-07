import unittest

from classify_fitr_week import classify_gear
from garmin_workout_builder import build_mixed_gear_workout


class MixedGearTest(unittest.TestCase):
    def setUp(self):
        self.section = {
            "title": "Conditioning 3 (Bitch Work)",
            "description": (
                "Build Mixed Machine - 4th Gear\n\n"
                "AMRAP 4:00\n"
                "Ski for Meters @ 4th Gear\n"
                "Rest 2:00\n"
                "AMRAP 4:00\n"
                "C2 Bike for Meters @ 4th Gear\n"
                "Rest 2:00\n"
                "Then\n"
                "3 Rounds\n"
                "AMRAP 2:00\n"
                "Ski for Meters @ 4th Gear\n"
                "Directly into\n"
                "AMRAP 2:00\n"
                "C2 Bike for Meters @ 4th Gear\n"
                "Rest 2:00"
            ),
        }

    def test_classifies_mixed_machine_progression(self):
        result = classify_gear(self.section)

        self.assertEqual(result["status"], "CANDIDATE")
        self.assertEqual(result["type"], "MIXED_GEAR")
        self.assertEqual(result["prescription"], "G4")
        self.assertEqual(result["modality"], "Ski + C2 Bike")
        self.assertEqual(result["rounds"], 5)
        self.assertEqual(len(result["steps"]), 12)

        work_modalities = [
            step["modality"]
            for step in result["steps"]
            if step["kind"] == "work"
        ]
        self.assertEqual(
            work_modalities,
            [
                "Ski",
                "C2 Bike",
                "Ski",
                "C2 Bike",
                "Ski",
                "C2 Bike",
                "Ski",
                "C2 Bike",
            ],
        )

    def test_builds_described_garmin_steps(self):
        candidate = classify_gear(self.section)
        candidate["workout_date"] = "2026-09-12"

        workout = build_mixed_gear_workout(candidate)
        steps = workout["workoutSegments"][0]["workoutSteps"]

        self.assertEqual(
            workout["workoutName"],
            "G4 Ski + C2 Bike - 2026-09-12",
        )
        self.assertEqual(
            workout["estimatedDurationInSecs"],
            1680,
        )
        self.assertEqual(steps[0]["description"], "Ski")
        self.assertEqual(steps[2]["description"], "C2 Bike")
        self.assertEqual(steps[4]["description"], "Ski")
        self.assertEqual(steps[5]["description"], "C2 Bike")
        self.assertEqual(steps[-1]["description"], "C2 Bike")


if __name__ == "__main__":
    unittest.main()
