from metric_parser import extract_average_metrics


def main() -> None:
    values = extract_average_metrics(
        "Actual - 7:27 pace / .17 miles"
    )

    assert values == {
        "primaryMetric": "7:27",
        "distance": ".17",
    }

    print("Fractional distance metric test passed.")


if __name__ == "__main__":
    main()
