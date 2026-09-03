from metric_parser import extract_average_metrics
from pace_distance_interval_parser import (
    extract_pace_distance_intervals,
)


def main() -> None:
    assert extract_average_metrics(
        "Distance - 16.11\nPace - 1:52"
    ) == {
        "primaryMetric": "1:52",
        "distance": "16.11",
    }

    assert extract_pace_distance_intervals(
        "Rd 1 - 3290m/1:58.5\n"
        "Rd 2 - 3289m/1:58.5\n"
        "Total - 6579m/1:58.5"
    ) == [
        {"primaryMetric": "1:58.5", "distance": "3290"},
        {"primaryMetric": "1:58.5", "distance": "3289"},
    ]

    assert extract_pace_distance_intervals(
        "380m,6:21 min/mile\n"
        "413m,5:51 min/mile"
    ) == [
        {"primaryMetric": "6:21", "distance": "380"},
        {"primaryMetric": "5:51", "distance": "413"},
    ]

    print("Phase II result format tests passed.")


if __name__ == "__main__":
    main()
