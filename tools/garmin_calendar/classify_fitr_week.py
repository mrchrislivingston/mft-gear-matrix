import re
import sys
from datetime import date, timedelta

from pull_fitr_week import load_credentials, fitr_get, next_week, BASE_URL
from garmin_workout_builder import build_z2_workout, build_gear_workout, build_power_workout, build_matt_row_workout


ORDINAL_GEARS = {
    "1st": "G1",
    "2nd": "G2",
    "3rd": "G3",
    "4th": "G4",
    "5th": "G5",
    "6th": "G6",
    "7th": "G7",
    "8th": "G8",
}

MODALITY_PATTERNS = [
    ("C2 Bike", r"\b(?:c2|bikeerg|bike erg)\s*bike\b|\bc2 bike\b"),
    ("Echo Bike", r"\becho(?: bike)?\b"),
    ("Row", r"\brow(?:ing)?\b"),
    ("Ski", r"\bski(?:erg)?\b"),
    ("Run", r"\brun(?:ning)?\b"),
]


def parse_time(value):
    """
    Convert FITR time strings such as:
      6:00
      1:30
      :20
      15:00
    into seconds.
    """
    value = value.strip()

    if value.startswith(":"):
        return int(value[1:])

    minutes, seconds = value.split(":")
    return int(minutes) * 60 + int(seconds)


def format_time(seconds):
    minutes, seconds = divmod(int(seconds), 60)
    return f"{minutes}:{seconds:02d}"


def section_title(section):
    return (
        section.get("title")
        or (section.get("challenge") or {}).get("title")
        or "(untitled)"
    ).strip()


def section_description(section):
    return (
        section.get("description")
        or (section.get("challenge") or {}).get("description")
        or ""
    ).strip()


def section_text(section):
    return f"{section_title(section)}\n{section_description(section)}"


def detect_modality(text):
    """
    Detect the PRIMARY modality from prescription language.

    We intentionally prefer lines describing the actual work and do not
    treat Equipment Modification / flush language as the primary modality.
    """
    lines = text.splitlines()

    useful_lines = []
    for line in lines:
        stripped = line.strip()

        if not stripped:
            continue

        lower = stripped.lower()

        if lower.startswith("equipment modification"):
            break

        # Active recovery may intentionally use another machine.
        if "flush on" in lower:
            continue

        useful_lines.append(stripped)

    primary_text = "\n".join(useful_lines)

    found = []

    for modality, pattern in MODALITY_PATTERNS:
        if re.search(pattern, primary_text, re.IGNORECASE):
            found.append(modality)

    # Remove duplicate conceptual matches.
    found = list(dict.fromkeys(found))

    if len(found) == 1:
        return found[0]

    return None


def detect_gear(text):
    # G1 ... G8
    match = re.search(r"\bG([1-8])\b", text, re.IGNORECASE)
    if match:
        return f"G{match.group(1)}"

    # "3rd Gear", "4th Gear", etc.
    match = re.search(
        r"\b(1st|2nd|3rd|4th|5th|6th|7th|8th)\s+Gear\b",
        text,
        re.IGNORECASE,
    )

    if match:
        ordinal = match.group(1).lower()

        lookup = {
            "1st": "G1",
            "2nd": "G2",
            "3rd": "G3",
            "4th": "G4",
            "5th": "G5",
            "6th": "G6",
            "7th": "G7",
            "8th": "G8",
        }

        return lookup[ordinal]

    return None


def detect_power(text):
    match = re.search(r"\bP([1-3])\b", text, re.IGNORECASE)

    if match:
        return f"P{match.group(1)}"

    return None


