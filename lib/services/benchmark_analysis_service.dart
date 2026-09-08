import '../models/benchmark_attempt.dart';
import '../models/benchmark_score_type.dart';

enum BenchmarkTrend { improved, declined, tied, unavailable }

class BenchmarkAnalysis {
  final BenchmarkAttempt? latest;
  final BenchmarkAttempt? previous;
  final BenchmarkAttempt? best;
  final BenchmarkTrend trend;
  final String trendLabel;

  const BenchmarkAnalysis({
    required this.latest,
    required this.previous,
    required this.best,
    required this.trend,
    required this.trendLabel,
  });

  bool get hasAttempts => latest != null;
}

class BenchmarkAnalysisService {
  const BenchmarkAnalysisService();

  BenchmarkAnalysis analyze({
    required BenchmarkScoreType scoreType,
    required List<BenchmarkAttempt> attempts,
  }) {
    if (attempts.isEmpty) {
      return const BenchmarkAnalysis(
        latest: null,
        previous: null,
        best: null,
        trend: BenchmarkTrend.unavailable,
        trendLabel: 'No attempts recorded',
      );
    }

    final ordered = List<BenchmarkAttempt>.of(attempts)
      ..sort((left, right) => right.date.compareTo(left.date));

    final latest = ordered.first;
    final previous = ordered.length > 1 ? ordered[1] : null;

    if (scoreType == BenchmarkScoreType.unconfigured) {
      return BenchmarkAnalysis(
        latest: latest,
        previous: previous,
        best: null,
        trend: BenchmarkTrend.unavailable,
        trendLabel: 'Scoring analysis pending',
      );
    }

    BenchmarkAttempt? best;
    _ParsedScore? bestScore;

    for (final attempt in ordered) {
      final parsed = _parse(scoreType, attempt.score);
      if (parsed == null) {
        continue;
      }

      if (best == null ||
          _performanceComparison(scoreType, parsed, bestScore!) > 0) {
        best = attempt;
        bestScore = parsed;
      }
    }

    if (previous == null) {
      return BenchmarkAnalysis(
        latest: latest,
        previous: null,
        best: best,
        trend: BenchmarkTrend.unavailable,
        trendLabel: 'First recorded attempt',
      );
    }

    final latestScore = _parse(scoreType, latest.score);
    final previousScore = _parse(scoreType, previous.score);

    if (latestScore == null || previousScore == null) {
      return BenchmarkAnalysis(
        latest: latest,
        previous: previous,
        best: best,
        trend: BenchmarkTrend.unavailable,
        trendLabel: 'Score format cannot be compared',
      );
    }

    final comparison = _performanceComparison(
      scoreType,
      latestScore,
      previousScore,
    );

    if (comparison == 0) {
      return BenchmarkAnalysis(
        latest: latest,
        previous: previous,
        best: best,
        trend: BenchmarkTrend.tied,
        trendLabel: 'Matched previous result',
      );
    }

    final improved = comparison > 0;

    return BenchmarkAnalysis(
      latest: latest,
      previous: previous,
      best: best,
      trend: improved ? BenchmarkTrend.improved : BenchmarkTrend.declined,
      trendLabel: _trendLabel(
        scoreType: scoreType,
        latest: latestScore,
        previous: previousScore,
        improved: improved,
      ),
    );
  }

  int _performanceComparison(
    BenchmarkScoreType scoreType,
    _ParsedScore left,
    _ParsedScore right,
  ) {
    final rawComparison = left.compareTo(right);

    if (_lowerIsBetter(scoreType)) {
      return -rawComparison;
    }

    return rawComparison;
  }

  bool _lowerIsBetter(BenchmarkScoreType scoreType) {
    return scoreType == BenchmarkScoreType.forTime ||
        scoreType == BenchmarkScoreType.slowestIntervalTime;
  }

  _ParsedScore? _parse(BenchmarkScoreType scoreType, String rawScore) {
    return switch (scoreType) {
      BenchmarkScoreType.forTime ||
      BenchmarkScoreType.slowestIntervalTime => _parseTime(rawScore),
      BenchmarkScoreType.roundsReps => _parseRoundsReps(rawScore),
      BenchmarkScoreType.unconfigured => null,
      _ => _parseNumber(rawScore),
    };
  }

