from __future__ import annotations

from distance_interval_parser import extract_interval_distances


def test_kilometer_distances() -> None:
    distances = extract_interval_distances(
        """This was hard, but manageable.

Distances in Km..Thanks Garmin

1.03/1.03/1.03/1.03/1.03/1.04/1.06/1.04

"""
    )

    assert distances == [
        {"distance": "1030"},
        {"distance": "1030"},
        {"distance": "1030"},
        {"distance": "1030"},
        {"distance": "1030"},
        {"distance": "1040"},
        {"distance": "1060"},
        {"distance": "1040"},
    ]


def test_numbered_meter_distances() -> None:
    distances = extract_interval_distances(
        """Probably should have done more than 18 box jump overs.

1-500, 2-238, 3-532, 4-251, 5-522
Total - 2043
"""
    )

    assert distances == [
        {"distance": "500"},
        {"distance": "238"},
        {"distance": "532"},
        {"distance": "251"},
        {"distance": "522"},
    ]


def test_nonsequential_numbered_values_return_empty() -> None:
    distances = extract_interval_distances(
        "1-500, 3-532, 4-251"
    )

    assert distances == []


def test_unlabeled_numbers_return_empty() -> None:
    distances = extract_interval_distances(
        "Rounds were 1.03/1.04/1.05"
    )

    assert distances == []


def test_no_distances_returns_empty() -> None:
    distances = extract_interval_distances(
        "Average pace was 1:42 per kilometer."
    )

    assert distances == []


def main() -> None:
    test_kilometer_distances()
    test_numbered_meter_distances()
    test_nonsequential_numbered_values_return_empty()
    test_unlabeled_numbers_return_empty()
    test_no_distances_returns_empty()
    print("All distance interval parser tests passed.")


if __name__ == "__main__":
    main()
