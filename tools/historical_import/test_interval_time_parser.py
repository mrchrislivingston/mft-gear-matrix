from interval_time_parser import extract_interval_times


def test_extract_interval_times():
    text = """
    Total time/Pace - per round

    4:47.4/1:53.4

    4:43.8/1:52.7

    4:41.5/1:52.4

    4:35.8/1:51.3
    """

    times = extract_interval_times(text)

    assert times == [
        "4:47.4",
        "4:43.8",
        "4:41.5",
        "4:35.8",
    ]