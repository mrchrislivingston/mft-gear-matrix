class MisfitIntervalParser {
  const MisfitIntervalParser();

  static final RegExp _perRoundPattern = RegExp(
    r'Per\s+Rd\s*-\s*([0-9:./]+)',
    caseSensitive: false,
  );

  static final RegExp _paceSequencePattern = RegExp(
    r'(\d+:\d+(?:\.\d+)?(?:/\d+:\d+(?:\.\d+)?){3,})',
  );

  List<String> extractIntervalPaces(String resultText) {
    final perRoundMatch = _perRoundPattern.firstMatch(resultText);

    if (perRoundMatch != null) {
      return _splitPaces(perRoundMatch.group(1)!);
    }

    final matches = _paceSequencePattern
        .allMatches(resultText)
        .map((match) => match.group(1)!)
        .toList();

    if (matches.isEmpty) {
      return const [];
    }

    matches.sort((left, right) => right.length.compareTo(left.length));
    return _splitPaces(matches.first);
  }

  List<String> _splitPaces(String paceText) {
    return paceText
        .split('/')
        .map((pace) => pace.trim())
        .where((pace) => pace.isNotEmpty)
        .toList(growable: false);
  }
}