  _ParsedScore? _parseTime(String rawScore) {
    final match = RegExp(
      r'^\s*(?:(\d+):)?(\d{1,2}):(\d{2})\s*$',
    ).firstMatch(rawScore);

    if (match != null) {
      final hours = int.tryParse(match.group(1) ?? '0');
      final minutes = int.tryParse(match.group(2)!);
      final seconds = int.tryParse(match.group(3)!);

      if (hours == null ||
          minutes == null ||
          seconds == null ||
          seconds >= 60) {
        return null;
      }

      return _ParsedScore(
        primary: (hours * 3600 + minutes * 60 + seconds).toDouble(),
      );
    }

    final shortMatch = RegExp(
      r'^\s*(\d{1,2}):(\d{2})\s*$',
    ).firstMatch(rawScore);

    if (shortMatch == null) {
      return null;
    }

    final minutes = int.tryParse(shortMatch.group(1)!);
    final seconds = int.tryParse(shortMatch.group(2)!);

    if (minutes == null || seconds == null || seconds >= 60) {
      return null;
    }

    return _ParsedScore(primary: (minutes * 60 + seconds).toDouble());
  }

  _ParsedScore? _parseRoundsReps(String rawScore) {
    final match = RegExp(r'^\s*(\d+)\s*\+\s*(\d+)\s*$').firstMatch(rawScore);

    if (match == null) {
      return null;
    }

    return _ParsedScore(
      primary: double.parse(match.group(1)!),
      secondary: double.parse(match.group(2)!),
    );
  }

  _ParsedScore? _parseNumber(String rawScore) {
    final cleaned = rawScore.replaceAll(',', '').trim();
    final match = RegExp(r'^-?\d+(?:\.\d+)?').firstMatch(cleaned);

    if (match == null) {
      return null;
    }

    final value = double.tryParse(match.group(0)!);

    if (value == null) {
      return null;
    }

    return _ParsedScore(primary: value);
  }

  String _trendLabel({
    required BenchmarkScoreType scoreType,
    required _ParsedScore latest,
    required _ParsedScore previous,
    required bool improved,
  }) {
    if (scoreType == BenchmarkScoreType.forTime ||
        scoreType == BenchmarkScoreType.slowestIntervalTime) {
      final difference = (latest.primary - previous.primary).abs().round();
      final direction = improved ? 'Faster' : 'Slower';
      return '$direction by ${_formatDuration(difference)}';
    }

    if (scoreType == BenchmarkScoreType.roundsReps) {
      if (latest.primary == previous.primary) {
        final difference = (latest.secondary - previous.secondary)
            .abs()
            .round();
        final direction = improved ? 'More' : 'Fewer';
        return '$direction by $difference reps';
      }

      final difference = (latest.primary - previous.primary).abs().round();
      final direction = improved ? 'More' : 'Fewer';
      final label = difference == 1 ? 'round' : 'rounds';
      return '$direction by $difference $label';
    }

    final difference = (latest.primary - previous.primary).abs();
    final formattedDifference = _formatNumber(difference);
    final direction = improved ? 'Higher' : 'Lower';
    final unit = _unitFor(scoreType);

    return unit.isEmpty
        ? '$direction by $formattedDifference'
        : '$direction by $formattedDifference $unit';
  }

  String _unitFor(BenchmarkScoreType scoreType) {
    return switch (scoreType) {
      BenchmarkScoreType.maxWeight || BenchmarkScoreType.totalLoad => 'lb',
      BenchmarkScoreType.averageWatts ||
      BenchmarkScoreType.lowestIntervalWatts => 'W',
      BenchmarkScoreType.totalCalories ||
      BenchmarkScoreType.lowestIntervalCalories => 'calories',
      BenchmarkScoreType.totalReps => 'reps',
      BenchmarkScoreType.totalDistance ||
      BenchmarkScoreType.lowestIntervalDistance => 'distance units',
      _ => '',
    };
  }

  String _formatDuration(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;
    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String _formatNumber(double value) {
    if (value == value.roundToDouble()) {
      return value.round().toString();
    }

    return value.toStringAsFixed(1);
  }
}

class _ParsedScore implements Comparable<_ParsedScore> {
  final double primary;
  final double secondary;

  const _ParsedScore({required this.primary, this.secondary = 0});

  @override
  int compareTo(_ParsedScore other) {
    final primaryComparison = primary.compareTo(other.primary);

    if (primaryComparison != 0) {
      return primaryComparison;
    }

    return secondary.compareTo(other.secondary);
  }
}
