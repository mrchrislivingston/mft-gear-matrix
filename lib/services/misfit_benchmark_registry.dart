class MisfitBenchmarkRegistryEntry {
  final String key;
  final String displayName;
  final List<String> aliases;

  const MisfitBenchmarkRegistryEntry({
    required this.key,
    required this.displayName,
    required this.aliases,
  });
}

class MisfitBenchmarkRegistry {
  const MisfitBenchmarkRegistry();

  static const entries = <MisfitBenchmarkRegistryEntry>[
    MisfitBenchmarkRegistryEntry(
      key: "matt",
      displayName: "M.A.T.T.",
      aliases: [
        "MATT",
        "MATT Test",
        "M.A.T.T.",
        "M.A.T.T. Test",
        "M. A. T. T.",
        "M. A. T. T. Test",
      ],
    ),
    MisfitBenchmarkRegistryEntry(
      key: "power_output_bike_test",
      displayName: "Power Output C2 Bike Test",
      aliases: [
        "Power Output Bike Test",
        "Power Output C2 Bike Test",
        "C2 Bike Power Output Test",
        "BikeErg Power Output Test",
        "Bike Erg Power Output Test",
      ],
    ),
    MisfitBenchmarkRegistryEntry(
      key: "power_output_echo_bike_test",
      displayName: "Power Output Echo Bike Test",
      aliases: ["Power Output Echo Bike Test", "Echo Bike Power Output Test"],
    ),
    MisfitBenchmarkRegistryEntry(
      key: "power_output_ski_test",
      displayName: "Power Output Ski Test",
      aliases: [
        "Power Output Ski Test",
        "Power Output SkiErg Test",
        "Ski Power Output Test",
        "SkiErg Power Output Test",
        "Ski Erg Power Output Test",
      ],
    ),
    MisfitBenchmarkRegistryEntry(
      key: "power_output_row_test",
      displayName: "Power Output Row Test",
      aliases: [
        "Power Output Row Test",
        "Power Output Rower Test",
        "Row Power Output Test",
        "Rower Power Output Test",
      ],
    ),
    MisfitBenchmarkRegistryEntry(
      key: "cleo",
      displayName: "Cleo",
      aliases: ["Cleo"],
    ),
    MisfitBenchmarkRegistryEntry(
      key: "speed_not_volume",
      displayName: "Speed, Not Volume",
      aliases: ["Speed, Not Volume", "Speed Not Volume"],
    ),
    MisfitBenchmarkRegistryEntry(
      key: "rule_8",
      displayName: "Rule 8",
      aliases: ["Rule 8", "Rule Eight"],
    ),
    MisfitBenchmarkRegistryEntry(
      key: "echo_bike_cube_test",
      displayName: "Echo Bike Cube Test",
      aliases: ["Echo Bike Cube Test", "Echo Cube Test"],
    ),
    MisfitBenchmarkRegistryEntry(
      key: "bike_mount_doom",
      displayName: "Bike Mount Doom",
      aliases: [
        "Bike Mount Doom",
        "C2 Bike Mount Doom",
        "BikeErg Mount Doom",
        "Bike Erg Mount Doom",
      ],
    ),
    MisfitBenchmarkRegistryEntry(
      key: "ski_cube_test",
      displayName: "Ski Cube Test",
      aliases: ["Ski Cube Test", "SkiErg Cube Test", "Ski Erg Cube Test"],
    ),
    MisfitBenchmarkRegistryEntry(
      key: "c2_bike_cube_test",
      displayName: "C2 Bike Cube Test",
      aliases: ["C2 Bike Cube Test", "BikeErg Cube Test", "Bike Erg Cube Test"],
    ),
    MisfitBenchmarkRegistryEntry(
      key: "row_cube_test",
      displayName: "Row Cube Test",
      aliases: ["Row Cube Test", "Rower Cube Test"],
    ),
    MisfitBenchmarkRegistryEntry(
      key: "run_cube_test",
      displayName: "Run Cube Test",
      aliases: ["Run Cube Test", "Runner Cube Test"],
    ),
    MisfitBenchmarkRegistryEntry(
      key: "cube_steaked",
      displayName: "Cube Steaked",
      aliases: ["Cube Steaked"],
    ),
    MisfitBenchmarkRegistryEntry(
      key: "runner_mount_doom",
      displayName: "Runner Mount Doom",
      aliases: ["Runner Mount Doom", "Run Mount Doom"],
    ),
    MisfitBenchmarkRegistryEntry(
      key: "ski_mount_doom",
      displayName: "Ski Mount Doom",
      aliases: ["Ski Mount Doom", "SkiErg Mount Doom", "Ski Erg Mount Doom"],
    ),
    MisfitBenchmarkRegistryEntry(
      key: "row_mount_doom",
      displayName: "Row Mount Doom",
      aliases: ["Row Mount Doom", "Rower Mount Doom"],
    ),
    MisfitBenchmarkRegistryEntry(
      key: "echo_bike_mount_doom",
      displayName: "Echo Bike Mount Doom",
      aliases: ["Echo Bike Mount Doom", "Echo Mount Doom"],
    ),
    MisfitBenchmarkRegistryEntry(
      key: "kill_o_meter",
      displayName: "Kill-O-Meter",
      aliases: ["Kill-O-Meter", "Kill O Meter", "Killometer"],
    ),
    MisfitBenchmarkRegistryEntry(
      key: "kill_o_watt",
      displayName: "Kill-O-Watt",
      aliases: ["Kill-O-Watt", "Kill O Watt", "Killowatt"],
    ),
    MisfitBenchmarkRegistryEntry(
      key: "spiders_on_mars",
      displayName: "Spiders on Mars",
      aliases: ["Spiders on Mars"],
    ),
    MisfitBenchmarkRegistryEntry(
      key: "tour_de_misfit",
      displayName: "Tour de Misfit",
      aliases: ["Tour de Misfit"],
    ),
    MisfitBenchmarkRegistryEntry(
      key: "riverside_time_trial",
      displayName: "Riverside Time Trial",
      aliases: ["Riverside Time Trial"],
    ),
    MisfitBenchmarkRegistryEntry(
      key: "enzo_gorlomi",
      displayName: "Enzo Gorlomi",
      aliases: ["Enzo Gorlomi"],
    ),
    MisfitBenchmarkRegistryEntry(
      key: "cupcake_lungs",
      displayName: "Cupcake Lungs",
      aliases: ["Cupcake Lungs"],
    ),
    MisfitBenchmarkRegistryEntry(
      key: "might_not",
      displayName: "Might Not",
      aliases: ["Might Not"],
    ),
    MisfitBenchmarkRegistryEntry(
      key: "bumper_cables",
      displayName: "Bumper Cables",
      aliases: ["Bumper Cables"],
    ),
    MisfitBenchmarkRegistryEntry(
      key: "pennies",
      displayName: "Pennies",
      aliases: ["Pennies"],
    ),
    MisfitBenchmarkRegistryEntry(
      key: "continental_drive_75",
      displayName: "75 Continental Drive",
      aliases: ["75 Continental Drive"],
    ),
    MisfitBenchmarkRegistryEntry(
      key: "king_larry_i",
      displayName: "King Larry I",
      aliases: ["King Larry I", "King Larry 1"],
    ),
    MisfitBenchmarkRegistryEntry(
      key: "chuckles_1_2",
      displayName: "Chuckles 1 & 2",
      aliases: ["Chuckles 1 & 2", "Chuckles 1&2", "Chuckles 1 and 2"],
    ),
    MisfitBenchmarkRegistryEntry(
      key: "hurt_and_injured",
      displayName: "Hurt and Injured",
      aliases: ["Hurt and Injured", "Hurt & Injured"],
    ),
    MisfitBenchmarkRegistryEntry(
      key: "fairy_dust",
      displayName: "Fairy Dust",
      aliases: ["Fairy Dust"],
    ),
  ];

