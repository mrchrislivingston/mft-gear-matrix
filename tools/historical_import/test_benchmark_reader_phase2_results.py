from __future__ import annotations

import csv
import tempfile
import unittest

from datetime import datetime
from pathlib import Path

from benchmark_reader import read_benchmark_candidates


class Phase2BenchmarkReaderTests(unittest.TestCase):
    def _read(
        self,
        rows: list[list[str]],
    ):
        with tempfile.TemporaryDirectory() as directory:
            input_path = Path(directory) / "Phase II 2025_2026.csv"

            with input_path.open(
                "w",
                encoding="utf-8",
                newline="",
            ) as output:
                csv.writer(output).writerows(rows)

            return read_benchmark_candidates(
                input_path=input_path,
                year=2025,
                program_start_date=datetime(2025, 11, 3),
            )

    def test_selects_matching_week_9_result(self) -> None:
        candidates = self._read(
            [
                [
                    "Mon - W1D1 - Nov 3rd",
                    "M. A. T. T. Echo Bike Test",
                ],
                [
                    "Notes / Results",
                    "Avg Watts - 288",
                ],
                [
                    "Mon - Dec 29 - W9D1",
                    "M. A. T. T. Echo Bike Test",
                ],
                [
                    "WEEK 1",
                    "Avg Watts - 288",
                ],
                [
                    "WEEK 9",
                    "Avg Watts - 302",
                ],
            ],
        )

        self.assertEqual(len(candidates), 2)
        self.assertEqual(
            candidates[0].result_text,
            "Avg Watts - 288",
        )
        self.assertEqual(
            candidates[0].result_source_row,
            2,
        )
        self.assertEqual(
            candidates[1].result_text,
            "Avg Watts - 302",
        )
        self.assertEqual(
            candidates[1].result_source_row,
            5,
        )
        self.assertEqual(
            candidates[1].date,
            "2025-12-29",
        )
        self.assertEqual(
            candidates[1].result_status,
            "selected",
        )

    def test_discards_exact_carried_forward_result(self) -> None:
        candidates = self._read(
            [
                [
                    "Mon - W1D1 - Nov 3rd",
                    "Cube Steaked",
                ],
                [
                    "Notes / Results",
                    "Total - 145",
                ],
                [
                    "Tues - Dec 30 - W9D2",
                    "Cube Steaked",
                ],
                [
                    "Old result",
                    "Total - 145",
                ],
                [
                    "Retest",
                    "Total - 185",
                ],
            ],
        )

        self.assertEqual(
            candidates[1].result_text,
            "Total - 185",
        )
        self.assertIn(
            "carried-forward",
            candidates[1].result_reason,
        )

    def test_ambiguous_results_require_review(self) -> None:
        candidates = self._read(
            [
                [
                    "Mon - W1D1 - Nov 3rd",
                    "Cube Steaked",
                ],
                [
                    "Result A",
                    "Total - 145",
                ],
                [
                    "Result B",
                    "Total - 150",
                ],
            ],
        )

        self.assertEqual(candidates[0].result_text, "")
        self.assertEqual(
            candidates[0].result_status,
            "needs_review",
        )

    def test_power_output_definition_can_have_no_result(self) -> None:
        candidates = self._read(
            [
                [
                    "Fri - W1D5",
                    (
                        "Power Output Bike Test\n\n"
                        "For Time:\n"
                        "50/40 Calorie C2 Bike"
                    ),
                ],
                [
                    "Notes / Results",
                    "",
                ],
            ],
        )

        self.assertEqual(len(candidates), 1)
        self.assertEqual(
            candidates[0].benchmark_key,
            "power_output_bike_test",
        )
        self.assertEqual(candidates[0].result_text, "")
        self.assertEqual(
            candidates[0].result_status,
            "missing",
        )
        self.assertEqual(
            candidates[0].date,
            "2025-11-07",
        )

    def test_week_9_january_date_rolls_into_2026(self) -> None:
        candidates = self._read(
            [
                [
                    "Sat - Jan 3 - W9D6",
                    "Row Mount Doom",
                ],
                [
                    "WEEK 9",
                    "Made it through 37 of the round of 39",
                ],
            ],
        )

        self.assertEqual(
            candidates[0].date,
            "2026-01-03",
        )


if __name__ == "__main__":
    unittest.main()
