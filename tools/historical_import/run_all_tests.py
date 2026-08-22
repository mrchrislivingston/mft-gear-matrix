from __future__ import annotations

import subprocess
import sys


TESTS = [
    ("Parser", "test_parser.py"),
    ("Reader", "test_reader.py"),
    ("Writer", "test_writer.py"),
    ("Normalized Models", "test_normalized_models.py"),
    ("Review Reader", "test_review_reader.py"),
    ("Interval Parser", "test_interval_parser.py"),
    ("Interval Time Parser", "test_interval_time_parser.py"),
    ("Distance Interval Parser", "test_distance_interval_parser.py"),
    ("Structured Interval Parser", "test_structured_interval_parser.py"),
    ("Execution Plan Parser", "test_execution_plan_parser.py"),
    ("Normalizer", "test_normalizer.py"),
]


def main() -> int:
    passed = 0
    failed: list[str] = []

    print("=" * 40)
    print("MFT Historical Import Test Suite")
    print("=" * 40)
    print()

    for title, filename in TESTS:
        result = subprocess.run(
            [sys.executable, filename],
            capture_output=True,
            text=True,
        )

        if result.returncode == 0:
            print(f"{title:.<35}PASS")
            passed += 1
        else:
            print(f"{title:.<35}FAIL")
            failed.append(title)

    print()
    print("=" * 40)
    print(f"Passed: {passed}")
    print(f"Failed: {len(failed)}")
    print()

    if failed:
        print("Failures:")
        for name in failed:
            print(f" - {name}")
        print()
        print("TEST SUITE FAILED")
        print("=" * 40)
        return 1

    print("ALL TESTS PASSED")
    print("=" * 40)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())