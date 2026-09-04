from __future__ import annotations

import unittest

import benchmark_importer


class Phase3BenchmarkImporterTests(unittest.TestCase):
    def test_phase3_attempts(self) -> None:
        attempts = benchmark_importer.phase_iii_attempts()

        actual = {
            attempt.benchmark_id: (
                attempt.date,
                attempt.score,
                attempt.program_day,
            )
            for attempt in attempts
        }

        self.assertEqual(
            actual,
            {
                "matt_c2_bike": (
                    "2026-01-06",
                    "230",
                    "W1D2",
                ),
                "row_cube_test": (
                    "2026-01-07",
                    "330",
                    "W1D3",
                ),
                "spiders_on_mars": (
                    "2026-01-09",
                    "6",
                    "W1D5",
                ),
            },
        )


if __name__ == "__main__":
    unittest.main()
