class MisfitPaceDistanceIntervalParser {
  const MisfitPaceDistanceIntervalParser();

  static final RegExp _paceDistancePattern = RegExp(
    r'(\d{1,2}:?\d{2}(?:\.\d+)?)'
    r'\s*/\s*'
    r'(\.?\d+(?:\.\d+)?)'
    r'(?!:)'
    r'\s*(KM)?',
    caseSensitive: false,
  );

  static final RegExp _distancePaceSlashPattern = RegExp(
    r'(\d+(?:\.\d+)?)\s*m\s*/\s*'
    r'(\d{1,2}:\d{2}(?:\.\d+)?)',
    caseSensitive: false,
  );

  static final RegExp _distancePaceTablePattern = RegExp(
    r'(\d+(?:\.\d+)?)\s*m\s*,\s*'
    r'(\d{1,2}:\d{2}(?:\.\d+)?)'
    r'\s*min\s*/\s*mile',
    caseSensitive: false,
  );

  List<Map<String, String>> extract(String? resultText) {
    if (resultText == null || resultText.isEmpty) {
      return const [];
    }

    final averageMatch = RegExp(
      r'\b(?:Avg|Average)\b',
      caseSensitive: false,
    ).firstMatch(resultText);

    var intervalText = averageMatch == null
        ? resultText
        : resultText.substring(0, averageMatch.start);

    intervalText = intervalText
        .split('\n')
        .where(
          (line) =>
              !RegExp(r'^\s*Total\b', caseSensitive: false).hasMatch(line),
        )
        .join('\n');

    var intervals = _extractDistanceFirst(
      _distancePaceTablePattern,
      intervalText,
    );

    if (intervals.isNotEmpty) {
      return intervals;
    }

    intervals = _extractDistanceFirst(_distancePaceSlashPattern, intervalText);

    if (intervals.isNotEmpty) {
      return intervals;
    }

    return _paceDistancePattern
        .allMatches(intervalText)
        .map((match) {
          return {
            'primaryMetric': _normalizePace(match.group(1)!),
            'distance': _normalizeDistance(match.group(2)!, match.group(3)),
          };
        })
        .toList(growable: false);
  }

  List<Map<String, String>> _extractDistanceFirst(
    RegExp pattern,
    String intervalText,
  ) {
    return pattern
        .allMatches(intervalText)
        .map((match) {
          return {
            'primaryMetric': _normalizePace(match.group(2)!),
            'distance': match.group(1)!,
          };
        })
        .toList(growable: false);
  }

  String _normalizePace(String value) {
    if (value.contains(':')) {
      return value;
    }

    final match = RegExp(r'^(\d)(\d{2}(?:\.\d+)?)$').firstMatch(value);

    if (match == null) {
      return value;
    }

    return '${match.group(1)}:${match.group(2)}';
  }

  String _normalizeDistance(String value, String? unit) {
    if (unit == null || unit.isEmpty) {
      return value;
    }

    return (double.parse(value) * 1000).round().toString();
  }
}
