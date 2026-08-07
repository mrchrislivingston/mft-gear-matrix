from pace_distance_interval_parser import (
    extract_pace_distance_intervals,
)


def test_run_mile_pace_and_distance() -> None:
    text = (
        "Per Rd Pace/Mile - "
        "7:27/.17, 6:35/.19, 6:35/.19, 6:20/.20"
    )

    intervals = extract_pace_distance_intervals(
        text,
    )

    assert intervals == [
        {"primaryMetric": "7:27", "distance": ".17"},
        {"primaryMetric": "6:35", "distance": ".19"},
        {"primaryMetric": "6:35", "distance": ".19"},
        {"primaryMetric": "6:20", "distance": ".20"},
    ]


def test_run_km_distance_converts_to_meters() -> None:
    text = (
        "6:44/.42KM, 6:48/.41KM, "
        "7:04/.40KM"
    )

    intervals = extract_pace_distance_intervals(
        text,
    )

    assert intervals == [
        {"primaryMetric": "6:44", "distance": "420"},
        {"primaryMetric": "6:48", "distance": "410"},
        {"primaryMetric": "7:04", "distance": "400"},
    ]


def test_bikeerg_missing_colon_pace() -> None:
    text = (
        "155.3/3121, 154.5/3143, "
        "152.8/3189, 151.1/3240"
    )

    intervals = extract_pace_distance_intervals(
        text,
    )

    assert intervals == [
        {"primaryMetric": "1:55.3", "distance": "3121"},
        {"primaryMetric": "1:54.5", "distance": "3143"},
        {"primaryMetric": "1:52.8", "distance": "3189"},
        {"primaryMetric": "1:51.1", "distance": "3240"},
    ]


def main() -> None:
    test_run_mile_pace_and_distance()
    test_run_km_distance_converts_to_meters()
    test_bikeerg_missing_colon_pace()

    print(
        "All pace/distance interval parser tests passed."
    )


if __name__ == "__main__":
    main()