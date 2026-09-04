from __future__ import annotations

import csv
import tempfile
import unittest

from datetime import datetime
from pathlib import Path

from benchmark_reader import read_benchmark_candidates


class Phase3BenchmarkReaderTests(unittest.TestCase):
    def _read(self, rows: list[list[str]]):
        with tempfile.TemporaryDirectory() as directory:
            path = Path(directory) / "Phase III 2026.csv"

            with path.open(
                "w",
                encoding="utf-8",
                newline="",
            ) as output:
                csv.writer(output).writerows(rows)

            return read_benchmark_candidates(
                input_path=path,
                year=2026,
                program_start_date=datetime(2026, 1, 5),
            )

    def test_selects_compatible_cross_column_results(self) -> None:
        candidates = self._read(
            [
                [
                    "Tues - 1/6/26 - W1D2",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "",
                    (
                        "M. A. T. T. C2 Bike Test\n"
                        "AMRAP 40 Minutes\n"
                        "Score is average Watts"
                    ),
                ],
                [
                    "Notes / Results",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "Shoot for 1:54 pace",
                    (
                        "Int 1 - 211w\n"
                        "Int 2 - 225w\n"
                        "Int 3 - 257w\n"
                        "Total Avg - 1:55.1, 230w"
                    ),
                ],
                [
                    "Wed - 1/7/26 - W1D3",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "Row Cube Test\nTotal Calories",
                ],
                [
                    "Notes / Results",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "Shoot for 1:50 pace",
                    "Total Cals - 330",
                ],
                [
                    "Fri - 1/9/26 - W1D5",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "Spiders on Mars\nMax Calorie Row",
                ],
                [
                    "Notes / Results",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "Finished the final row.\n6 cals.",
                ],
                [
                    "Sat - 1/10/26 - W1D6",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "",
                    "",
                    (
                        "Power Output Echo Bike Test\n"
                        "For Time:\n"
                        "50/40 Calorie Echo Bike"
                    ),
                ],
                [
                    "Notes / Results",
                    "",
                ],
            ],
        )

        actual = {
            candidate.benchmark_key: candidate
            for candidate in candidates
        }

        self.assertEqual(len(actual), 4)
        self.assertIn("230w", actual["matt"].result_text)
        self.assertIn(
            "Total Cals - 330",
            actual["row_cube_test"].result_text,
        )
        self.assertIn(
            "6 cals",
            actual["spiders_on_mars"].result_text,
        )
        self.assertEqual(
            actual[
                "power_output_echo_bike_test"
            ].result_status,
            "missing",
        )

    def test_ignores_generic_test_names(self) -> None:
        candidates = self._read(
            [
                [
                    "Mon - 1/5/26 - W1D1",
                    "Wall Walk Deadlift Test",
                ],
                [
                    "Notes / Results",
                    "Completed 89 reps",
                ],
                [
                    "Sat - 1/10/26 - W1D6",
                    "Thruster Chest to Bar Test",
                ],
                [
                    "Notes / Results",
                    "Completed 132 reps",
                ],
            ],
        )

        self.assertEqual(candidates, [])


if __name__ == "__main__":
    unittest.main()
