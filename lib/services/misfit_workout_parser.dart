enum MisfitWorkoutType { gear, power, zone, unknown }

enum MisfitImportStatus { ready, review, tbdLater, skip }

enum MisfitResultDetail {
  none,
  workoutAverage,
  intervalResults,
  mixed,
  resultTextOnly,
}

class MisfitClassification {
  final MisfitImportStatus status;
  final String reason;

  const MisfitClassification({required this.status, required this.reason});
}

class MisfitWorkoutParser {
  const MisfitWorkoutParser();

  static final RegExp _gearWordPattern = RegExp(
    r'\b([1-8])(?:st|nd|rd|th)?\s+gear\b',
    caseSensitive: false,
  );

  static final RegExp _gearShortPattern = RegExp(
    r'\bG([1-8])\b',
    caseSensitive: false,
  );

  static final RegExp _powerPattern = RegExp(
    r'\bP([1-4])\b',
    caseSensitive: false,
  );

  static final RegExp _prescribedPowerPattern = RegExp(
    r'@\s*P([1-4])\b',
    caseSensitive: false,
  );

  static final RegExp _zonePattern = RegExp(
    r'\b(?:zone|z)\s*([12])\b',
    caseSensitive: false,
  );

  static final RegExp _skipResultPattern = RegExp(
    r"\b(skip(?:ped|ping)?|didn['’]?t do|did not do|"
    r"not completed|missed|rest day|sick|illness|"
    r"work emergency|woke up with a cold|"
    r"going to take the weekend|not today satan|"
    r"instead of (?:zone|z)\s*[12]|called it a day|"
    r"will do (?:a )?(?:zone|z)\s*[12].*later)\b",
    caseSensitive: false,
    dotAll: true,
  );

  static final RegExp _partialResultPattern = RegExp(
    r'\b(quit|stopped|cut (?:this|it) off early|'
    r'only completed|only did|did\s+\d+\s*(?:of|/)\s*\d+|'
    r'\d+\s*/\s*\d+\s+rounds?)\b',
    caseSensitive: false,
  );

  static final RegExp _workoutStartPattern = RegExp(
    r'^\s*(aerobic|power|zone\s*[12]|build)\b',
    caseSensitive: false,
  );

  static final List<RegExp> _primaryTextStopPatterns = [
    RegExp(r'^\s*equipment modifications?\s*$', caseSensitive: false),
    RegExp(r'^\s*recover\b', caseSensitive: false),
    RegExp(r'^\s*your zone 2 today\b', caseSensitive: false),
    RegExp(r'^\s*reminder:', caseSensitive: false),
    RegExp(r'^\s*there will be a zone 2\b', caseSensitive: false),
  ];

  static final Map<String, RegExp> _modalityPatterns = {
    'run': RegExp(r'\b(?:run|running|treadmill)\b', caseSensitive: false),
    'row': RegExp(r'\b(?:row|rowing|rower)\b', caseSensitive: false),
    'ski': RegExp(r'\b(?:ski|skierg|ski erg)\b', caseSensitive: false),
    'bikeErg': RegExp(
      r'\b(?:c2 bike|bikeerg|bike erg|bike)\b',
      caseSensitive: false,
    ),
    'echo': RegExp(
      r'\b(?:echo bike|air bike|assault bike)\b',
      caseSensitive: false,
    ),
  };

  String normalizeText(String value) {
    return value.replaceAll('\r\n', '\n').replaceAll('\r', '\n').trim();
  }

  List<int> detectGears(String programmingText) {
    final gears = <int>{};

    for (final match in _gearWordPattern.allMatches(programmingText)) {
      gears.add(int.parse(match.group(1)!));
    }

    for (final match in _gearShortPattern.allMatches(programmingText)) {
      gears.add(int.parse(match.group(1)!));
    }

    final result = gears.toList()..sort();
    return result;
  }

  List<int> detectPowerPrescriptions(String programmingText) {
    final prescribed = _integerMatches(
      _prescribedPowerPattern,
      programmingText,
    );

    if (prescribed.isNotEmpty) {
      return prescribed;
    }

    return _integerMatches(_powerPattern, programmingText);
  }

  List<int> detectZonePrescriptions(String programmingText) {
    return _integerMatches(
      _zonePattern,
      _workoutProgrammingText(programmingText),
    );
  }

  List<String> detectModalities(String programmingText) {
    final prescriptionModalities = _prescriptionLineModalities(programmingText);

    if (prescriptionModalities.isNotEmpty) {
      return prescriptionModalities;
    }

    final headingModalities = _modalitiesInText(
      _workoutHeadingText(programmingText),
    );

    if (headingModalities.length == 1) {
      return headingModalities;
    }

    return _modalitiesInText(_workoutProgrammingText(programmingText));
  }

  List<String> detectCandidateModalities({
    required String programmingText,
    required String resultText,
  }) {
    final programmingModalities = detectModalities(programmingText);

    if (programmingModalities.isNotEmpty) {
      return programmingModalities;
    }

    return _modalitiesInText(normalizeText(resultText));
  }

  MisfitWorkoutType detectWorkoutType(String programmingText) {
    if (detectGears(programmingText).isNotEmpty) {
      return MisfitWorkoutType.gear;
    }

    if (detectPowerPrescriptions(programmingText).isNotEmpty) {
      return MisfitWorkoutType.power;
    }

    if (detectZonePrescriptions(programmingText).isNotEmpty) {
      return MisfitWorkoutType.zone;
    }

    return MisfitWorkoutType.unknown;
  }

