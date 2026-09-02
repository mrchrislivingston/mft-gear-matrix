from __future__ import annotations

import unittest

from metric_parser import (
    extract_actual_run,
    extract_average_heart_rate,
    extract_average_metrics,
    extract_average_pace,
    extract_average_watts,
    extract_distance,
    extract_duration,
)


class MetricParserTests(unittest.TestCase):
    def test_extract_duration_from_minutes(self) -> None:
        self.assertEqual(
            extract_duration("Completed 90 minutes"),
            "01:30:00",
        )

    def test_extract_duration_from_context_clock(self) -> None:
        self.assertEqual(
            extract_duration("Worked for 45:30 in Zone 2"),
            "00:45:30",
        )
        self.assertEqual(
            extract_duration("Result was 40:00 total"),
            "00:40:00",
        )

    def test_extract_duration_from_modality_clock(self) -> None:
        self.assertEqual(
            extract_duration("BikeErg 35:15"),
            "00:35:15",
        )

    def test_extract_duration_from_line_start_clock(self) -> None:
        self.assertEqual(
            extract_duration("42:10\nAverage HR - 145"),
            "00:42:10",
        )

    def test_duration_ignores_unqualified_clock_value(self) -> None:
        self.assertEqual(
            extract_duration("Average pace - 2:04"),
            "",
        )

    def test_extract_average_watts(self) -> None:
        self.assertEqual(
            extract_average_watts("Average watts: 183"),
            {"watts": "183"},
        )
        self.assertEqual(
            extract_average_watts("Avg power - 250.5"),
            {"watts": "250.5"},
        )

    def test_extract_average_heart_rate_variants(self) -> None:
        self.assertEqual(
            extract_average_heart_rate("Average heart rate: 151"),
            {"heartRate": "151"},
        )
        self.assertEqual(
            extract_average_heart_rate("148 avg HR"),
            {"heartRate": "148"},
        )

    def test_extract_actual_run(self) -> None:
        self.assertEqual(
            extract_actual_run("Actual - 8:12 pace / 4.25 miles"),
            {
                "primaryMetric": "8:12",
                "distance": "4.25",
            },
        )

    def test_extract_average_pace_variants(self) -> None:
        self.assertEqual(
            extract_average_pace("Avg pace - 2:01.4"),
            {"primaryMetric": "2:01.4"},
        )
        self.assertEqual(
            extract_average_pace("8:30 / mile average"),
            {"primaryMetric": "8:30"},
        )

    def test_extract_distance_variants(self) -> None:
        self.assertEqual(
            extract_distance("Distance: 6.2 miles"),
            {"distance": "6.2"},
        )
        self.assertEqual(
            extract_distance("Completed 10 KM"),
            {"distance": "10"},
        )

    def test_extract_average_metrics_combines_values(self) -> None:
        result = extract_average_metrics(
            "Average watts: 183\n"
            "Average HR: 151\n"
            "Average pace: 2:04\n"
            "Distance: 9680 meters"
        )

        self.assertEqual(
            result,
            {
                "watts": "183",
                "heartRate": "151",
                "primaryMetric": "2:04",
            },
        )

    def test_extractors_return_empty_values_for_no_match(self) -> None:
        text = "Nothing parseable here"

        self.assertEqual(extract_duration(text), "")
        self.assertEqual(extract_average_watts(text), {})
        self.assertEqual(extract_average_heart_rate(text), {})
        self.assertEqual(extract_average_pace(text), {})
        self.assertEqual(extract_distance(text), {})
        self.assertEqual(extract_average_metrics(text), {})


if __name__ == "__main__":
    unittest.main()