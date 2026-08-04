from __future__ import annotations

import re

from models import ImportStatus, ResultDetail, WorkoutType


GEAR_WORD_PATTERN = re.compile(
    r"\b([1-8])(?:st|nd|rd|th)?\s+gear\b",
    re.IGNORECASE,
)

GEAR_SHORT_PATTERN = re.compile(
    r"\bG([1-8])\b",
    re.IGNORECASE,
)

POWER_PATTERN = re.compile(
    r"\bP([1-3])\b",
    re.IGNORECASE,
)

PRESCRIBED_POWER_PATTERN = re.compile(
    r"@\s*P([1-3])\b",
    re.IGNORECASE,
)

ZONE_PATTERN = re.compile(
    r"\b(?:zone|z)\s*([12])\b",
    re.IGNORECASE,
)

SKIP_RESULT_PATTERN = re.compile(
    r"\b("
    r"skip(?:ped|ping)?|"
    r"didn['’]?t do|"
    r"did not do|"
    r"not completed|"
    r"missed|"
    r"rest day|"
    r"sick|"
    r"illness|"
    r"work emergency|"
    r"woke up with a cold|"
    r"going to take the weekend"
    r")\b",
    re.IGNORECASE,
)

PARTIAL_RESULT_PATTERN = re.compile(
    r"\b("
    r"quit|"
    r"stopped|"
    r"only completed|"
    r"only did|"
    r"did\s+\d+\s*(?:of|/)\s*\d+|"
    r"\d+\s*/\s*\d+\s+rounds?"
    r")\b",
    re.IGNORECASE,
)

WORKOUT_START_PATTERN = re.compile(
    r"^\s*("
    r"aerobic|"
    r"power|"
    r"zone\s*[12]|"
    r"build"
    r")\b",
    re.IGNORECASE,
)

MODALITY_PATTERNS = {
    "run": re.compile(
        r"\b(?:run|running|treadmill)\b",
        re.IGNORECASE,
    ),
    "row": re.compile(
        r"\b(?:row|rowing|rower)\b",
        re.IGNORECASE,
    ),
    "ski": re.compile(
        r"\b(?:ski|skierg|ski erg)\b",
        re.IGNORECASE,
    ),
    "bikeErg": re.compile(
        r"\b(?:c2 bike|bikeerg|bike erg|bike)\b",
        re.IGNORECASE,
    ),
    "echo": re.compile(
        r"\b(?:echo bike|air bike|assault bike)\b",
        re.IGNORECASE,
    ),
}

PRIMARY_TEXT_STOP_PATTERNS = [
    re.compile(
        r"^\s*equipment modifications?\s*$",
        re.IGNORECASE,
    ),
    re.compile(
        r"^\s*recover\b",
        re.IGNORECASE,
    ),
    re.compile(
        r"^\s*your zone 2 today\b",
        re.IGNORECASE,
    ),
    re.compile(
        r"^\s*reminder:",
        re.IGNORECASE,
    ),
    re.compile(
        r"^\s*there will be a zone 2\b",
        re.IGNORECASE,
    ),
]


def normalize_text(value: str) -> str:
    return (
        value
        .replace("\r\n", "\n")
        .replace("\r", "\n")
        .strip()
    )


def _modalities_in_text(text: str) -> list[str]:
    modalities = [
        modality
        for modality, pattern in MODALITY_PATTERNS.items()
        if pattern.search(text)
    ]

    if "echo" in modalities and "bikeErg" in modalities:
        modalities.remove("bikeErg")

    return modalities


def _workout_heading_text(
    programming_text: str,
) -> str:
    lines = normalize_text(programming_text).splitlines()

    heading = ""

    for line in lines:
        if WORKOUT_START_PATTERN.search(line):
            heading = line.strip()

    return heading


def _workout_programming_text(
    programming_text: str,
) -> str:
    lines = normalize_text(programming_text).splitlines()

    start_index = 0

    for index, line in enumerate(lines):
        if WORKOUT_START_PATTERN.search(line):
            start_index = index

    workout_lines: list[str] = []

    for line in lines[start_index:]:
        normalized_line = line.strip()

        if any(
            pattern.search(normalized_line)
            for pattern in PRIMARY_TEXT_STOP_PATTERNS
        ):
            break

        workout_lines.append(line)

    return "\n".join(workout_lines).strip()


def _prescription_line_modalities(
    programming_text: str,
) -> list[str]:
    lines = _workout_programming_text(
        programming_text,
    ).splitlines()

    for line in lines:
        if not re.search(
            r"\b(?:gear|zone\s*[12]|@\s*P[1-3])\b",
            line,
            re.IGNORECASE,
        ):
            continue

        modalities = _modalities_in_text(line)

        if len(modalities) == 1:
            return modalities

    return []