  List<MisfitBenchmarkRegistryEntry> findMatches(Iterable<String> textValues) {
    final values = textValues.toList(growable: false);
    final rawMatches = <({MisfitBenchmarkRegistryEntry entry, String alias})>[];

    for (final entry in entries) {
      final matchingAliases = entry.aliases
          .map(normalizeText)
          .where(
            (alias) =>
                alias.isNotEmpty &&
                values.any((text) => _containsNormalizedAlias(text, alias)),
          )
          .toList();

      if (matchingAliases.isEmpty) {
        continue;
      }

      matchingAliases.sort((left, right) {
        final wordComparison = right
            .split(' ')
            .length
            .compareTo(left.split(' ').length);
        return wordComparison != 0
            ? wordComparison
            : right.length.compareTo(left.length);
      });

      rawMatches.add((entry: entry, alias: matchingAliases.first));
    }

    return rawMatches
        .where((match) {
          return !rawMatches.any((other) {
            return other.entry.key != match.entry.key &&
                other.alias != match.alias &&
                ' ${other.alias} '.contains(' ${match.alias} ');
          });
        })
        .map((match) => match.entry)
        .toList(growable: false);
  }

  String normalizeText(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  bool _containsNormalizedAlias(String text, String normalizedAlias) {
    final normalizedText = normalizeText(text);
    if (normalizedText.isEmpty || normalizedAlias.isEmpty) {
      return false;
    }

    return ' $normalizedText '.contains(' $normalizedAlias ');
  }
}
