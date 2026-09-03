class MisfitMetricParser {
  const MisfitMetricParser();

  static final RegExp _durationPattern = RegExp(
    r'\b(\d{1,3})\s*(?:min|minutes?)\b',
    caseSensitive: false,
  );

  static final RegExp _contextClockDurationPattern = RegExp(
    r'\b(\d{1,2}):(\d{2})\b'
    r'(?=\s*(?:in\s+(?:z|zone)\s*[12]\b|today\b|total\b))',
    caseSensitive: false,
  );

  static final RegExp _lineStartClockDurationPattern = RegExp(
    r'^\s*(\d{1,2}):(\d{2})\b',
    multiLine: true,
  );

  static final RegExp _modalityClockDurationPattern = RegExp(
    r'\b(?:bike|bikeerg|bike erg|run|row|rower|ski|skierg|ski erg)\s+'
    r'(\d{1,2}):(\d{2})\b',
    caseSensitive: false,
  );

  static final RegExp _averageWattsPattern = RegExp(
    r'\b(?:avg|average)\s+'
    r'(?:watt|watts|power)\s*[-:]?\s*(\d+(?:\.\d+)?)\b',
    caseSensitive: false,
  );

  static final RegExp _averageHeartRatePattern = RegExp(
    r'\b(?:avg|average)\s+'
    r'(?:hr|heart\s*rate)\s*[-:]?\s*(\d+(?:\.\d+)?)\b',
    caseSensitive: false,
  );

  static final RegExp _heartRateAverageSuffixPattern = RegExp(
    r'\b(\d+)\s+avg\s+hr\b',
    caseSensitive: false,
  );

  static final List<RegExp> _averagePacePatterns = [
    RegExp(
      r'\b(?:avg|average)\s+pace\s*[-:]?\s*'
      r'(\d+:\d+(?:\.\d+)?)',
      caseSensitive: false,
    ),
    RegExp(r'\bpace\s*[-:]?\s*(\d+:\d+(?:\.\d+)?)', caseSensitive: false),
    RegExp(r'\b(\d+:\d+)\s*/\s*mile\s+average\b', caseSensitive: false),
    RegExp(r'\b(\d+:\d+(?:\.\d+)?)\s+avg\b', caseSensitive: false),
  ];

  static final RegExp _labeledDistancePattern = RegExp(
    r'\bdistance\s*[-:]\s*(\.?\d+(?:\.\d+)?)\b',
    caseSensitive: false,
  );

  static final RegExp _distanceMilesPattern = RegExp(
    r'(?<!\d)(\.?\d+(?:\.\d+)?)\s*miles?\b',
    caseSensitive: false,
  );

  static final RegExp _distanceKilometersPattern = RegExp(
    r'(?<!\d)(\.?\d+(?:\.\d+)?)\s*KM\b',
    caseSensitive: false,
  );

  static final RegExp _actualRunPattern = RegExp(
    r'Actual\s*-\s*'
    r'(\d+:\d+)'
    r'\s*pace\s*/\s*'
    r'([0-9.]+)'
    r'\s*miles?',
    caseSensitive: false,
  );

  String extractDuration(String resultText) {
    final durationMatch = _durationPattern.firstMatch(resultText);

    if (durationMatch != null) {
      return _formatClockDuration(int.parse(durationMatch.group(1)!), 0);
    }

    final contextMatch = _contextClockDurationPattern.firstMatch(resultText);

    if (contextMatch != null) {
      return _formatClockDuration(
        int.parse(contextMatch.group(1)!),
        int.parse(contextMatch.group(2)!),
      );
    }

    final modalityMatch = _modalityClockDurationPattern.firstMatch(resultText);

    if (modalityMatch != null) {
      return _formatClockDuration(
        int.parse(modalityMatch.group(1)!),
        int.parse(modalityMatch.group(2)!),
      );
    }

    final lineStartMatch = _lineStartClockDurationPattern.firstMatch(
      resultText,
    );

    if (lineStartMatch == null) {
      return '';
    }

    return _formatClockDuration(
      int.parse(lineStartMatch.group(1)!),
      int.parse(lineStartMatch.group(2)!),
    );
  }

  Map<String, String> extractAverageWatts(String resultText) {
    final match = _averageWattsPattern.firstMatch(resultText);

    if (match == null) {
      return const {};
    }

    return {'watts': match.group(1)!};
  }

  Map<String, String> extractAverageHeartRate(String resultText) {
    var match = _averageHeartRatePattern.firstMatch(resultText);
    match ??= _heartRateAverageSuffixPattern.firstMatch(resultText);

    if (match == null) {
      return const {};
    }

    return {'heartRate': match.group(1)!};
  }

  Map<String, String> extractActualRun(String resultText) {
    final match = _actualRunPattern.firstMatch(resultText);

    if (match == null) {
      return const {};
    }

    return {'primaryMetric': match.group(1)!, 'distance': match.group(2)!};
  }

  Map<String, String> extractAveragePace(String resultText) {
    final actualRun = extractActualRun(resultText);

    if (actualRun.isNotEmpty) {
      return actualRun;
    }

    for (final pattern in _averagePacePatterns) {
      final match = pattern.firstMatch(resultText);

      if (match != null) {
        return {'primaryMetric': match.group(1)!};
      }
    }

    return const {};
  }

  Map<String, String> extractDistance(String resultText) {
    var match = _labeledDistancePattern.firstMatch(resultText);

    if (match != null) {
      return {'distance': match.group(1)!};
    }

    match = _distanceMilesPattern.firstMatch(resultText);
    match ??= _distanceKilometersPattern.firstMatch(resultText);

    if (match == null) {
      return const {};
    }

    return {'distance': match.group(1)!};
  }

  Map<String, String> extractAverageMetrics(String resultText) {
    return {
      ...extractAverageWatts(resultText),
      ...extractAverageHeartRate(resultText),
      ...extractAveragePace(resultText),
      ...extractDistance(resultText),
    };
  }

  String _formatClockDuration(int minutes, int seconds) {
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    return '${hours.toString().padLeft(2, '0')}:'
        '${remainingMinutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}