def classify_mixed_gear(text, gear, source_title):
    structure = re.search(
        r"AMRAP\s+(\d+:\d{2})\s+"
        r"Ski\s+for\s+Meters\s+@\s+\d+(?:st|nd|rd|th)\s+Gear"
        r".*?\bRest\s+(\d+:\d{2})"
        r".*?AMRAP\s+(\d+:\d{2})\s+"
        r"C2\s+Bike\s+for\s+Meters\s+@\s+\d+(?:st|nd|rd|th)\s+Gear"
        r".*?\bRest\s+(\d+:\d{2})"
        r".*?\bThen\s+(\d+)\s+Rounds?"
        r".*?AMRAP\s+(\d+:\d{2})\s+"
        r"Ski\s+for\s+Meters\s+@\s+\d+(?:st|nd|rd|th)\s+Gear"
        r".*?Directly\s+into"
        r".*?AMRAP\s+(\d+:\d{2})\s+"
        r"C2\s+Bike\s+for\s+Meters\s+@\s+\d+(?:st|nd|rd|th)\s+Gear"
        r".*?\bRest\s+(\d+:\d{2})",
        text,
        re.IGNORECASE | re.DOTALL,
    )

    if not structure:
        return None

    first_ski_seconds = parse_time(structure.group(1))
    first_rest_seconds = parse_time(structure.group(2))
    first_bike_seconds = parse_time(structure.group(3))
    second_rest_seconds = parse_time(structure.group(4))
    split_rounds = int(structure.group(5))
    split_ski_seconds = parse_time(structure.group(6))
    split_bike_seconds = parse_time(structure.group(7))
    split_rest_seconds = parse_time(structure.group(8))

    steps = [
        {
            "kind": "work",
            "modality": "Ski",
            "seconds": first_ski_seconds,
        },
        {
            "kind": "recovery",
            "seconds": first_rest_seconds,
        },
        {
            "kind": "work",
            "modality": "C2 Bike",
            "seconds": first_bike_seconds,
        },
        {
            "kind": "recovery",
            "seconds": second_rest_seconds,
        },
    ]

    for round_index in range(split_rounds):
        steps.extend(
            [
                {
                    "kind": "work",
                    "modality": "Ski",
                    "seconds": split_ski_seconds,
                },
                {
                    "kind": "work",
                    "modality": "C2 Bike",
                    "seconds": split_bike_seconds,
                },
            ]
        )

        if round_index < split_rounds - 1:
            steps.append(
                {
                    "kind": "recovery",
                    "seconds": split_rest_seconds,
                }
            )

    return {
        "status": "CANDIDATE",
        "type": "MIXED_GEAR",
        "prescription": gear,
        "modality": "Ski + C2 Bike",
        "rounds": 2 + split_rounds,
        "steps": steps,
        "source_title": source_title,
    }


def classify_gear(section):
    text = section_text(section)

    gear = detect_gear(text)

    if not gear:
        return None

    mixed = classify_mixed_gear(
        text,
        gear,
        section_title(section),
    )
    if mixed:
        return mixed

    modality = detect_modality(text)

    if not modality:
        return {
            "status": "SKIP",
            "reason": "Gear detected but modality is ambiguous",
            "source_title": section_title(section),
        }

    # Example:
    # AMRAP 6:00 x 4
    structure = re.search(
        r"AMRAP\s+(:?\d*:\d{2})\s*[xX]\s*(\d+)",
        text,
        re.IGNORECASE,
    )

    rest = re.search(
        r"\bRest\s+(:?\d*:\d{2})",
        text,
        re.IGNORECASE,
    )

    if not structure or not rest:
        return {
            "status": "SKIP",
            "reason": "Gear detected but explicit FITR timing could not be parsed",
            "source_title": section_title(section),
        }

    work_seconds = parse_time(structure.group(1))
    rounds = int(structure.group(2))
    rest_seconds = parse_time(rest.group(1))

    return {
        "status": "CANDIDATE",
        "type": "GEAR",
        "prescription": gear,
        "modality": modality,
        "rounds": rounds,
        "work_seconds": work_seconds,
        "rest_seconds": rest_seconds,
        "source_title": section_title(section),
    }


