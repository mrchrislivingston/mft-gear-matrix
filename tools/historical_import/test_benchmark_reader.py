from __future__ import annotations

import csv
import tempfile
import unittest
from datetime import datetime
from pathlib import Path

from benchmark_reader import read_benchmark_candidates
from models import DateStatus


class BenchmarkReaderTests(unittest.TestCase):
    def test_reads_programming_and_aligned_result_cells(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            input_path = Path(temporary_directory) / "Phase 1.csv"

            rows = [
                [
                    "Mon - W1D1",
                    "M. A. T. T. Row Test\n40:00 Row",
                    "Echo Bike Cube Test\nAMRAP 4:00 x 4",
                ],
                [
                    "Notes / Results",
                    (
                        "I'm pretty sure this is worse than the "
                        "40 min M. A. T. T. test.\n"
                        "Avg Pace - 2:04\n"
                        "Avg Watts - 183"
                    ),
                    (
                        "72 / 80 / 81 / 83 calories\n"
                        "316 total"
                    ),
                ],
                [
                    "Tues - W1D2",
                    "Transitions matter in this workout",
                ],
                [
                    "Notes / Results",
                    "No benchmark here",
                ],
            ]

            with input_path.open(
                "w",
                encoding="utf-8",
                newline="",
            ) as output_file:
                csv.writer(output_file).writerows(rows)

            candidates = read_benchmark_candidates(
                input_path=input_path,
                year=2025,
                program_start_date=datetime(2025, 9, 1),
            )

        self.assertEqual(len(candidates), 2)

        matt = next(
            candidate
            for candidate in candidates
            if candidate.benchmark_key == "matt"
        )
        self.assertEqual(matt.date, "2025-09-01")
        self.assertEqual(matt.date_status, DateStatus.INFERRED)
        self.assertEqual(matt.program_day, "W1D1")
        self.assertEqual(matt.modality, "row")
        self.assertEqual(matt.source_row, 1)
        self.assertEqual(matt.source_column, 2)
        self.assertIn("Avg Watts - 183", matt.result_text)

        cube = next(
            candidate
            for candidate in candidates
            if candidate.benchmark_key
            == "echo_bike_cube_test"
        )
        self.assertEqual(cube.modality, "echo")
        self.assertEqual(cube.source_column, 3)
        self.assertIn("316 total", cube.result_text)

    def test_candidate_serializes_date_status(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            input_path = Path(temporary_directory) / "test.csv"

            with input_path.open(
                "w",
                encoding="utf-8",
                newline="",
            ) as output_file:
                csv.writer(output_file).writerows(
                    [
                        [
                            "Sep 22 - W4D1",
                            "Cleo",
                        ],
                        [
                            "Notes / Results",
                            "32:29",
                        ],
                    ]
                )

            candidates = read_benchmark_candidates(
                input_path=input_path,
                year=2025,
            )

        self.assertEqual(len(candidates), 1)

        serialized = candidates[0].to_dict()
        self.assertEqual(serialized["date"], "2025-09-22")
        self.assertEqual(serialized["date_status"], "exact")
        self.assertEqual(serialized["benchmark_key"], "cleo")

    def test_ignores_benchmark_reference_in_result_text(self) -> None:
        with tempfile.TemporaryDirectory() as temporary_directory:
            input_path = Path(temporary_directory) / "test.csv"

            with input_path.open(
                "w",
                encoding="utf-8",
                newline="",
            ) as output_file:
                csv.writer(output_file).writerows(
                    [
                        [
                            "W1D1",
                            (
                                "Build Echo - 5th / 6th Gear\n"
                                "AMRAP 4:00 Calorie Echo Bike"
                            ),
                        ],
                        [
                            "Notes / Results",
                            (
                                "I'm pretty sure this is worse than "
                                "the 40 min MATT test."
                            ),
                        ],
                    ]
                )

            candidates = read_benchmark_candidates(
                input_path=input_path,
                year=2025,
                program_start_date=datetime(2025, 1, 1),
            )

        self.assertEqual(candidates, [])

if __name__ == "__main__":
    unittest.main()