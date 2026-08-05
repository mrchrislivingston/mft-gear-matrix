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


if __name__ == "__main__":
    test_echo_intervals()

    print(
        "All structured interval parser tests passed."
    )