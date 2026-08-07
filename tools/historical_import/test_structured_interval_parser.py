from structured_interval_parser import (
    extract_watts_rpm_calories,
)


def test_echo_intervals() -> None:
    text = (
        "Avg Watts/Avg RPM/Cals\n"
        "Rd1 - 691/87/18, "
        "Rd2 - 683/87/20, "
        "Rd3 - 934/96/20, "
        "Rd4 - 871/94/19"
    )

    intervals = extract_watts_rpm_calories(
        text,
    )

    assert intervals == [
        {
            "watts": "691",
            "rpm": "87",
            "calories": "18",
        },
        {
            "watts": "683",
            "rpm": "87",
            "calories": "20",
        },
        {
            "watts": "934",
            "rpm": "96",
            "calories": "20",
        },
        {
            "watts": "871",
            "rpm": "94",
            "calories": "19",
        },
    ]


def test_bikeerg_missing_colons() -> None:
    text = (
        "Rd1-8 "
        "1019/1:57.7/86, "
        "1095/1:49.5/94, "
        "1120/1:47.1/90, "
        "1129/1:46.2/91, "
        "1105/1:48.5/95, "
        "1122/1:46.9/96, "
        "1129/146.2/97, "
        "1145/144.8/98 "
        "| Average 1108/1:49/93"
    )

    intervals = extract_watts_rpm_calories(
        text,
    )

    assert len(intervals) == 8

    assert intervals[6] == {
        "watts": "1129",
        "primaryMetric": "1:46.2",
        "rpm": "97",
    }

    assert intervals[7] == {
        "watts": "1145",
        "primaryMetric": "1:44.8",
        "rpm": "98",
    }


def test_calorie_only_interval_sequence() -> None:
    text = (
        "18/19/19 @ 7/8/6 damper - "
        "8 was the highest output, but the hardest. "
        "I probably dig 7"
    )

    intervals = extract_watts_rpm_calories(
        text,
    )

    assert intervals == [
        {
            "calories": "18",
        },
        {
            "calories": "19",
        },
        {
            "calories": "19",
        },
    ]


def test_calories_per_hour_power_bike() -> None:
    text = (
        "Avg Cals/hr/cals in time\n"
        "2970/20, "
        "2732/18, "
        "2897/20, "
        "2802/19"
    )

    intervals = extract_watts_rpm_calories(
        text,
    )

    assert intervals == [
        {
            "caloriesPerHour": "2970",
            "calories": "20",
        },
        {
            "caloriesPerHour": "2732",
            "calories": "18",
        },
        {
            "caloriesPerHour": "2897",
            "calories": "20",
        },
        {
            "caloriesPerHour": "2802",
            "calories": "19",
        },
    ]


if __name__ == "__main__":
    test_echo_intervals()
    test_bikeerg_missing_colons()
    test_calorie_only_interval_sequence()
    test_calories_per_hour_power_bike()

    print(
        "All structured interval parser tests passed."
    )