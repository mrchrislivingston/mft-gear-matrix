from __future__ import annotations

import subprocess
import sys
from pathlib import Path


SCRIPT_DIRECTORY = Path(__file__).resolve().parent


def discover_tests() -> list[Path]:
    return sorted(SCRIPT_DIRECTORY.glob("test_*.py"))


def display_name(test_path: Path) -> str:
    return test_path.stem.removeprefix("test_").replace("_", " ").title()


def main() -> int:
    tests = discover_tests()
    passed = 0
    failures: list[tuple[str, subprocess.CompletedProcess[str]]] = []

    print("=" * 50)
    print("MFT Historical Import Test Suite")
    print("=" * 50)
    print()
    print(f"Discovered tests: {len(tests)}")
    print()

    if not tests:
        print("No test_*.py files were found.")
        print("=" * 50)
        return 1

    for test_path in tests:
        title = display_name(test_path)
        result = subprocess.run(
            [sys.executable, str(test_path)],
            cwd=SCRIPT_DIRECTORY,
            capture_output=True,
            text=True,
        )

        if result.returncode == 0:
            print(f"{title:.<40}PASS")
            passed += 1
        else:
            print(f"{title:.<40}FAIL")
            failures.append((title, result))

    print()
    print("=" * 50)
    print(f"Passed: {passed}")
    print(f"Failed: {len(failures)}")

    if failures:
        print()
        print("Failure details:")

        for title, result in failures:
            print()
            print("-" * 50)
            print(title)
            print("-" * 50)

            if result.stdout.strip():
                print(result.stdout.rstrip())

            if result.stderr.strip():
                print(result.stderr.rstrip())

        print()
        print("TEST SUITE FAILED")
        print("=" * 50)
        return 1

    print()
    print("ALL TESTS PASSED")
    print("=" * 50)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())