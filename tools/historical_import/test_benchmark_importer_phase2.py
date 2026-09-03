from __future__ import annotations

import unittest

import benchmark_importer


class Phase2BenchmarkImporterTests(unittest.TestCase):
    def test_phase2_attempts(self) -> None:
        attempts = benchmark_importer.phase_ii_attempts()

        actual = {
            (
                attempt.benchmark_id,
                attempt.program_day,
            ): (
                attempt.date,
                attempt.score,
            )
            for attempt in attempts
        }

        self.assertEqual(
            actual,
            {
                ("matt_echo_bike", "W1D1"): (
                    "2025-11-03",
                    "288",
                ),
                ("cube_steaked", "W1D2"): (
                    "2025-11-04",
                    "145",
                ),
                ("row_mount_doom", "W1D6"): (
                    "2025-11-08",
                    "543",
                ),
                ("matt_echo_bike", "W9D1"): (
                    "2025-12-29",
                    "302",
                ),
                ("cube_steaked", "W9D2"): (
                    "2025-12-30",
                    "185",
                ),
                ("row_mount_doom", "W9D6"): (
                    "2026-01-03",
                    "588",
                ),
            },
        )


if __name__ == "__main__":
    unittest.main()
