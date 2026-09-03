from __future__ import annotations

import csv
import tempfile
import unittest

from datetime import datetime
from pathlib import Path

from benchmark_normalizer import (
    normalize_benchmark_candidates,
)
from benchmark_reader import read_benchmark_candidates


class Phase2BenchmarkNormalizerTests(unittest.TestCase):
    def _normalize_phase2_rows(
        self,
        rows: list[list[str]],
    ):
        with tempfile.TemporaryDirectory() as directory:
            input_path = (
                Path(directory)
                / "Chris Livingston - Remote Coaching "
                "Phase II 2025_2026.csv"
            )

            with input_path.open(
                "w",
                encoding="utf-8",
                newline="",
            ) as output:
                csv.writer(output).writerows(rows)

            candidates = read_benchmark_candidates(
                input_path=input_path,
                year=2025,
                program_start_date=datetime(2025, 11, 3),
            )

            return normalize_benchmark_candidates(candidates)

    def test_normalizes_six_phase2_attempts(self) -> None:
        attempts = self._normalize_phase2_rows(
            [
                [
                    "Mon - W1D1 - Nov 3rd",
                    (
                        "M. A. T. T. Echo Bike Test\n"
                        "AMRAP 40 Minutes\n"
                        "Score is average Watts"
                    ),
                ],
                [
                    "Notes / Results",
                    (
                        "Hard effort.\n"
                        "Avg Watts - 288\n"
                        "Avg RPM - 64\n"
                        "594 cals"
                    ),
                ],
                [
                    "Tues - W1D2",
                    "Cube Steaked",
                ],
                [
                    "Notes / Results",
                    (
                        "Subbed box jumps for burpees\n"
                        "Total - 145 - 78/25/19/23"
                    ),
                ],
                [
                    "Fri - W1D5",
                    (
                        "Power Output Bike Test\n"
                        "For Time:\n"
                        "50/40 Calorie C2 Bike"
                    ),
                ],
                [
                    "Notes / Results",
                    "",
                ],
                [
                    "Sat - W1D6",
                    (
                        "Row Mount Doom\n"
                        "Every 2:00 Until Failure\n"
                        "Row 20/13 Calories\n"
                        "Add 1 Calorie Every Round"
                    ),
                ],
                [
                    "Notes / Results",
                    "Made it through 30 of the round of 38",
                ],
                [
                    "Mon - Dec 29 - W9D1",
                    (
                        "M. A. T. T. Echo Bike Test\n"
                        "AMRAP 40 Minutes\n"
                        "Score is average Watts"
                    ),
                ],
                [
                    "WEEK 1",
                    (
                        "Avg Watts - 288\n"
                        "Avg RPM - 64\n"
                        "594 cals"
                    ),
                ],
                [
                    "WEEK 9",
                    (
                        "Solid improvement.\n"
                        "Avg Watts - 302\n"
                        "Avg RPM - 65\n"
                        "Cals - 613"
                    ),
                ],
                [
                    "Tues - Dec 30 - W9D2",
                    "Cube Steaked",
                ],
                [
                    "WEEK 1",
                    "Total - 145 - 78/25/19/23",
                ],
                [
                    "WEEK 9",
                    (
                        "Better than expected!\n"
                        "Total - 185 - 102/36/21/26"
                    ),
                ],
                [
                    "Fri - Jan 2 - W9D5",
                    (
                        "Power Output Bike Test\n"
                        "For Time:\n"
                        "50/40 Calorie C2 Bike"
                    ),
                ],
                [
                    "WEEK 1",
                    "",
                ],
                [
                    "WEEK 9",
                    "",
                ],
                [
                    "Sat - Jan 3 - W9D6",
                    (
                        "Row Mount Doom\n"
                        "Every 2:00 Until Failure\n"
                        "Row 20/13 Calories\n"
                        "Add 1 Calorie Every Round"
                    ),
                ],
                [
                    "Notes / Results",
                    "Made it through 30 of the round of 38",
                ],
                [
                    "WEEK 9",
                    (
                        "Made it through 37 of the round of 39 "
                        "- solid improvement!"
                    ),
                ],
            ],
        )

        self.assertEqual(len(attempts), 6)

        actual = {
            (
                attempt.benchmark_id,
                attempt.program_day,
            ): attempt
            for attempt in attempts
        }

        self.assertEqual(
            actual[("matt_echo_bike", "W1D1")].score,
            "288",
        )
        self.assertEqual(
            actual[("matt_echo_bike", "W9D1")].score,
            "302",
        )
        self.assertEqual(
            actual[("cube_steaked", "W1D2")].score,
            "145",
        )
        self.assertEqual(
            actual[("cube_steaked", "W9D2")].score,
            "185",
        )
        self.assertEqual(
            actual[("row_mount_doom", "W1D6")].score,
            "543",
        )
        self.assertEqual(
            actual[("row_mount_doom", "W9D6")].score,
            "588",
        )

        self.assertEqual(
            actual[("matt_echo_bike", "W9D1")].date,
            "2025-12-29",
        )
        self.assertEqual(
            actual[("row_mount_doom", "W9D6")].date,
            "2026-01-03",
        )

        self.assertEqual(
            actual[("cube_steaked", "W9D2")].details,
            "Round breakdown - 102/36/21/26",
        )
        self.assertIn(
            "37 of 39 calories",
            actual[("row_mount_doom", "W9D6")].details,
        )

    def test_mount_doom_rejects_impossible_partial(self) -> None:
        with self.assertRaisesRegex(
            ValueError,
            "partial calories",
        ):
            from benchmark_normalizer import _mount_doom_score

            _mount_doom_score(
                partial=39,
                failed_round=39,
            )


if __name__ == "__main__":
    unittest.main()
