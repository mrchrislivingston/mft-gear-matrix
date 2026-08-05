from interval_parser import (
    extract_interval_paces,
)


def test_per_round_parser() -> None:
    text = (
        "Definitely burned.\n"
        "Lowered the damper.\n"
        "Averaged out to 1:50/km\n"
        "Per Rd - "
        "1:50.4/1:50.0/1:50.8/1:50.4"
    )

    paces = extract_interval_paces(text)

    assert paces == [
        "1:50.4",
        "1:50.0",
        "1:50.8",
        "1:50.4",
    ]


def test_plain_sequence_parser() -> None:
    text = (
        "Yes this was pretty shitty! I thought I could avg 1:50.\n"
        "Avg 8x 2:15/1:15 - 152.4\n"
        "Definitely fell off after rd 4\n"
        "1:51.7/1:50.8/1:51.2/1:51/"
        "1:53.6/1:53/1:54.4/1:53.8"
    )

    paces = extract_interval_paces(text)

    assert paces == [
        "1:51.7",
        "1:50.8",
        "1:51.2",
        "1:51",
        "1:53.6",
        "1:53",
        "1:54.4",
        "1:53.8",
    ]


if __name__ == "__main__":
    test_per_round_parser()
    test_plain_sequence_parser()

    print("All interval parser tests passed.")