def detect_gears(programming_text: str) -> list[int]:
    gears = {
        int(match)
        for match in GEAR_WORD_PATTERN.findall(
            programming_text,
        )
    }

    gears.update(
        int(match)
        for match in GEAR_SHORT_PATTERN.findall(
            programming_text,
        )
    )

    return sorted(gears)


def detect_power_prescriptions(
    programming_text: str,
) -> list[int]:
    prescribed_matches = sorted(
        {
            int(match)
            for match in PRESCRIBED_POWER_PATTERN.findall(
                programming_text,
            )
        },
    )

    if prescribed_matches:
        return prescribed_matches

    return sorted(
        {
            int(match)
            for match in POWER_PATTERN.findall(
                programming_text,
            )
        },
    )


def detect_zone_prescriptions(
    programming_text: str,
) -> list[int]:
    workout_text = _workout_programming_text(
        programming_text,
    )

    return sorted(
        {
            int(match)
            for match in ZONE_PATTERN.findall(
                workout_text,
            )
        },
    )


def detect_modalities(
    programming_text: str,
) -> list[str]:
    prescription_modalities = _prescription_line_modalities(
        programming_text,
    )

    if prescription_modalities:
        return prescription_modalities

    heading_text = _workout_heading_text(
        programming_text,
    )
    heading_modalities = _modalities_in_text(
        heading_text,
    )

    if len(heading_modalities) == 1:
        return heading_modalities

    workout_text = _workout_programming_text(
        programming_text,
    )

    return _modalities_in_text(workout_text)


def detect_candidate_modalities(
    programming_text: str,
    result_text: str,
) -> list[str]:
    programming_modalities = detect_modalities(
        programming_text,
    )

    if programming_modalities:
        return programming_modalities

    return _modalities_in_text(
        normalize_text(result_text),
    )


def detect_workout_type(
    programming_text: str,
) -> WorkoutType:
    if detect_gears(programming_text):
        return WorkoutType.GEAR

    if detect_power_prescriptions(programming_text):
        return WorkoutType.POWER

    if detect_zone_prescriptions(programming_text):
        return WorkoutType.ZONE

    return WorkoutType.UNKNOWN


def detect_result_detail(
    result_text: str,
) -> ResultDetail:
    normalized = normalize_text(result_text)

    if not normalized:
        return ResultDetail.NONE

    has_average = bool(
        re.search(
            r"\b(?:avg|average|overall)\b",
            normalized,
            re.IGNORECASE,
        ),
    )

    has_intervals = bool(
        re.search(
            r"\b(?:round|rd|interval|set)\s*#?\s*\d+\b",
            normalized,
            re.IGNORECASE,
        )
        or re.search(
            r"(?:\d+(?::\d+)?(?:\.\d+)?\s*/){2,}"
            r"\d+(?::\d+)?(?:\.\d+)?",
            normalized,
            re.IGNORECASE,
        )
    )

    if has_average and has_intervals:
        return ResultDetail.MIXED

    if has_intervals:
        return ResultDetail.INTERVAL_RESULTS

    if has_average:
        return ResultDetail.WORKOUT_AVERAGE

    return ResultDetail.RESULT_TEXT_ONLY


def is_relevant_workout(
    programming_text: str,
) -> bool:
    return (
        detect_workout_type(programming_text)
        is not WorkoutType.UNKNOWN
    )


def classify_candidate(
    programming_text: str,
    result_text: str,
) -> tuple[ImportStatus, str]:
    normalized_result = normalize_text(result_text)

    if not normalized_result:
        return (
            ImportStatus.SKIP,
            "No result recorded",
        )

    if SKIP_RESULT_PATTERN.search(normalized_result):
        return (
            ImportStatus.SKIP,
            "Result indicates workout was not completed",
        )

    gears = detect_gears(programming_text)
    power_prescriptions = detect_power_prescriptions(
        programming_text,
    )
    zone_prescriptions = detect_zone_prescriptions(
        programming_text,
    )
    modalities = detect_candidate_modalities(
        programming_text=programming_text,
        result_text=result_text,
    )

    if len(gears) > 1:
        return (
            ImportStatus.TBD_LATER,
            "Mixed-gear workout",
        )

    if len(modalities) > 1:
        return (
            ImportStatus.TBD_LATER,
            "Mixed-modality workout",
        )

    if len(power_prescriptions) > 1:
        return (
            ImportStatus.TBD_LATER,
            "Multiple power prescriptions",
        )

    if len(zone_prescriptions) > 1:
        return (
            ImportStatus.TBD_LATER,
            "Multiple zone prescriptions",
        )

    if PARTIAL_RESULT_PATTERN.search(normalized_result):
        return (
            ImportStatus.REVIEW,
            "Result indicates partial completion",
        )

    if not modalities:
        return (
            ImportStatus.REVIEW,
            "Modality could not be detected",
        )

    return (
        ImportStatus.READY,
        "Single supported workout",
    )