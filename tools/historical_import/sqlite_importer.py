from __future__ import annotations

from pathlib import Path

from normalizer import normalize_candidate
from review_reader import read_reviewed_candidates


def main() -> None:
    candidates = read_reviewed_candidates(
        Path("review/offszn1_review_v3.csv"),
    )

    imported = 0
    failed = 0

    for candidate in candidates:
        try:
            workout = normalize_candidate(candidate)

            print(
                f"OK   "
                f"{workout.prescription_id:<3} "
                f"{workout.modality:<8} "
                f"{workout.date}"
            )

            imported += 1

        except Exception as error:
            print(
                f"FAIL "
                f"{candidate.prescription or candidate.gear:<3} "
                f"{candidate.modality:<8} "
                f"{candidate.date}"
            )

            print(f"Reason: {error}")

            preview = (
                candidate.result_text
                .replace("\n", " ")
                .strip()
            )

            if len(preview) > 120:
                preview = preview[:117] + "..."

            print(f"Result: {preview}")
            print()

            failed += 1

    print("-" * 40)
    print(f"Imported: {imported}")
    print(f"Failed:   {failed}")


if __name__ == "__main__":
    main()