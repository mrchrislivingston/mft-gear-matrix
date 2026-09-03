class MisfitExecutionPlan {
  final int intervalCount;
  final String workDuration;

  const MisfitExecutionPlan({
    required this.intervalCount,
    required this.workDuration,
  });
}

class MisfitExecutionPlanParser {
  const MisfitExecutionPlanParser();

  static final RegExp _countFirstPattern = RegExp(
    r'\b(\d+)\s*[x×]\s*(\d{1,2}:\d{2})\b',
    caseSensitive: false,
  );

  static final RegExp _durationFirstPattern = RegExp(
    r'\b(\d{1,2}:\d{2})\s*[x×]\s*(\d+)\b',
    caseSensitive: false,
  );

  static final RegExp _roundsCaloriesPattern = RegExp(
    r'\b(\d+)\s+Rounds?\b.*?'
    r'(\d+)\s*(?:/|\s|-)?\s*(?:\d+\s*)?Calories?\b',
    caseSensitive: false,
    dotAll: true,
  );

  static final RegExp _powerRoundsPattern = RegExp(
    r'\bEvery\s+\d{1,2}:\d{2}\s+for\s+(\d+)\s+Rounds?\b',
    caseSensitive: false,
  );

  static final RegExp _powerWorkDurationPattern = RegExp(
    r'\bin\s+(:\d{2})\b',
    caseSensitive: false,
  );

  MisfitExecutionPlan? extract(String? programmingText) {
    if (programmingText == null || programmingText.isEmpty) {
      return null;
    }

    final countFirstMatch = _countFirstPattern.firstMatch(programmingText);

    if (countFirstMatch != null) {
      return MisfitExecutionPlan(
        intervalCount: int.parse(countFirstMatch.group(1)!),
        workDuration: countFirstMatch.group(2)!,
      );
    }

    final durationFirstMatch = _durationFirstPattern.firstMatch(
      programmingText,
    );

    if (durationFirstMatch != null) {
      return MisfitExecutionPlan(
        intervalCount: int.parse(durationFirstMatch.group(2)!),
        workDuration: durationFirstMatch.group(1)!,
      );
    }

    final calorieMatch = _roundsCaloriesPattern.firstMatch(programmingText);

    if (calorieMatch != null) {
      return MisfitExecutionPlan(
        intervalCount: int.parse(calorieMatch.group(1)!),
        workDuration: '${calorieMatch.group(2)!} calories',
      );
    }

    final powerRoundsMatch = _powerRoundsPattern.firstMatch(programmingText);
    final powerDurationMatch = _powerWorkDurationPattern.firstMatch(
      programmingText,
    );

    if (powerRoundsMatch != null && powerDurationMatch != null) {
      return MisfitExecutionPlan(
        intervalCount: int.parse(powerRoundsMatch.group(1)!),
        workDuration: powerDurationMatch.group(1)!,
      );
    }

    return null;
  }
}
