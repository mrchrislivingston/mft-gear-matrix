from __future__ import annotations

import unittest

from pathlib import Path

from benchmark_normalizer import normalize_benchmark_candidates
from benchmark_reader import read_benchmark_candidates


class Phase3BenchmarkNormalizerTests(unittest.TestCase):
    def test_normalizes_recorded_phase3_attempts(self) -> None:
        input_path = (
            Path(__file__).resolve().parent
            / "input"
            / "Chris Livingston - Remote Coaching - Phase III 2026.csv"
        )

        candidates = read_benchmark_candidates(
            input_path=input_path,
            year=2026,
        )
        attempts = normalize_benchmark_candidates(candidates)

        actual = {
            attempt.benchmark_id: (
                attempt.date,
                attempt.score,
            )
            for attempt in attempts
        }

        self.assertEqual(
            actual,
            {
                "matt_c2_bike": (
                    "2026-01-06",
                    "230",
                ),
                "row_cube_test": (
                    "2026-01-07",
                    "330",
                ),
                "spiders_on_mars": (
                    "2026-01-09",
                    "6",
                ),
            },
        )

    def test_preserves_row_cube_round_details(self) -> None:
        input_path = (
            Path(__file__).resolve().parent
            / "input"
            / "Chris Livingston - Remote Coaching - Phase III 2026.csv"
        )

        attempts = normalize_benchmark_candidates(
            read_benchmark_candidates(
                input_path=input_path,
                year=2026,
            ),
        )

        row_cube = next(
            attempt
            for attempt in attempts
            if attempt.benchmark_id == "row_cube_test"
        )

        self.assertIn(
            "Rd1 - 1:47.4/1117/84/282",
            row_cube.details,
        )
        self.assertIn(
            "Rd4 - 1:49.1/1099/81/269",
            row_cube.details,
        )


if __name__ == "__main__":
    unittest.main()
