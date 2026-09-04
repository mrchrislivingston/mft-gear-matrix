from __future__ import annotations

import unittest

from benchmark_registry import find_benchmark_matches


class PowerOutputBenchmarkRegistryTests(unittest.TestCase):
    def _key_for(self, programming_text: str) -> str:
        matches = find_benchmark_matches(programming_text)

        self.assertEqual(len(matches), 1)

        return matches[0].key

    def test_recognizes_c2_bike_test(self) -> None:
        self.assertEqual(
            self._key_for(
                "Power Output Bike Test\n"
                "For Time:\n"
                "50/40 Calorie C2 Bike"
            ),
            "power_output_bike_test",
        )

    def test_recognizes_echo_bike_test(self) -> None:
        self.assertEqual(
            self._key_for(
                "Power Output Echo Bike Test\n"
                "For Time:\n"
                "50/40 Calorie Echo Bike"
            ),
            "power_output_echo_bike_test",
        )

    def test_recognizes_ski_test(self) -> None:
        self.assertEqual(
            self._key_for(
                "Power Output Ski Test\n"
                "For Time:\n"
                "50/40 Calorie Ski"
            ),
            "power_output_ski_test",
        )

    def test_recognizes_row_test(self) -> None:
        self.assertEqual(
            self._key_for(
                "Power Output Row Test\n"
                "For Time:\n"
                "50/40 Calorie Row"
            ),
            "power_output_row_test",
        )


if __name__ == "__main__":
    unittest.main()
