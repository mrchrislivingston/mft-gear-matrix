from __future__ import annotations

import argparse
from collections import Counter
from datetime import datetime
from pathlib import Path

from reader import read_workout_candidates
from writer import write_review_csv


def build_argument_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        description=(
            "Extract Gear, Power, and Zone workout candidates "
            "from a Misfit coaching CSV."
        ),
    )

    parser.add_argument(
        "input_csv",
        type=Path,
        help="Path to the exported coaching CSV.",
    )

    parser.add_argument(
        "output_csv",
        type=Path,
        help="Path for the generated review CSV.",
    )

    parser.add_argument(
        "--year",
        type=int,
        required=True,
        help="Calendar year represented by the workbook dates.",
    )

    parser.add_argument(
        "--program-start-date",
        type=str,
        default=None,
        help=(
            "Optional W1D1 calendar anchor in YYYY-MM-DD format. "
            "Used to infer dates from W#D# headers when the workbook "
            "does not contain an explicit calendar date."
        ),
    )

    return parser


def main() -> None:
    parser = build_argument_parser()
    args = parser.parse_args()

    if not args.input_csv.exists():
        parser.error(
            f"Input file does not exist: {args.input_csv}",
        )

    program_start_date = None

    if args.program_start_date is not None:
        try:
            program_start_date = datetime.strptime(
                args.program_start_date,
                "%Y-%m-%d",
            )
        except ValueError:
            parser.error(
                "--program-start-date must use "
                "YYYY-MM-DD format.",
            )

    candidates = read_workout_candidates(
        input_path=args.input_csv,
        year=args.year,
        program_start_date=program_start_date,
    )

    write_review_csv(
        candidates=candidates,
        output_path=args.output_csv,
    )

    status_counts = Counter(
        candidate.import_status.value
        for candidate in candidates
    )

    print(f"Created: {args.output_csv}")
    print(f"Candidates: {len(candidates)}")

    if program_start_date is not None:
        print(
            "Program start date: "
            f"{program_start_date.date().isoformat()}"
        )

    for status in sorted(status_counts):
        print(f"{status}: {status_counts[status]}")


if __name__ == "__main__":
    main()