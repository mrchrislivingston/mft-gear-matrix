import 'fitr_mobile_client.dart';

typedef FitrClassification = Map<String, Object?>;

const _ordinalGears = {
  '1st': 'G1',
  '2nd': 'G2',
  '3rd': 'G3',
  '4th': 'G4',
  '5th': 'G5',
  '6th': 'G6',
  '7th': 'G7',
  '8th': 'G8',
};

final _modalityPatterns = <(String, RegExp)>[
  (
    'C2 Bike',
    RegExp(
      r'\b(?:c2|bikeerg|bike erg)\s*bike\b|\bc2 bike\b',
      caseSensitive: false,
    ),
  ),
  ('Echo Bike', RegExp(r'\becho(?: bike)?\b', caseSensitive: false)),
  ('Row', RegExp(r'\brow(?:ing)?\b', caseSensitive: false)),
  ('Ski', RegExp(r'\bski(?:erg)?\b', caseSensitive: false)),
  ('Run', RegExp(r'\brun(?:ning)?\b', caseSensitive: false)),
];

int parseFitrTime(String value) {
  final cleaned = value.trim();

  if (cleaned.startsWith(':')) {
    return int.parse(cleaned.substring(1));
  }

  final parts = cleaned.split(':');
  if (parts.length != 2) {
    throw FormatException('Invalid FITR time: $value');
  }

  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

String fitrSectionTitle(Map<String, dynamic> section) {
  final title = section['title'];
  if (title is String && title.trim().isNotEmpty) {
    return title.trim();
  }

  final challenge = section['challenge'];
  if (challenge is Map) {
    final challengeTitle = challenge['title'];
    if (challengeTitle is String && challengeTitle.trim().isNotEmpty) {
      return challengeTitle.trim();
    }
  }

  return '(untitled)';
}

String fitrSectionDescription(Map<String, dynamic> section) {
  final description = section['description'];
  if (description is String && description.trim().isNotEmpty) {
    return description.trim();
  }

  final challenge = section['challenge'];
  if (challenge is Map) {
    final challengeDescription = challenge['description'];
    if (challengeDescription is String) {
      return challengeDescription.trim();
    }
  }

  return '';
}

String fitrSectionText(Map<String, dynamic> section) {
  return '${fitrSectionTitle(section)}\n'
      '${fitrSectionDescription(section)}';
}

String? detectFitrModality(String text) {
  final usefulLines = <String>[];

  for (final line in text.split(RegExp(r'\r?\n'))) {
    final cleaned = line.trim();
    if (cleaned.isEmpty) {
      continue;
    }

    final lower = cleaned.toLowerCase();
    if (lower.startsWith('equipment modification')) {
      break;
    }

    if (lower.contains('flush on')) {
      continue;
    }

    usefulLines.add(cleaned);
  }

  final primaryText = usefulLines.join('\n');
  final found = <String>{};

  for (final (modality, pattern) in _modalityPatterns) {
    if (pattern.hasMatch(primaryText)) {
      found.add(modality);
    }
  }

  return found.length == 1 ? found.single : null;
}

String? detectFitrGear(String text) {
  final compact = RegExp(
    r'\bG([1-8])\b',
    caseSensitive: false,
  ).firstMatch(text);

  if (compact != null) {
    return 'G${compact.group(1)}';
  }

  final ordinal = RegExp(
    r'\b(1st|2nd|3rd|4th|5th|6th|7th|8th)\s+Gear\b',
    caseSensitive: false,
  ).firstMatch(text);

  if (ordinal == null) {
    return null;
  }

  return _ordinalGears[ordinal.group(1)!.toLowerCase()];
}

String? detectFitrPower(String text) {
  final match = RegExp(r'\bP([1-3])\b', caseSensitive: false).firstMatch(text);

  return match == null ? null : 'P${match.group(1)}';
}

FitrClassification _candidate({
  required String type,
  required String prescription,
  required String modality,
  required String sourceTitle,
  Map<String, Object?> values = const {},
}) {
  return {
    'status': 'CANDIDATE',
    'type': type,
    'prescription': prescription,
    'modality': modality,
    'source_title': sourceTitle,
    ...values,
  };
}

FitrClassification _skip({
  required String reason,
  required String sourceTitle,
}) {
  return {'status': 'SKIP', 'reason': reason, 'source_title': sourceTitle};
}

FitrClassification? _classifyMixedRunGear(String text, String sourceTitle) {
  final structure = RegExp(
    r'AMRAP\s+(\d+:\d{2})\s*[xX]\s*(\d+)'
    r'.*?Run\s+for\s+Meters\s+@\s+'
    r'(1st|2nd|3rd|4th|5th|6th|7th|8th)\s+Gear'
    r'.*?\bRest\s+(\d+:\d{2})'
    r'.*?\bRest\s+(\d+:\d{2})\s+after\s+round\s+(\d+)\s*,?\s*Then'
    r'.*?AMRAP\s+(\d+:\d{2})\s*[xX]\s*(\d+)'
    r'.*?Run\s+for\s+Meters\s+@\s+'
    r'(1st|2nd|3rd|4th|5th|6th|7th|8th)\s+Gear'
    r'.*?\bRest\s+(\d+:\d{2})',
    caseSensitive: false,
    dotAll: true,
  ).firstMatch(text);

  if (structure == null) {
    return null;
  }

  final firstRounds = int.parse(structure.group(2)!);
  final transitionAfterRound = int.parse(structure.group(6)!);
  final secondRounds = int.parse(structure.group(8)!);

  if (transitionAfterRound != firstRounds) {
    return _skip(
      reason: 'Mixed Gear transition round does not match first block',
      sourceTitle: sourceTitle,
    );
  }

  final firstGear = _ordinalGears[structure.group(3)!.toLowerCase()]!;
  final secondGear = _ordinalGears[structure.group(9)!.toLowerCase()]!;
  final firstWorkSeconds = parseFitrTime(structure.group(1)!);
  final firstRestSeconds = parseFitrTime(structure.group(4)!);
  final transitionRestSeconds = parseFitrTime(structure.group(5)!);
  final secondWorkSeconds = parseFitrTime(structure.group(7)!);
  final secondRestSeconds = parseFitrTime(structure.group(10)!);

  final steps = <Map<String, Object?>>[];

  for (var round = 0; round < firstRounds; round++) {
    steps.add({
      'kind': 'work',
      'prescription': firstGear,
      'modality': 'Run',
      'seconds': firstWorkSeconds,
    });

    steps.add({
      'kind': 'recovery',
      'seconds': round < firstRounds - 1
          ? firstRestSeconds
          : transitionRestSeconds,
    });
  }

  for (var round = 0; round < secondRounds; round++) {
    steps.add({
      'kind': 'work',
      'prescription': secondGear,
      'modality': 'Run',
      'seconds': secondWorkSeconds,
    });

    if (round < secondRounds - 1) {
      steps.add({'kind': 'recovery', 'seconds': secondRestSeconds});
    }
  }

  return _candidate(
    type: 'MIXED_GEAR',
    prescription: '$firstGear-$secondGear',
    modality: 'Run',
    sourceTitle: sourceTitle,
    values: {'rounds': firstRounds + secondRounds, 'steps': steps},
  );
}

FitrClassification? _classifyMixedGear(
  String text,
  String gear,
  String sourceTitle,
) {
  final structure = RegExp(
    r'AMRAP\s+(\d+:\d{2})\s+'
    r'Ski\s+for\s+Meters\s+@\s+\d+(?:st|nd|rd|th)\s+Gear'
    r'.*?\bRest\s+(\d+:\d{2})'
    r'.*?AMRAP\s+(\d+:\d{2})\s+'
    r'C2\s+Bike\s+for\s+Meters\s+@\s+\d+(?:st|nd|rd|th)\s+Gear'
    r'.*?\bRest\s+(\d+:\d{2})'
    r'.*?\bThen\s+(\d+)\s+Rounds?'
    r'.*?AMRAP\s+(\d+:\d{2})\s+'
    r'Ski\s+for\s+Meters\s+@\s+\d+(?:st|nd|rd|th)\s+Gear'
    r'.*?Directly\s+into'
    r'.*?AMRAP\s+(\d+:\d{2})\s+'
    r'C2\s+Bike\s+for\s+Meters\s+@\s+\d+(?:st|nd|rd|th)\s+Gear'
    r'.*?\bRest\s+(\d+:\d{2})',
    caseSensitive: false,
    dotAll: true,
  ).firstMatch(text);

  if (structure == null) {
    return null;
  }

  final splitRounds = int.parse(structure.group(5)!);
  final splitRestSeconds = parseFitrTime(structure.group(8)!);

  final steps = <Map<String, Object?>>[
    {
      'kind': 'work',
      'modality': 'Ski',
      'seconds': parseFitrTime(structure.group(1)!),
    },
    {'kind': 'recovery', 'seconds': parseFitrTime(structure.group(2)!)},
    {
      'kind': 'work',
      'modality': 'C2 Bike',
      'seconds': parseFitrTime(structure.group(3)!),
    },
    {'kind': 'recovery', 'seconds': parseFitrTime(structure.group(4)!)},
  ];

  for (var roundIndex = 0; roundIndex < splitRounds; roundIndex++) {
    steps.addAll([
      {
        'kind': 'work',
        'modality': 'Ski',
        'seconds': parseFitrTime(structure.group(6)!),
      },
      {
        'kind': 'work',
        'modality': 'C2 Bike',
        'seconds': parseFitrTime(structure.group(7)!),
      },
    ]);

    if (roundIndex < splitRounds - 1) {
      steps.add({'kind': 'recovery', 'seconds': splitRestSeconds});
    }
  }

  return _candidate(
    type: 'MIXED_GEAR',
    prescription: gear,
    modality: 'Ski + C2 Bike',
    sourceTitle: sourceTitle,
    values: {'rounds': 2 + splitRounds, 'steps': steps},
  );
}

FitrClassification? _classifyGear(Map<String, dynamic> section) {
  final text = fitrSectionText(section);
  final gear = detectFitrGear(text);

  if (gear == null) {
    return null;
  }

  final sourceTitle = fitrSectionTitle(section);

  final mixedRun = _classifyMixedRunGear(text, sourceTitle);
  if (mixedRun != null) {
    return mixedRun;
  }

  final mixed = _classifyMixedGear(text, gear, sourceTitle);
  if (mixed != null) {
    return mixed;
  }

  final modality = detectFitrModality(text);
  if (modality == null) {
    return _skip(
      reason: 'Gear detected but modality is ambiguous',
      sourceTitle: sourceTitle,
    );
  }

  final structure = RegExp(
    r'AMRAP\s+(:?\d*:\d{2})\s*[xX]\s*(\d+)',
    caseSensitive: false,
  ).firstMatch(text);

  final rest = RegExp(
    r'\bRest\s+(:?\d*:\d{2})',
    caseSensitive: false,
  ).firstMatch(text);

  if (structure == null || rest == null) {
    return _skip(
      reason: 'Gear detected but explicit FITR timing could not be parsed',
      sourceTitle: sourceTitle,
    );
  }

  return _candidate(
    type: 'GEAR',
    prescription: gear,
    modality: modality,
    sourceTitle: sourceTitle,
    values: {
      'rounds': int.parse(structure.group(2)!),
      'work_seconds': parseFitrTime(structure.group(1)!),
      'rest_seconds': parseFitrTime(rest.group(1)!),
    },
  );
}

String? _normalizePowerModality(String rawModality) {
  final lower = rawModality.toLowerCase();

  if (lower.startsWith('row')) {
    return 'Row';
  }
  if (lower.startsWith('ski')) {
    return 'Ski';
  }
  if (lower.startsWith('echo')) {
    return 'Echo Bike';
  }
  if (lower.startsWith('c2')) {
    return 'C2 Bike';
  }
  if (lower.startsWith('run')) {
    return 'Run';
  }

  return null;
}

FitrClassification? _classifyPower(Map<String, dynamic> section) {
  final text = fitrSectionText(section);
  final power = detectFitrPower(text);

  if (power == null) {
    return null;
  }

  final sourceTitle = fitrSectionTitle(section);
  final powers = RegExp(
    r'\bP[1-3]\b',
    caseSensitive: false,
  ).allMatches(text).map((match) => match.group(0)!.toUpperCase()).toSet();

  if (powers.length != 1) {
    return _skip(reason: 'Mixed Power prescriptions', sourceTitle: sourceTitle);
  }

  final every = RegExp(
    r'Every\s+(:?\d*:\d{2})\s+(?:for|x)\s+(\d+)'
    r'(?:\s+Rounds?)?',
    caseSensitive: false,
  ).firstMatch(text);

  if (every == null) {
    return _skip(
      reason: 'Power detected but Every/round structure could not be parsed',
      sourceTitle: sourceTitle,
    );
  }

  final workPatterns = [
    RegExp(
      r'(?:(?:Max\s+)?Calorie\s+)?'
      r'(Row|Ski)\s+(?:for\s+Calories\s+)?'
      r'in\s+(:?\d*:\d{2})\s+@\s*(P[1-3])',
      caseSensitive: false,
    ),
    RegExp(
      r'(Echo(?:\s+Bike)?|C2\s+Bike)\s+for\s+Calories\s+'
      r'in\s+(:?\d*:\d{2})\s+@\s*(P[1-3])',
      caseSensitive: false,
    ),
    RegExp(
      r'Max\s+Calorie\s+(Echo(?:\s+Bike)?|C2\s+Bike)\s+'
      r'in\s+(:?\d*:\d{2})\s+@\s*(P[1-3])',
      caseSensitive: false,
    ),
    RegExp(
      r'(Run)\s+.*?in\s+(:?\d*:\d{2})\s+@\s*(P[1-3])',
      caseSensitive: false,
    ),
  ];

  RegExpMatch? workMatch;
  for (final pattern in workPatterns) {
    workMatch = pattern.firstMatch(text);
    if (workMatch != null) {
      break;
    }
  }

  if (workMatch == null) {
    return _skip(
      reason: 'Power work interval/modality could not be parsed',
      sourceTitle: sourceTitle,
    );
  }

  final modality = _normalizePowerModality(workMatch.group(1)!);
  if (modality == null) {
    return _skip(reason: 'Unknown Power modality', sourceTitle: sourceTitle);
  }

  final everySeconds = parseFitrTime(every.group(1)!);
  final workSeconds = parseFitrTime(workMatch.group(2)!);
  final recoverySeconds = everySeconds - workSeconds;

  if (recoverySeconds < 0) {
    return _skip(
      reason: 'Power work duration exceeds interval duration',
      sourceTitle: sourceTitle,
    );
  }

  return _candidate(
    type: 'POWER',
    prescription: power,
    modality: modality,
    sourceTitle: sourceTitle,
    values: {
      'rounds': int.parse(every.group(2)!),
      'work_seconds': workSeconds,
      'recovery_seconds': recoverySeconds,
    },
  );
}

FitrClassification? _classifyZone2(Map<String, dynamic> section) {
  final text = fitrSectionText(section);

  if (!RegExp(r'\bZone\s*2\b', caseSensitive: false).hasMatch(text)) {
    return null;
  }

  final sourceTitle = fitrSectionTitle(section);
  final modalityMatch = RegExp(
    r'Zone\s*2\s*-\s*(C2 Bike|Echo Bike|Row|Ski|Run)\b',
    caseSensitive: false,
  ).firstMatch(text);

  if (modalityMatch == null) {
    return _skip(
      reason: 'Zone 2 modality is ambiguous',
      sourceTitle: sourceTitle,
    );
  }

  final modality = switch (modalityMatch.group(1)!.toLowerCase()) {
    'c2 bike' => 'C2 Bike',
    'echo bike' => 'Echo Bike',
    'row' => 'Row',
    'ski' => 'Ski',
    'run' => 'Run',
    _ => throw StateError('Unhandled Zone 2 modality'),
  };

  final warmup = RegExp(
    r'(\d+:\d{2})\s+Zone\s*2\s+Warm\s*Up',
    caseSensitive: false,
  ).firstMatch(text);

  final work = RegExp(
    r'(\d+:\d{2})(?:\s*[-–]\s*(\d+:\d{2}))?\s+' +
        RegExp.escape(modality) +
        r'\s+@\s+Zone\s*2',
    caseSensitive: false,
  ).firstMatch(text);

  final cooldown = RegExp(
    r'(\d+:\d{2})\s+Zone\s*2\s+Cool\s*Down',
    caseSensitive: false,
  ).firstMatch(text);

  if (work == null) {
    return _skip(
      reason: 'Zone 2 working duration could not be parsed',
      sourceTitle: sourceTitle,
    );
  }

  return _candidate(
    type: 'Z2',
    prescription: 'Z2',
    modality: modality,
    sourceTitle: sourceTitle,
    values: {
      'warmup_seconds': warmup == null ? 0 : parseFitrTime(warmup.group(1)!),
      'work_seconds': parseFitrTime(work.group(1)!),
      'cooldown_seconds': cooldown == null
          ? 0
          : parseFitrTime(cooldown.group(1)!),
    },
  );
}

FitrClassification? classifyFitrSection(Map<String, dynamic> section) {
  return _classifyGear(section) ??
      _classifyPower(section) ??
      _classifyZone2(section);
}

class FitrWorkoutCandidate {
  final String id;
  final String date;
  final String planTitle;
  final String sourceTitle;
  final FitrClassification classification;

  const FitrWorkoutCandidate({
    required this.id,
    required this.date,
    required this.planTitle,
    required this.sourceTitle,
    required this.classification,
  });

  String get type => classification['type']! as String;

  String get prescription {
    return classification['prescription']?.toString() ?? '';
  }

  String get modality {
    return classification['modality']?.toString() ?? '';
  }

  String get displayName {
    if (type == 'MATT') {
      return prescription;
    }

    return '$prescription $modality'.trim();
  }
}

class FitrSkippedWorkout {
  final String id;
  final String date;
  final String planTitle;
  final String sourceTitle;
  final String reason;

  const FitrSkippedWorkout({
    required this.id,
    required this.date,
    required this.planTitle,
    required this.sourceTitle,
    required this.reason,
  });
}

class FitrClassifiedWeek {
  final FitrWeekSnapshot snapshot;
  final List<FitrWorkoutCandidate> candidates;
  final List<FitrSkippedWorkout> skipped;

  const FitrClassifiedWeek({
    required this.snapshot,
    required this.candidates,
    required this.skipped,
  });
}

FitrClassifiedWeek classifyFitrWeekSnapshot(FitrWeekSnapshot snapshot) {
  final candidates = <FitrWorkoutCandidate>[];
  final skipped = <FitrSkippedWorkout>[];
  final mattDatesSeen = <String>{};

  for (final day in snapshot.days) {
    final rawDay = day.detail['day'];
    if (rawDay is! Map) {
      continue;
    }

    final rawSections = rawDay['sections'];
    if (rawSections is! List) {
      continue;
    }

    for (
      var sectionIndex = 0;
      sectionIndex < rawSections.length;
      sectionIndex++
    ) {
      final rawSection = rawSections[sectionIndex];
      if (rawSection is! Map) {
        continue;
      }

      final section = Map<String, dynamic>.from(rawSection);
      final sourceTitle = fitrSectionTitle(section);
      final text = fitrSectionText(section);

      FitrClassification? classification;

      final isMattRow = RegExp(
        r'm\.\s*a\.\s*t\.\s*t\.\s*row\s*test',
        caseSensitive: false,
      ).hasMatch(text);

      if (isMattRow) {
        if (!mattDatesSeen.add(day.date)) {
          continue;
        }

        classification = _candidate(
          type: 'MATT',
          prescription: 'M.A.T.T. Row Test',
          modality: 'row',
          sourceTitle: sourceTitle,
        );
      } else if (sourceTitle.toLowerCase() == 'instructions') {
        continue;
      } else {
        classification = classifyFitrSection(section);
      }

      if (classification == null) {
        continue;
      }

      final type = classification['type']?.toString() ?? 'unknown';
      final recordId = '${day.scheduleId}:$sectionIndex:$type';

      if (classification['status'] != 'CANDIDATE') {
        skipped.add(
          FitrSkippedWorkout(
            id: recordId,
            date: day.date,
            planTitle: day.planTitle,
            sourceTitle:
                classification['source_title']?.toString() ?? sourceTitle,
            reason:
                classification['reason']?.toString() ??
                'Recognized but not importable',
          ),
        );
        continue;
      }

      candidates.add(
        FitrWorkoutCandidate(
          id: recordId,
          date: day.date,
          planTitle: day.planTitle,
          sourceTitle:
              classification['source_title']?.toString() ?? sourceTitle,
          classification: Map.unmodifiable({
            ...classification,
            'workout_date': day.date,
          }),
        ),
      );
    }
  }

  return FitrClassifiedWeek(
    snapshot: snapshot,
    candidates: List.unmodifiable(candidates),
    skipped: List.unmodifiable(skipped),
  );
}
