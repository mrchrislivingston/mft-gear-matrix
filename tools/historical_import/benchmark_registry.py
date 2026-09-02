from __future__ import annotations

import re
from dataclasses import dataclass


@dataclass(frozen=True)
class BenchmarkRegistryEntry:
    key: str
    display_name: str
    aliases: tuple[str, ...]


BENCHMARK_REGISTRY = (
    BenchmarkRegistryEntry(
        key="matt",
        display_name="M.A.T.T.",
        aliases=(
            "MATT",
            "MATT Test",
            "M.A.T.T.",
            "M.A.T.T. Test",
            "M. A. T. T.",
            "M. A. T. T. Test",
        ),
    ),
    BenchmarkRegistryEntry(
        key="cleo",
        display_name="Cleo",
        aliases=("Cleo",),
    ),
    BenchmarkRegistryEntry(
        key="speed_not_volume",
        display_name="Speed, Not Volume",
        aliases=(
            "Speed, Not Volume",
            "Speed Not Volume",
        ),
    ),
    BenchmarkRegistryEntry(
        key="rule_8",
        display_name="Rule 8",
        aliases=(
            "Rule 8",
            "Rule Eight",
        ),
    ),
    BenchmarkRegistryEntry(
        key="echo_bike_cube_test",
        display_name="Echo Bike Cube Test",
        aliases=(
            "Echo Bike Cube Test",
            "Echo Cube Test",
        ),
    ),
    BenchmarkRegistryEntry(
        key="bike_mount_doom",
        display_name="Bike Mount Doom",
        aliases=(
            "Bike Mount Doom",
            "C2 Bike Mount Doom",
            "BikeErg Mount Doom",
            "Bike Erg Mount Doom",
        ),
    ),

    BenchmarkRegistryEntry(
        key="ski_cube_test",
        display_name="Ski Cube Test",
        aliases=(
            "Ski Cube Test",
            "SkiErg Cube Test",
            "Ski Erg Cube Test",
        ),
    ),
    BenchmarkRegistryEntry(
        key="c2_bike_cube_test",
        display_name="C2 Bike Cube Test",
        aliases=(
            "C2 Bike Cube Test",
            "BikeErg Cube Test",
            "Bike Erg Cube Test",
        ),
    ),
    BenchmarkRegistryEntry(
        key="row_cube_test",
        display_name="Row Cube Test",
        aliases=(
            "Row Cube Test",
            "Rower Cube Test",
        ),
    ),
    BenchmarkRegistryEntry(
        key="run_cube_test",
        display_name="Run Cube Test",
        aliases=(
            "Run Cube Test",
            "Runner Cube Test",
        ),
    ),
    BenchmarkRegistryEntry(
        key="cube_steaked",
        display_name="Cube Steaked",
        aliases=("Cube Steaked",),
    ),
    BenchmarkRegistryEntry(
        key="runner_mount_doom",
        display_name="Runner Mount Doom",
        aliases=(
            "Runner Mount Doom",
            "Run Mount Doom",
        ),
    ),
    BenchmarkRegistryEntry(
        key="ski_mount_doom",
        display_name="Ski Mount Doom",
        aliases=(
            "Ski Mount Doom",
            "SkiErg Mount Doom",
            "Ski Erg Mount Doom",
        ),
    ),
    BenchmarkRegistryEntry(
        key="row_mount_doom",
        display_name="Row Mount Doom",
        aliases=(
            "Row Mount Doom",
            "Rower Mount Doom",
        ),
    ),
    BenchmarkRegistryEntry(
        key="echo_bike_mount_doom",
        display_name="Echo Bike Mount Doom",
        aliases=(
            "Echo Bike Mount Doom",
            "Echo Mount Doom",
        ),
    ),
    BenchmarkRegistryEntry(
        key="kill_o_meter",
        display_name="Kill-O-Meter",
        aliases=(
            "Kill-O-Meter",
            "Kill O Meter",
            "Killometer",
        ),
    ),
    BenchmarkRegistryEntry(
        key="kill_o_watt",
        display_name="Kill-O-Watt",
        aliases=(
            "Kill-O-Watt",
            "Kill O Watt",
            "Killowatt",
        ),
    ),
    BenchmarkRegistryEntry(
        key="spiders_on_mars",
        display_name="Spiders on Mars",
        aliases=("Spiders on Mars",),
    ),
    BenchmarkRegistryEntry(
        key="tour_de_misfit",
        display_name="Tour de Misfit",
        aliases=("Tour de Misfit",),
    ),
    BenchmarkRegistryEntry(
        key="riverside_time_trial",
        display_name="Riverside Time Trial",
        aliases=("Riverside Time Trial",),
    ),
    BenchmarkRegistryEntry(
        key="enzo_gorlomi",
        display_name="Enzo Gorlomi",
        aliases=("Enzo Gorlomi",),
    ),
    BenchmarkRegistryEntry(
        key="cupcake_lungs",
        display_name="Cupcake Lungs",
        aliases=("Cupcake Lungs",),
    ),
    BenchmarkRegistryEntry(
        key="might_not",
        display_name="Might Not",
        aliases=("Might Not",),
    ),
    BenchmarkRegistryEntry(
        key="bumper_cables",
        display_name="Bumper Cables",
        aliases=("Bumper Cables",),
    ),
    BenchmarkRegistryEntry(
        key="pennies",
        display_name="Pennies",
        aliases=("Pennies",),
    ),
    BenchmarkRegistryEntry(
        key="continental_drive_75",
        display_name="75 Continental Drive",
        aliases=("75 Continental Drive",),
    ),
    BenchmarkRegistryEntry(
        key="king_larry_i",
        display_name="King Larry I",
        aliases=(
            "King Larry I",
            "King Larry 1",
        ),
    ),
    BenchmarkRegistryEntry(
        key="chuckles_1_2",
        display_name="Chuckles 1 & 2",
        aliases=(
            "Chuckles 1 & 2",
            "Chuckles 1&2",
            "Chuckles 1 and 2",
        ),
    ),
    BenchmarkRegistryEntry(
        key="hurt_and_injured",
        display_name="Hurt and Injured",
        aliases=(
            "Hurt and Injured",
            "Hurt & Injured",
        ),
    ),
    BenchmarkRegistryEntry(
        key="fairy_dust",
        display_name="Fairy Dust",
        aliases=("Fairy Dust",),
    ),

)


