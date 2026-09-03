from __future__ import annotations

import re

from benchmark_models import (
    BenchmarkCandidate,
    NormalizedBenchmarkAttempt,
)


_AVERAGE_WATTS_PATTERN = re.compile(
    r"\bAvg(?:erage)?\s+Watts?\s*[-:]\s*(?P<score>\d+)\b",
    re.IGNORECASE,
)

_AVERAGE_RPM_PATTERN = re.compile(
    r"\bAvg(?:erage)?\s+RPM\s*[-:]\s*(?P<rpm>\d+)\b",
    re.IGNORECASE,
)

_CALORIES_PATTERN = re.compile(
    r"(?:\bCals?\s*[-:]\s*(?P<labelled>\d+)\b|"
    r"\b(?P<prefix>\d+)\s+Cals?\b)",
    re.IGNORECASE,
)

_TOTAL_REPS_PATTERN = re.compile(
    r"\bTotal\s*-\s*(?P<score>\d+)"
    r"(?:\s*-\s*(?P<breakdown>\d+(?:/\d+)+))?",
    re.IGNORECASE,
)

_MOUNT_DOOM_PATTERN = re.compile(
    r"\bthrough\s+(?P<partial>\d+)\s+of\s+"
    r"(?:the\s+)?round\s+of\s+(?P<failed_round>\d+)\b",
    re.IGNORECASE,
)


def _matt_benchmark_id(
    candidate: BenchmarkCandidate,
) -> str:
    modalities = {
        value.strip().casefold()
        for value in candidate.modality.split("/")
        if value.strip()
    }

    if "echo" in modalities:
        return "matt_echo_bike"

    if "row" in modalities:
        return "matt_row"

    raise ValueError(
        "Unsupported M.A.T.T. modality: "
        f"{candidate.modality or '(unknown)'}"
    )


def _normalize_matt(
    candidate: BenchmarkCandidate,
) -> NormalizedBenchmarkAttempt:
    watts_match = _AVERAGE_WATTS_PATTERN.search(
        candidate.result_text,
    )

    if watts_match is None:
        raise ValueError(
            "M.A.T.T. result does not contain average watts"
        )

    detail_lines: list[str] = []

    rpm_match = _AVERAGE_RPM_PATTERN.search(
        candidate.result_text,
    )
    if rpm_match is not None:
        detail_lines.append(
            f"Average RPM - {rpm_match.group('rpm')}"
        )

    calories_match = _CALORIES_PATTERN.search(
        candidate.result_text,
    )
    if calories_match is not None:
        calories = (
            calories_match.group("labelled")
            or calories_match.group("prefix")
        )
        detail_lines.append(f"Calories - {calories}")

    return NormalizedBenchmarkAttempt(
        benchmark_id=_matt_benchmark_id(candidate),
        date=candidate.date,
        score=watts_match.group("score"),
        source_workbook=candidate.source_workbook,
        program_day=candidate.program_day,
        details="\n".join(detail_lines),
        notes=candidate.result_text,
    )


def _normalize_cube_steaked(
    candidate: BenchmarkCandidate,
) -> NormalizedBenchmarkAttempt:
    match = _TOTAL_REPS_PATTERN.search(
        candidate.result_text,
    )

    if match is None:
        raise ValueError(
            "Cube Steaked result does not contain a total score"
        )

    breakdown = match.group("breakdown")
    details = (
        f"Round breakdown - {breakdown}"
        if breakdown
        else ""
    )

    return NormalizedBenchmarkAttempt(
        benchmark_id="cube_steaked",
        date=candidate.date,
        score=match.group("score"),
        source_workbook=candidate.source_workbook,
        program_day=candidate.program_day,
        details=details,
        notes=candidate.result_text,
    )


def _mount_doom_score(
    partial: int,
    failed_round: int,
    starting_calories: int = 20,
) -> int:
    if failed_round < starting_calories:
        raise ValueError(
            "Mount Doom failed round is below its starting calories"
        )

    if partial < 0 or partial >= failed_round:
        raise ValueError(
            "Mount Doom partial calories must be below "
            "the failed-round target"
        )

    completed_total = sum(
        range(starting_calories, failed_round)
    )

    return completed_total + partial


def _normalize_row_mount_doom(
    candidate: BenchmarkCandidate,
) -> NormalizedBenchmarkAttempt:
    match = _MOUNT_DOOM_PATTERN.search(
        candidate.result_text,
    )

    if match is None:
        raise ValueError(
            "Row Mount Doom result does not identify "
            "the failed round"
        )

    partial = int(match.group("partial"))
    failed_round = int(match.group("failed_round"))
    score = _mount_doom_score(
        partial=partial,
        failed_round=failed_round,
    )

    last_completed_round = failed_round - 1

    return NormalizedBenchmarkAttempt(
        benchmark_id="row_mount_doom",
        date=candidate.date,
        score=str(score),
        source_workbook=candidate.source_workbook,
        program_day=candidate.program_day,
        details=(
            "Completed rounds 20 through "
            f"{last_completed_round} calories, then completed "
            f"{partial} of {failed_round} calories in the "
            "failed round."
        ),
        notes=candidate.result_text,
    )


def normalize_benchmark_candidate(
    candidate: BenchmarkCandidate,
) -> NormalizedBenchmarkAttempt | None:
    if candidate.result_status != "selected":
        return None

    if not candidate.result_text:
        return None

    if not candidate.date:
        raise ValueError(
            "Benchmark candidate does not have a resolved date"
        )

    if candidate.benchmark_key == "matt":
        return _normalize_matt(candidate)

    if candidate.benchmark_key == "cube_steaked":
        return _normalize_cube_steaked(candidate)

    if candidate.benchmark_key == "row_mount_doom":
        return _normalize_row_mount_doom(candidate)

    if candidate.benchmark_key == "power_output_bike_test":
        raise ValueError(
            "Power Output Bike Test has a recorded result, "
            "but no supported result parser"
        )

    raise ValueError(
        "Unsupported benchmark normalization: "
        f"{candidate.benchmark_key}"
    )


def normalize_benchmark_candidates(
    candidates: list[BenchmarkCandidate],
) -> list[NormalizedBenchmarkAttempt]:
    attempts: list[NormalizedBenchmarkAttempt] = []

    for candidate in candidates:
        attempt = normalize_benchmark_candidate(candidate)

        if attempt is not None:
            attempts.append(attempt)

    return attempts