def classify_power(section):
    text = section_text(section)

    power = detect_power(text)

    if not power:
        return None

    # Mixed P3/P2/P1 pieces are explicitly outside V1.
    powers = set(re.findall(r"\bP[1-3]\b", text, re.IGNORECASE))

    if len(powers) != 1:
        return {
            "status": "SKIP",
            "reason": "Mixed Power prescriptions",
            "source_title": section_title(section),
        }

    every = re.search(
        r"Every\s+(:?\d*:\d{2})\s+(?:for|x)\s+(\d+)(?:\s+Rounds?)?",
        text,
        re.IGNORECASE,
    )

    if not every:
        return {
            "status": "SKIP",
            "reason": "Power detected but Every/round structure could not be parsed",
            "source_title": section_title(section),
        }

    work_patterns = [
        r"(?:(?:Max\s+)?Calorie\s+)?(Row|Ski)\s+(?:for\s+Calories\s+)?in\s+(:?\d*:\d{2})\s+@\s*(P[1-3])",
        r"(Echo(?:\s+Bike)?|C2\s+Bike)\s+for\s+Calories\s+in\s+(:?\d*:\d{2})\s+@\s*(P[1-3])",
        r"Max\s+Calorie\s+(Echo(?:\s+Bike)?|C2\s+Bike)\s+in\s+(:?\d*:\d{2})\s+@\s*(P[1-3])",
        r"(Run)\s+.*?in\s+(:?\d*:\d{2})\s+@\s*(P[1-3])",
    ]

    work_match = None

    for pattern in work_patterns:
        work_match = re.search(pattern, text, re.IGNORECASE)
        if work_match:
            break

    if not work_match:
        return {
            "status": "SKIP",
            "reason": "Power work interval/modality could not be parsed",
            "source_title": section_title(section),
        }

    raw_modality = work_match.group(1).lower()

    if raw_modality.startswith("row"):
        modality = "Row"
    elif raw_modality.startswith("ski"):
        modality = "Ski"
    elif raw_modality.startswith("echo"):
        modality = "Echo Bike"
    elif raw_modality.startswith("c2"):
        modality = "C2 Bike"
    elif raw_modality.startswith("run"):
        modality = "Run"
    else:
        return {
            "status": "SKIP",
            "reason": "Unknown Power modality",
            "source_title": section_title(section),
        }

    every_seconds = parse_time(every.group(1))
    rounds = int(every.group(2))
    work_seconds = parse_time(work_match.group(2))

    recovery_seconds = every_seconds - work_seconds

    if recovery_seconds < 0:
        return {
            "status": "SKIP",
            "reason": "Power work duration exceeds interval duration",
            "source_title": section_title(section),
        }

    return {
        "status": "CANDIDATE",
        "type": "POWER",
        "prescription": power,
        "modality": modality,
        "rounds": rounds,
        "work_seconds": work_seconds,
        "recovery_seconds": recovery_seconds,
        "source_title": section_title(section),
    }


def classify_z2(section):
    text = section_text(section)

    if not re.search(r"\bZone\s*2\b", text, re.IGNORECASE):
        return None

    # Require an explicit modality after "Zone 2 -".
    modality_match = re.search(
        r"Zone\s*2\s*-\s*(C2 Bike|Echo Bike|Row|Ski|Run)\b",
        text,
        re.IGNORECASE,
    )

    if not modality_match:
        return {
            "status": "SKIP",
            "reason": "Zone 2 modality is ambiguous",
            "source_title": section_title(section),
        }

    raw_modality = modality_match.group(1).lower()

    modality_lookup = {
        "c2 bike": "C2 Bike",
        "echo bike": "Echo Bike",
        "row": "Row",
        "ski": "Ski",
        "run": "Run",
    }

    modality = modality_lookup[raw_modality]

    warmup = re.search(
        r"(\d+:\d{2})\s+Zone\s*2\s+Warm\s*Up",
        text,
        re.IGNORECASE,
    )

    work = re.search(
        r"(\d+:\d{2})(?:\s*[-–]\s*(\d+:\d{2}))?\s+"
        + re.escape(modality)
        + r"\s+@\s+Zone\s*2",
        text,
        re.IGNORECASE,
    )

    cooldown = re.search(
        r"(\d+:\d{2})\s+Zone\s*2\s+Cool\s*Down",
        text,
        re.IGNORECASE,
    )

    if not work:
        return {
            "status": "SKIP",
            "reason": "Zone 2 working duration could not be parsed",
            "source_title": section_title(section),
        }

    # If FITR says 45:00-90:00, use the minimum: 45:00.
    work_seconds = parse_time(work.group(1))

    return {
        "status": "CANDIDATE",
        "type": "Z2",
        "prescription": "Z2",
        "modality": modality,
        "warmup_seconds": parse_time(warmup.group(1)) if warmup else 0,
        "work_seconds": work_seconds,
        "cooldown_seconds": parse_time(cooldown.group(1)) if cooldown else 0,
        "source_title": section_title(section),
    }


def classify_section(section):
    # Order matters. Gear/P identifiers are more specific than generic Z2 text.
    result = classify_gear(section)
    if result:
        return result

    result = classify_power(section)
    if result:
        return result

    result = classify_z2(section)
    if result:
        return result

    return None


