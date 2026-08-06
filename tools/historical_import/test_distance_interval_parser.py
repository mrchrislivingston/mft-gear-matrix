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
        {"distanceKm": "1.03"},
        {"distanceKm": "1.03"},
        {"distanceKm": "1.03"},
        {"distanceKm": "1.03"},
        {"distanceKm": "1.03"},
        {"distanceKm": "1.04"},
        {"distanceKm": "1.06"},
        {"distanceKm": "1.04"},
    ]


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
    test_unlabeled_numbers_return_empty()
    test_no_distances_returns_empty()

    print("All distance interval parser tests passed.")


if __name__ == "__main__":
    main()