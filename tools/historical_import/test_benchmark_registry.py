from __future__ import annotations

import unittest

from benchmark_registry import (
    find_benchmark_matches,
    normalize_benchmark_text,
)


class BenchmarkRegistryTests(unittest.TestCase):
    def _keys(self, *values: str) -> list[str]:
        return [
            match.key
            for match in find_benchmark_matches(*values)
        ]

    def test_normalizes_case_punctuation_and_spacing(self) -> None:
        self.assertEqual(
            normalize_benchmark_text("  Speed,   NOT Volume! "),
            "speed not volume",
        )

    def test_matches_compact_matt(self) -> None:
        self.assertEqual(
            self._keys("40 minute MATT test"),
            ["matt"],
        )

    def test_matches_dotted_matt(self) -> None:
        self.assertEqual(
            self._keys("M.A.T.T. Row Test"),
            ["matt"],
        )

    def test_matches_spaced_dotted_matt(self) -> None:
        self.assertEqual(
            self._keys("M. A. T. T. Row Test"),
            ["matt"],
        )

    def test_does_not_match_matter(self) -> None:
        self.assertEqual(
            self._keys("Transitions matter in this workout."),
            [],
        )

    def test_matches_programming_or_result_text(self) -> None:
        self.assertEqual(
            self._keys(
                "Zone 2 Row",
                "Worse than the 40 min MATT test.",
            ),
            ["matt"],
        )

    def test_matches_phase_one_benchmarks(self) -> None:
        examples = {
            "Cleo": "cleo",
            "Speed, not Volume": "speed_not_volume",
            "Rule 8 (benchmark chipper test!)": "rule_8",
            "Echo Bike Cube Test": "echo_bike_cube_test",
            "Bike Mount Doom": "bike_mount_doom",
        }

        for text, expected_key in examples.items():
            with self.subTest(text=text):
                self.assertEqual(
                    self._keys(text),
                    [expected_key],
                )

    def test_matches_alias_variants(self) -> None:
        examples = {
            "Rule Eight": "rule_8",
            "Echo Cube Test": "echo_bike_cube_test",
            "C2 Bike Mount Doom": "bike_mount_doom",
            "Bike Erg Mount Doom": "bike_mount_doom",
        }

        for text, expected_key in examples.items():
            with self.subTest(text=text):
                self.assertEqual(
                    self._keys(text),
                    [expected_key],
                )

    def test_returns_multiple_distinct_matches(self) -> None:
        self.assertEqual(
            self._keys("Retest Cleo and Rule 8"),
            ["cleo", "rule_8"],
        )

    def test_returns_each_registry_entry_only_once(self) -> None:
        self.assertEqual(
            self._keys(
                "Echo Bike Cube Test",
                "Echo Cube Test results",
            ),
            ["echo_bike_cube_test"],
        )


    def test_matches_all_documented_registry_names(self) -> None:
        examples = {
            "SkiErg Cube Test": "ski_cube_test",
            "C2 Bike Cube Test": "c2_bike_cube_test",
            "Rower Cube Test": "row_cube_test",
            "Runner Cube Test": "run_cube_test",
            "Cube Steaked": "cube_steaked",
            "Runner Mount Doom": "runner_mount_doom",
            "Ski Erg Mount Doom": "ski_mount_doom",
            "Row Mount Doom": "row_mount_doom",
            "Echo Bike Mount Doom": "echo_bike_mount_doom",
            "Kill-O-Meter": "kill_o_meter",
            "Kill O Watt": "kill_o_watt",
            "Spiders on Mars": "spiders_on_mars",
            "Tour de Misfit": "tour_de_misfit",
            "Riverside Time Trial": "riverside_time_trial",
            "Enzo Gorlomi": "enzo_gorlomi",
            "Cupcake Lungs": "cupcake_lungs",
            "Might Not": "might_not",
            "Bumper Cables": "bumper_cables",
            "Pennies": "pennies",
            "75 Continental Drive": "continental_drive_75",
            "King Larry 1": "king_larry_i",
            "Chuckles 1&2": "chuckles_1_2",
            "Hurt & Injured": "hurt_and_injured",
            "Fairy Dust": "fairy_dust",
        }

        for text, expected_key in examples.items():
            with self.subTest(text=text):
                self.assertEqual(
                    self._keys(text),
                    [expected_key],
                )

    def test_prefers_specific_overlapping_alias(self) -> None:
        self.assertEqual(
            self._keys("Echo Bike Mount Doom"),
            ["echo_bike_mount_doom"],
        )


if __name__ == "__main__":
    unittest.main()