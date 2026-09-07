import unittest

from classify_fitr_week import classify_power


class ClassifyPowerTest(unittest.TestCase):
    def test_parses_p1_calorie_row_without_rounds_word(self):
        section = {
            "title": "Conditioning 3 (Bitch Work)",
            "description": (
                "Power Row - P1\n\n"
                "Every 3:00 x 5\n"
                "Calorie Row in :30 @ P1\n\n"
                "P1 = Full send."
            ),
        }

        result = classify_power(section)

        self.assertEqual(result["status"], "CANDIDATE")
        self.assertEqual(result["type"], "POWER")
        self.assertEqual(result["prescription"], "P1")
        self.assertEqual(result["modality"], "Row")
        self.assertEqual(result["rounds"], 5)
        self.assertEqual(result["work_seconds"], 30)
        self.assertEqual(result["recovery_seconds"], 150)


if __name__ == "__main__":
    unittest.main()
