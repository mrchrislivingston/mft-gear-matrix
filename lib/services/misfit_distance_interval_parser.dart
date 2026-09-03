class MisfitDistanceIntervalParser {
  const MisfitDistanceIntervalParser();

  static final RegExp _numberedDistancePattern = RegExp(
    r'(?:^|[,\n]\s*)'
    r'(\d+)\s*[-:]\s*'
    r'(\d{2,5})'
    r'(?=\s*(?:,|$))',
    multiLine: true,
  );

  static final RegExp _distanceBlockPattern = RegExp(
    r'Distances?\s+in\s+Km.*?\n([0-9./\s]+)',
    caseSensitive: false,
    dotAll: true,
  );

  static final RegExp _distancePattern = RegExp(r'\d+\.\d+');

  List<Map<String, String>> extract(String? resultText) {
    if (resultText == null || resultText.isEmpty) {
      return const [];
    }

    final numberedDistances = _extractNumberedDistances(resultText);

    if (numberedDistances.isNotEmpty) {
      return numberedDistances;
    }

    final blockMatch = _distanceBlockPattern.firstMatch(resultText);

    if (blockMatch == null) {
      return const [];
    }

    return _distancePattern
        .allMatches(blockMatch.group(1)!)
        .map((match) {
          final kilometers = double.parse(match.group(0)!);
          final meters = (kilometers * 1000).round();

          return {'distance': meters.toString()};
        })
        .toList(growable: false);
  }

  List<Map<String, String>> _extractNumberedDistances(String resultText) {
    final matches = _numberedDistancePattern.allMatches(resultText).toList();

    if (matches.length < 2) {
      return const [];
    }

    for (var index = 0; index < matches.length; index++) {
      final intervalNumber = int.parse(matches[index].group(1)!);

      if (intervalNumber != index + 1) {
        return const [];
      }
    }

    return matches
        .map((match) => {'distance': match.group(2)!})
        .toList(growable: false);
  }
}
