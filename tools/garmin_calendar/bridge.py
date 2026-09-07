import argparse
import json
import re
import sys
from contextlib import redirect_stdout
from datetime import date, timedelta
from pathlib import Path

from classify_fitr_week import (
    classify_section,
    section_text,
    section_title,
)
from garmin_workout_builder import (
    build_gear_workout,
    build_matt_row_workout,
    build_mixed_gear_workout,
    build_power_workout,
    build_z2_workout,
)
from garmin_sync import (
    ensure_scheduled,
    get_garmin_client,
    upload_if_missing,
)
from pull_fitr_week import BASE_URL, fitr_get


def load_credentials(path):
    credentials = {}
    with Path(path).expanduser().open(
        "r",
        encoding="utf-8",
    ) as file:
        for raw_line in file:
            line = raw_line.rstrip("\n")
            if not line or line.startswith("#"):
                continue
            key, value = line.split("=", 1)
            credentials[key.strip()] = value.strip()

    token = credentials.get("TOKEN")
    cookie = credentials.get("COOKIE")
    raw_athlete_id = credentials.get("ATHLETE_ID")

    if not token:
        raise RuntimeError(
            "TOKEN is missing from the FITR credentials file"
        )
    if not cookie:
        raise RuntimeError(
            "COOKIE is missing from the FITR credentials file"
        )
    if not raw_athlete_id:
        raise RuntimeError(
            "ATHLETE_ID is missing from the FITR credentials file"
        )

    try:
        athlete_id = int(raw_athlete_id)
    except ValueError as error:
        raise RuntimeError(
            "ATHLETE_ID in the FITR credentials file must be an integer"
        ) from error

    return token, cookie, athlete_id


def parse_run_pace_targets(values):
    targets = {}

    for value in values:
        if "=" not in value or "," not in value:
            raise ValueError(
                "Run pace targets must use "
                "PRESCRIPTION=LOW,HIGH"
            )

        prescription, pace_range = value.split("=", 1)
        low, high = pace_range.split(",", 1)

        prescription = prescription.strip().upper()
        low = low.strip()
        high = high.strip()

        if not prescription or not low or not high:
            raise ValueError(
                "Run pace targets must use "
                "PRESCRIPTION=LOW,HIGH"
            )

        targets[prescription] = {
            "low": low,
            "high": high,
        }

    return targets

def build_workout(candidate):
    workout_type = candidate["type"]

    if workout_type == "Z2":
        return build_z2_workout(candidate, candidate["age"])

    if workout_type == "GEAR":
        return build_gear_workout(candidate)

    if workout_type == "POWER":
        return build_power_workout(candidate)

    if workout_type == "MIXED_GEAR":
        return build_mixed_gear_workout(candidate)

    if workout_type == "MATT":
        return build_matt_row_workout(candidate["workout_date"])

    raise ValueError(f"Unsupported workout type: {workout_type}")


def preview_week(
    monday,
    age,
    token,
    cookie,
    athlete_id,
    run_pace_targets=None,
):
    sunday = monday + timedelta(days=6)
    calendar_url = (
        f"{BASE_URL}/schedule"
        f"?from={monday.isoformat()}"
        f"&to={sunday.isoformat()}"
    )
    calendar = fitr_get(calendar_url, token, cookie)

    candidates = []
    skipped = []
    matt_dates_seen = set()

    for plan in calendar.get("plans", []):
        plan_title = plan.get("title", "Unknown")

        for day in plan.get("days", []):
            workout_date = day["date"]
            schedule_id = day["schedule_id"]
            detail_url = (
                f"{BASE_URL}/schedule/"
                f"{schedule_id}/athlete/{athlete_id}"
            )
            detail = fitr_get(detail_url, token, cookie)
            sections = detail.get("day", {}).get("sections", [])

            for section_index, section in enumerate(sections):
                text = section_text(section)

                if re.search(
                    r"m\.\s*a\.\s*t\.\s*t\.\s*row\s*test",
                    text,
                    re.IGNORECASE,
                ):
                    if workout_date in matt_dates_seen:
                        continue

                    matt_dates_seen.add(workout_date)
                    result = {
                        "status": "CANDIDATE",
                        "type": "MATT",
                        "prescription": "M.A.T.T. Row Test",
                        "modality": "row",
                        "source_title": section_title(section),
                    }
                elif section_title(section).lower() == "instructions":
                    continue
                else:
                    result = classify_section(section)

                if result is None:
                    continue

                result = dict(result)
                result["workout_date"] = workout_date
                result["age"] = age

                record_id = (
                    f"{schedule_id}:{section_index}:"
                    f"{result.get('type', 'unknown')}"
                )

                if result.get("status") != "CANDIDATE":
                    skipped.append(
                        {
                            "id": record_id,
                            "date": workout_date,
                            "planTitle": plan_title,
                            "sourceTitle": result.get(
                                "source_title",
                                section_title(section),
                            ),
                            "reason": result.get(
                                "reason",
                                "Recognized but not importable",
                            ),
                        }
                    )
                    continue

                if (
                    result["type"] == "GEAR"
                    and result.get("modality", "").lower()
                    == "run"
                ):
                    target = (run_pace_targets or {}).get(
                        result["prescription"]
                    )

                    if target:
                        result["pace_low"] = target["low"]
                        result["pace_high"] = target["high"]

                workout = build_workout(result)

                candidates.append(
                    {
                        "id": record_id,
                        "date": workout_date,
                        "planTitle": plan_title,
                        "sourceTitle": result.get(
                            "source_title",
                            section_title(section),
                        ),
                        "type": result["type"],
                        "prescription": result.get("prescription", ""),
                        "modality": result.get("modality", ""),
                        "workoutName": workout["workoutName"],
                        "classification": result,
                        "garminWorkout": workout,
                    }
                )

    return {
        "action": "preview",
        "from": monday.isoformat(),
        "to": sunday.isoformat(),
        "candidates": candidates,
        "skipped": skipped,
        "summary": {
            "candidates": len(candidates),
            "skipped": len(skipped),
        },
    }



