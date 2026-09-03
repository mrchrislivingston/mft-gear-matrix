class MisfitStructuredIntervalParser {
  const MisfitStructuredIntervalParser();

  static final RegExp _standardRoundPattern = RegExp(
    r'Rd\s*\d+\s*[-:]\s*'
    r'(\d+)\s*/\s*(\d+)\s*/\s*(\d+)',
    caseSensitive: false,
  );

  static final RegExp _maxRoundPattern = RegExp(
    r'Rd\s*\d+\s+'
    r'(\d+)\s*/\s*(\d+)\s*/\s*(\d+)',
    caseSensitive: false,
  );

  static final RegExp _bikeErgPattern = RegExp(
    r'(?<![\d:.])'
    r'(\d{3,4})\s*/\s*'
    r'(\d+:\d{2}(?:\.\d+)?|\d{3}(?:\.\d+)?)'
    r'\s*/\s*'
    r'(\d{2,3})'
    r'(?![\d:.])',
  );

  static final RegExp _calorieSequencePattern = RegExp(
    r'\b(\d+(?:\s*/\s*\d+){2,})\b',
  );

  static final RegExp _twoValuePattern = RegExp(r'(\d+)\s*/\s*(\d+)');

  static final RegExp _labeledCaloriesRpmPattern = RegExp(
    r'Rd\s*\d+\s*[-:]\s*'
    r'Cals?\s*(\d+)\s*,?\s*'
    r'(?:Avg\s*)?RPMs?\s*(\d+)',
    caseSensitive: false,
  );

  static final RegExp _caloriesRpmWattsHeaderPattern = RegExp(
    r'\bCals?\s*/\s*RPMs?\s*/\s*Watts?\b',
    caseSensitive: false,
  );

  static final RegExp _caloriesRpmWattsRoundPattern = RegExp(
    r'^\s*(?:Rd\s*)?\d+\s*[-:]\s*'
    r'(\d+)\s*/\s*(\d+)\s*/\s*(\d+)\s*$',
    caseSensitive: false,
    multiLine: true,
  );

  List<Map<String, String>> extract(String resultText) {
    final structuredText = _maxSectionOnly(resultText);

    var intervals = _extractCaloriesRpmWatts(resultText);
    if (intervals.isNotEmpty) {
      return intervals;
    }

    intervals = _extractThreeMetricMatches(
      _standardRoundPattern,
      structuredText,
    );
    if (intervals.isNotEmpty) {
      return intervals;
    }

    intervals = _extractThreeMetricMatches(_maxRoundPattern, structuredText);
    if (intervals.isNotEmpty) {
      return intervals;
    }

    intervals = _extractBikeErgMatches(resultText);
    if (intervals.isNotEmpty) {
      return intervals;
    }

    intervals = _extractCaloriesPerHour(resultText);
    if (intervals.isNotEmpty) {
      return intervals;
    }

    intervals = _extractCaloriesRpm(resultText);
    if (intervals.isNotEmpty) {
      return intervals;
    }

    return _extractCalorieSequence(resultText);
  }

  List<Map<String, String>> _extractThreeMetricMatches(
    RegExp pattern,
    String resultText,
  ) {
    return pattern
        .allMatches(resultText)
        .map((match) {
          return {
            'watts': match.group(1)!,
            'rpm': match.group(2)!,
            'calories': match.group(3)!,
          };
        })
        .toList(growable: false);
  }

  List<Map<String, String>> _extractCaloriesRpmWatts(String resultText) {
    if (!_caloriesRpmWattsHeaderPattern.hasMatch(resultText)) {
      return const [];
    }

    return _caloriesRpmWattsRoundPattern
        .allMatches(resultText)
        .map((match) {
          return {
            'calories': match.group(1)!,
            'rpm': match.group(2)!,
            'watts': match.group(3)!,
          };
        })
        .toList(growable: false);
  }

  String _maxSectionOnly(String resultText) {
    final maxMatch = RegExp(
      r'\bMax\b',
      caseSensitive: false,
    ).firstMatch(resultText);

    if (maxMatch == null) {
      return resultText;
    }

    final textAfterMax = resultText.substring(maxMatch.end);
    final averageMatch = RegExp(
      r'\b(?:Avg|Average)\b',
      caseSensitive: false,
    ).firstMatch(textAfterMax);

    if (averageMatch == null) {
      return resultText;
    }

    return resultText.substring(0, maxMatch.end + averageMatch.start);
  }

  String _normalizeBikeErgPace(String pace) {
    if (pace.contains(':')) {
      return pace;
    }

    final match = RegExp(r'^(\d)(\d{2}(?:\.\d+)?)$').firstMatch(pace);

    if (match == null) {
      return pace;
    }

    return '${match.group(1)}:${match.group(2)}';
  }

  List<Map<String, String>> _extractBikeErgMatches(String resultText) {
    final averageMatch = RegExp(
      r'\bAverage\b',
      caseSensitive: false,
    ).firstMatch(resultText);

    final intervalText = averageMatch == null
        ? resultText
        : resultText.substring(0, averageMatch.start);

    return _bikeErgPattern
        .allMatches(intervalText)
        .map((match) {
          return {
            'watts': match.group(1)!,
            'primaryMetric': _normalizeBikeErgPace(match.group(2)!),
            'rpm': match.group(3)!,
          };
        })
        .toList(growable: false);
  }

  List<Map<String, String>> _extractCaloriesPerHour(String resultText) {
    if (!RegExp(r'cals/hr/cals', caseSensitive: false).hasMatch(resultText)) {
      return const [];
    }

    return _twoValuePattern
        .allMatches(resultText)
        .map((match) {
          return {
            'caloriesPerHour': match.group(1)!,
            'calories': match.group(2)!,
          };
        })
        .toList(growable: false);
  }

  List<Map<String, String>> _extractLabeledCaloriesRpm(String resultText) {
    return _labeledCaloriesRpmPattern
        .allMatches(resultText)
        .map((match) {
          return {'calories': match.group(1)!, 'rpm': match.group(2)!};
        })
        .toList(growable: false);
  }

  List<Map<String, String>> _extractCaloriesRpm(String resultText) {
    final labeled = _extractLabeledCaloriesRpm(resultText);

    if (labeled.isNotEmpty) {
      return labeled;
    }

    if (!RegExp(r'cals/rpms', caseSensitive: false).hasMatch(resultText)) {
      return const [];
    }

    return _twoValuePattern
        .allMatches(resultText)
        .map((match) {
          return {'calories': match.group(1)!, 'rpm': match.group(2)!};
        })
        .toList(growable: false);
  }

  List<Map<String, String>> _extractCalorieSequence(String resultText) {
    final match = _calorieSequencePattern.firstMatch(resultText);

    if (match == null) {
      return const [];
    }

    return match
        .group(1)!
        .split('/')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)
        .map((value) => {'calories': value})
        .toList(growable: false);
  }
}
