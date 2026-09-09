import unittest

from garmin_workout_builder import build_z2_steps


def target_ranges(age):
    steps = build_z2_steps(
        {
            "work_seconds": 2700,
        },
        age,
    )

    return [
        (
            step["targetValueOne"],
            step["targetValueTwo"],
        )
        for step in steps
    ]


class Z2TargetTest(unittest.TestCase):
    def test_builds_age_28_heart_rate_progression(self):
        self.assertEqual(
            target_ranges(28),
            [
                (100, 132),
                (132, 137),
                (137, 142),
                (142, 152),
                (137, 142),
                (132, 137),
                (100, 132),
            ],
        )

    def test_builds_age_50_heart_rate_progression(self):
        self.assertEqual(
            target_ranges(50),
            [
                (100, 110),
                (110, 115),
                (115, 120),
                (120, 130),
                (115, 120),
                (110, 115),
                (100, 110),
            ],
        )


if __name__ == "__main__":
    unittest.main()