def normalize_benchmark_text(value: str) -> str:
    normalized = value.casefold()
    normalized = re.sub(r"[^a-z0-9]+", " ", normalized)
    return re.sub(r"\s+", " ", normalized).strip()


def _contains_alias(text: str, alias: str) -> bool:
    normalized_text = normalize_benchmark_text(text)
    normalized_alias = normalize_benchmark_text(alias)

    if not normalized_text or not normalized_alias:
        return False

    return (
        f" {normalized_alias} "
        in f" {normalized_text} "
    )


def _best_matching_alias(
    entry: BenchmarkRegistryEntry,
    text_values: tuple[str, ...],
) -> str:
    matching_aliases = [
        normalize_benchmark_text(alias)
        for alias in entry.aliases
        if any(
            _contains_alias(text, alias)
            for text in text_values
        )
    ]

    if not matching_aliases:
        return ""

    return max(
        matching_aliases,
        key=lambda alias: (
            len(alias.split()),
            len(alias),
        ),
    )


def find_benchmark_matches(
    *text_values: str,
) -> tuple[BenchmarkRegistryEntry, ...]:
    raw_matches: list[
        tuple[BenchmarkRegistryEntry, str]
    ] = []

    for entry in BENCHMARK_REGISTRY:
        matched_alias = _best_matching_alias(
            entry,
            text_values,
        )

        if matched_alias:
            raw_matches.append(
                (entry, matched_alias)
            )

    matches: list[BenchmarkRegistryEntry] = []

    for entry, matched_alias in raw_matches:
        contained_by_more_specific_alias = any(
            other_entry.key != entry.key
            and matched_alias != other_alias
            and (
                f" {matched_alias} "
                in f" {other_alias} "
            )
            for other_entry, other_alias in raw_matches
        )

        if not contained_by_more_specific_alias:
            matches.append(entry)

    return tuple(matches)