def commit_candidates(preview, selected_ids):
    selected_ids = set(selected_ids)

    if not selected_ids:
        raise ValueError(
            "Commit requires at least one explicit --selected-id"
        )

    available = {
        candidate["id"]: candidate
        for candidate in preview["candidates"]
    }

    unknown = sorted(selected_ids.difference(available))
    if unknown:
        raise ValueError(
            "Unknown candidate IDs: " + ", ".join(unknown)
        )

    garmin = get_garmin_client()
    results = []

    for candidate in preview["candidates"]:
        candidate_id = candidate["id"]

        if candidate_id not in selected_ids:
            continue

        workout = candidate["garminWorkout"]

        # Keep human-readable library output on stderr so stdout remains
        # valid JSON for the Flutter app.
        with redirect_stdout(sys.stderr):
            uploaded, created = upload_if_missing(
                garmin,
                workout,
            )
            workout_id = uploaded["workoutId"]
            scheduled = ensure_scheduled(
                garmin,
                workout_id,
                candidate["date"],
            )

        results.append(
            {
                "id": candidate_id,
                "date": candidate["date"],
                "workoutName": candidate["workoutName"],
                "workoutId": workout_id,
                "created": created,
                "scheduled": scheduled,
            }
        )

    return {
        "action": "commit",
        "from": preview["from"],
        "to": preview["to"],
        "requested": len(selected_ids),
        "results": results,
        "summary": {
            "created": sum(
                1 for result in results
                if result["created"]
            ),
            "scheduled": sum(
                1 for result in results
                if result["scheduled"]
            ),
            "alreadyExisting": sum(
                1 for result in results
                if not result["created"]
            ),
            "alreadyScheduled": sum(
                1 for result in results
                if not result["scheduled"]
            ),
        },
    }

def parse_args():
    parser = argparse.ArgumentParser(
        description="Preview FITR workouts for Garmin calendar sync."
    )
    parser.add_argument(
        "action",
        choices=["preview", "commit"],
        help="Preview is read-only; commit requires selected IDs.",
    )
    parser.add_argument(
        "--monday",
        required=True,
        help="Monday of the requested week in YYYY-MM-DD format.",
    )
    parser.add_argument(
        "--age",
        required=True,
        type=int,
        help="Athlete age used for Zone 2 heart-rate targets.",
    )
    parser.add_argument(
        "--credentials-file",
        required=True,
        help="Path to the existing FITR credentials file.",
    )
    parser.add_argument(
        "--run-pace-target",
        action="append",
        default=[],
        help=(
            "Current Run target as "
            "PRESCRIPTION=LOW,HIGH; may be repeated."
        ),
    )
    parser.add_argument(
        "--selected-id",
        action="append",
        default=[],
        help=(
            "Candidate ID to commit; may be supplied repeatedly."
        ),
    )
    return parser.parse_args()


def main():
    args = parse_args()

    if args.age < 1 or args.age > 120:
        raise ValueError("Age must be between 1 and 120")

    monday = date.fromisoformat(args.monday)

    if monday.weekday() != 0:
        raise ValueError("--monday must be a Monday")

    token, cookie, athlete_id = load_credentials(args.credentials_file)
    run_pace_targets = parse_run_pace_targets(
        args.run_pace_target
    )
    preview = preview_week(
        monday,
        args.age,
        token,
        cookie,
        athlete_id,
        run_pace_targets=run_pace_targets,
    )

    if args.action == "preview":
        result = preview
    else:
        result = commit_candidates(
            preview,
            args.selected_id,
        )

    json.dump(result, sys.stdout, indent=2)
    sys.stdout.write("\n")


if __name__ == "__main__":
    main()