def print_result(workout_date, result):
    if result["status"] == "SKIP":
        print(
            f"{workout_date}  SKIP       "
            f"{result['source_title']} — {result['reason']}"
        )
        return

    if result["type"] == "GEAR":
        print(
            f"{workout_date}  GEAR       "
            f"{result['prescription']} {result['modality']} — "
            f"{result['rounds']} x {format_time(result['work_seconds'])} "
            f"/ {format_time(result['rest_seconds'])} rest"
        )

    elif result["type"] == "POWER":
        print(
            f"{workout_date}  POWER      "
            f"{result['prescription']} {result['modality']} — "
            f"{result['rounds']} x "
            f"{format_time(result['work_seconds'])} work "
            f"/ {format_time(result['recovery_seconds'])} recovery"
        )

    elif result["type"] == "Z2":
        print(
            f"{workout_date}  Z2         "
            f"{result['modality']} — "
            f"{format_time(result['warmup_seconds'])} warmup / "
            f"{format_time(result['work_seconds'])} work / "
            f"{format_time(result['cooldown_seconds'])} cooldown"
        )


from garmin_sync import (
    get_garmin_client,
    upload_if_missing,
    ensure_scheduled,
)


WRITE_TO_GARMIN = True


def main():
    token, cookie, athlete_id = load_credentials()

    age = int(input("Age: ").strip())

    if age < 1 or age > 120:
        raise ValueError("Age must be between 1 and 120.")

    garmin = get_garmin_client() if WRITE_TO_GARMIN else None

    if len(sys.argv) > 1:
        monday = date.fromisoformat(sys.argv[1])
        sunday = monday + timedelta(days=6)
    else:
        monday, sunday = next_week()

    print()
    print(f"FITR classifier: {monday} -> {sunday}")
    print("=" * 76)

    calendar_url = (
        f"{BASE_URL}/schedule"
        f"?from={monday.isoformat()}"
        f"&to={sunday.isoformat()}"
    )

    calendar = fitr_get(calendar_url, token, cookie)

    candidates = 0
    skipped = 0
    matt_dates_seen = set()

    for plan in calendar.get("plans", []):
        for day in plan.get("days", []):
            workout_date = day["date"]
            schedule_id = day["schedule_id"]

            detail_url = (
                f"{BASE_URL}/schedule/"
                f"{schedule_id}/athlete/{athlete_id}"
            )

            detail = fitr_get(detail_url, token, cookie)

            for section in detail.get("day", {}).get("sections", []):
                section_text_value = section_text(section)

                if re.search(
                    r"m\.\s*a\.\s*t\.\s*t\.\s*row\s*test",
                    section_text_value,
                    re.IGNORECASE,
                ):
                    if workout_date in matt_dates_seen:
                        continue

                    matt_dates_seen.add(workout_date)

                    result = {
                        "status": "CANDIDATE",
                        "type": "MATT",
                        "prescription": "M.A.T.T. Row Test",
                        "source_title": section_title(section),
                    }
                elif section_title(section).lower() == "instructions":
                    continue
                else:
                    result = classify_section(section)

                if result is None:
                    continue

                    continue

                print_result(workout_date, result)

                if result["status"] == "CANDIDATE":
                    result["workout_date"] = workout_date
                    candidates += 1

                    if result["type"] == "Z2":
                        workout = build_z2_workout(result, age)
                    elif result["type"] == "GEAR":
                        workout = build_gear_workout(result)
                    elif result["type"] == "POWER":
                        workout = build_power_workout(result)
                    elif result["type"] == "MATT":
                        workout = build_matt_row_workout(workout_date)

                    if WRITE_TO_GARMIN:
                        uploaded, created = upload_if_missing(garmin, workout)

                        workout_id = uploaded["workoutId"]

                        if ensure_scheduled(
                            garmin,
                            workout_id,
                            workout_date,
                        ):
                            print(
                                f"            SCHEDULED: "
                                f"{workout['workoutName']}"
                            )
                            print(
                                f"            Workout ID: "
                                f"{workout_id}"
                            )
                        else:
                            print(
                                f"            Already scheduled: "
                                f"{workout['workoutName']}"
                            )

                    else:
                        print(
                            f"            WOULD CREATE: "
                            f"{workout['workoutName']}"
                        )

                else:
                    skipped += 1

    print()
    print("=" * 76)
    print(f"Garmin candidates: {candidates}")
    print(f"Recognized but skipped: {skipped}")
    print(
        f"Garmin writes: "
        f"{'ENABLED' if WRITE_TO_GARMIN else 'DISABLED'}"
    )


if __name__ == "__main__":
    main()
