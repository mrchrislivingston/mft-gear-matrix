class MisfitIntervalTimeParser {
  const MisfitIntervalTimeParser();

  static final RegExp _intervalTimePattern = RegExp(
    r'\b(\d+:\d+(?:\.\d+)?)\s*/',
  );

  List<String> extract(String resultText) {
    return _intervalTimePattern
        .allMatches(resultText)
        .map((match) => match.group(1)!)
        .toList(growable: false);
  }
}