  MisfitResultDetail detectResultDetail(String resultText) {
    final normalized = normalizeText(resultText);

    if (normalized.isEmpty) {
      return MisfitResultDetail.none;
    }

    final hasAverage = RegExp(
      r'\b(?:avg|average|overall)\b',
      caseSensitive: false,
    ).hasMatch(normalized);

    final hasIntervals =
        RegExp(
          r'\b(?:round|rd|interval|set)\s*#?\s*\d+\b',
          caseSensitive: false,
        ).hasMatch(normalized) ||
        RegExp(
          r'(?:\d+(?::\d+)?(?:\.\d+)?\s*/){2,}'
          r'\d+(?::\d+)?(?:\.\d+)?',
          caseSensitive: false,
        ).hasMatch(normalized);

    if (hasAverage && hasIntervals) {
      return MisfitResultDetail.mixed;
    }

    if (hasIntervals) {
      return MisfitResultDetail.intervalResults;
    }

    if (hasAverage) {
      return MisfitResultDetail.workoutAverage;
    }

    return MisfitResultDetail.resultTextOnly;
  }

  bool isRelevantWorkout(String programmingText) {
    return detectWorkoutType(programmingText) != MisfitWorkoutType.unknown;
  }

  MisfitClassification classifyCandidate({
    required String programmingText,
    required String resultText,
  }) {
    final normalizedResult = normalizeText(resultText);

    if (normalizedResult.isEmpty) {
      return const MisfitClassification(
        status: MisfitImportStatus.skip,
        reason: 'No result recorded',
      );
    }

    if (_skipResultPattern.hasMatch(normalizedResult)) {
      return const MisfitClassification(
        status: MisfitImportStatus.skip,
        reason: 'Result indicates workout was not completed',
      );
    }

    final gears = detectGears(programmingText);
    final powerPrescriptions = detectPowerPrescriptions(programmingText);
    final zonePrescriptions = detectZonePrescriptions(programmingText);
    final modalities = detectCandidateModalities(
      programmingText: programmingText,
      resultText: resultText,
    );

    if (gears.length > 1) {
      return const MisfitClassification(
        status: MisfitImportStatus.tbdLater,
        reason: 'Mixed-gear workout',
      );
    }

    if (modalities.length > 1) {
      return const MisfitClassification(
        status: MisfitImportStatus.tbdLater,
        reason: 'Mixed-modality workout',
      );
    }

    if (powerPrescriptions.length > 1) {
      return const MisfitClassification(
        status: MisfitImportStatus.tbdLater,
        reason: 'Multiple power prescriptions',
      );
    }

    if (zonePrescriptions.length > 1) {
      return const MisfitClassification(
        status: MisfitImportStatus.tbdLater,
        reason: 'Multiple zone prescriptions',
      );
    }

    if (modalities.isEmpty) {
      return const MisfitClassification(
        status: MisfitImportStatus.review,
        reason: 'Modality could not be detected',
      );
    }

    if (_partialResultPattern.hasMatch(normalizedResult)) {
      return const MisfitClassification(
        status: MisfitImportStatus.review,
        reason: 'Result may describe a partial workout',
      );
    }

    return const MisfitClassification(
      status: MisfitImportStatus.ready,
      reason: 'Single supported workout',
    );
  }

  List<int> _integerMatches(RegExp pattern, String text) {
    final values = <int>{
      for (final match in pattern.allMatches(text)) int.parse(match.group(1)!),
    };

    final result = values.toList()..sort();
    return result;
  }

  List<String> _modalitiesInText(String text) {
    final modalities = <String>[
      for (final entry in _modalityPatterns.entries)
        if (entry.value.hasMatch(text)) entry.key,
    ];

    if (modalities.contains('echo') && modalities.contains('bikeErg')) {
      modalities.remove('bikeErg');
    }

    return modalities;
  }

  String _workoutHeadingText(String programmingText) {
    final lines = normalizeText(programmingText).split('\n');
    var heading = '';

    for (final line in lines) {
      if (_workoutStartPattern.hasMatch(line)) {
        heading = line.trim();
      }
    }

    return heading;
  }

  String _workoutProgrammingText(String programmingText) {
    final lines = normalizeText(programmingText).split('\n');
    var startIndex = 0;

    for (var index = 0; index < lines.length; index++) {
      if (_workoutStartPattern.hasMatch(lines[index])) {
        startIndex = index;
      }
    }

    final workoutLines = <String>[];

    for (final line in lines.skip(startIndex)) {
      final normalizedLine = line.trim();
      final shouldStop = _primaryTextStopPatterns.any(
        (pattern) => pattern.hasMatch(normalizedLine),
      );

      if (shouldStop) {
        break;
      }

      workoutLines.add(line);
    }

    return workoutLines.join('\n').trim();
  }

  List<String> _prescriptionLineModalities(String programmingText) {
    final prescriptionPattern = RegExp(
      r'\b(?:gear|zone\s*[12]|@\s*P[1-3])\b',
      caseSensitive: false,
    );

    final lines = _workoutProgrammingText(programmingText).split('\n');

    for (final line in lines) {
      if (!prescriptionPattern.hasMatch(line)) {
        continue;
      }

      final modalities = _modalitiesInText(line);

      if (modalities.length == 1) {
        return modalities;
      }
    }

    return const [];
  }
}
