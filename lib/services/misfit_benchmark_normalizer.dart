import '../models/benchmark_attempt.dart';
import 'misfit_benchmark_candidate_reader.dart';

class MisfitBenchmarkNormalizationAttempt {
  final MisfitBenchmarkCandidate candidate;
  final BenchmarkAttempt? benchmarkAttempt;
  final String? error;
  final String? excludedReason;

  const MisfitBenchmarkNormalizationAttempt({
    required this.candidate,
    this.benchmarkAttempt,
    this.error,
    this.excludedReason,
  });

  bool get succeeded => benchmarkAttempt != null;
}

class MisfitBenchmarkNormalizationSummary {
  final List<MisfitBenchmarkNormalizationAttempt> attempts;

  const MisfitBenchmarkNormalizationSummary({required this.attempts});

  int get successful => attempts.where((attempt) => attempt.succeeded).length;

  int get failed => attempts.where((attempt) => attempt.error != null).length;

  int get excluded =>
      attempts.where((attempt) => attempt.excludedReason != null).length;

  MisfitBenchmarkNormalizationAttempt? attemptFor(
    MisfitBenchmarkCandidate candidate,
  ) {
    for (final attempt in attempts) {
      if (identical(attempt.candidate, candidate)) {
        return attempt;
      }
    }
    return null;
  }
}

class MisfitBenchmarkNormalizer {
  const MisfitBenchmarkNormalizer();

  static final RegExp _timePattern = RegExp(r'\b(\d{1,2}:\d{2}(?:\.\d+)?)\b');

  static final RegExp _plusScorePattern = RegExp(
    r'\b(\d+)\s*(?:rds?|rounds?)?\s*\+\s*(\d+)\b',
    caseSensitive: false,
  );

  static final RegExp _writtenRoundsRepsPattern = RegExp(
    r'\b(\d+)\s*(?:rds?|rounds?)\s+(\d+)\s*reps?\b',
    caseSensitive: false,
  );

  static final RegExp _averageWattsPattern = RegExp(
    r'\bAvg(?:erage)?\s+Watts?\s*[-:]\s*(\d+)\b',
    caseSensitive: false,
  );

  static final RegExp _totalAverageWattsPattern = RegExp(
    r'\bTotal\s+Avg\s*-\s*[^,\n]+,\s*(\d+)\s*w\b',
    caseSensitive: false,
  );

  static final RegExp _averagesTablePattern = RegExp(
    r'\bAverages?\s*[-:]\s*(\d+)\s*/',
    caseSensitive: false,
  );

  static final RegExp _totalCaloriesPattern = RegExp(
    r'\bTotal\s+(?:Cals?|Calories?)\s*[-:]\s*(\d+)\b',
    caseSensitive: false,
  );

  static final RegExp _totalPattern = RegExp(
    r'\bTotal\s*[-:]\s*(\d+)\b',
    caseSensitive: false,
  );

  static final RegExp _caloriesPattern = RegExp(
    r'\b(\d+)\s+Cals?\b',
    caseSensitive: false,
  );

  static final RegExp _mountDoomPattern = RegExp(
    r'\bthrough\s+(\d+)\s+of\s+(?:the\s+)?'
    r'round\s+of\s+(\d+)\b',
    caseSensitive: false,
  );

  MisfitBenchmarkNormalizationSummary normalizeAll(
    MisfitBenchmarkCandidateSummary summary, {
    required String sourceWorkbook,
  }) {
    final attempts = <MisfitBenchmarkNormalizationAttempt>[];

    for (final candidate in summary.candidates) {
      if (candidate.resultStatus != MisfitBenchmarkResultStatus.selected) {
        attempts.add(
          MisfitBenchmarkNormalizationAttempt(
            candidate: candidate,
            excludedReason: candidate.resultReason,
          ),
        );
        continue;
      }

      try {
        attempts.add(
          MisfitBenchmarkNormalizationAttempt(
            candidate: candidate,
            benchmarkAttempt: normalize(
              candidate,
              sourceWorkbook: sourceWorkbook,
            ),
          ),
        );
      } catch (error) {
        attempts.add(
          MisfitBenchmarkNormalizationAttempt(
            candidate: candidate,
            error: error.toString(),
          ),
        );
      }
    }

    return MisfitBenchmarkNormalizationSummary(
      attempts: List.unmodifiable(attempts),
    );
  }

  BenchmarkAttempt normalize(
    MisfitBenchmarkCandidate candidate, {
    required String sourceWorkbook,
  }) {
    if (candidate.resultStatus != MisfitBenchmarkResultStatus.selected) {
      throw FormatException(
        'Benchmark candidate does not have a selected result',
      );
    }

    if (candidate.date.isEmpty) {
      throw FormatException(
        'Benchmark candidate does not have a resolved date',
      );
    }

    final value = switch (candidate.benchmarkKey) {
      'matt' => _normalizeMatt(candidate),
      'cube_steaked' => _value(
        _required(
          _totalPattern,
          candidate.resultText,
          'Cube Steaked result does not contain a total score',
        ),
      ),
      'row_mount_doom' => _normalizeMountDoom(candidate),
      'row_cube_test' ||
      'c2_bike_cube_test' ||
      'ski_cube_test' ||
      'echo_bike_cube_test' => _normalizeCube(candidate),
      'spiders_on_mars' => _value(_lastCalories(candidate.resultText)),
      'cleo' ||
      'pennies' ||
      'continental_drive_75' ||
      'chuckles_1_2' ||
      'bumper_cables' => _normalizeTime(candidate),
      'hurt_and_injured' ||
      'cupcake_lungs' ||
      'might_not' ||
      'speed_not_volume' => _normalizeRoundsReps(candidate),
      'kill_o_watt' => _normalizeKillOWatt(candidate),
      'kill_o_meter' => _normalizeKillOMeter(candidate),
      'power_output_bike_test' ||
      'power_output_echo_bike_test' ||
      'power_output_ski_test' ||
      'power_output_row_test' => throw FormatException(
        'Power Output result parsing is not yet supported',
      ),
      _ => throw FormatException(
        'Unsupported benchmark normalization: '
        '${candidate.benchmarkKey}',
      ),
    };

    return BenchmarkAttempt(
      benchmarkId: value.benchmarkId ?? candidate.benchmarkKey,
      date: DateTime.parse(candidate.date),
      score: value.score,
      sourceWorkbook: sourceWorkbook,
      programDay: candidate.programDay,
      details: value.details,
      notes: candidate.resultText,
    );
  }

  _NormalizedValue _normalizeMatt(MisfitBenchmarkCandidate candidate) {
    final match =
        _averageWattsPattern.firstMatch(candidate.resultText) ??
        _totalAverageWattsPattern.firstMatch(candidate.resultText) ??
        _averagesTablePattern.firstMatch(candidate.resultText);

    if (match == null) {
      throw FormatException('M.A.T.T. result does not contain average watts');
    }

    final benchmarkId = switch (candidate.modality) {
      'echo' => 'matt_echo_bike',
      'bikeErg' => 'matt_c2_bike',
      'ski' => 'matt_ski',
      'row' => 'matt_row',
      _ => throw FormatException(
        'Unsupported M.A.T.T. modality: '
        '${candidate.modality.isEmpty ? '(unknown)' : candidate.modality}',
      ),
    };

    return _NormalizedValue(benchmarkId: benchmarkId, score: match.group(1)!);
  }

  _NormalizedValue _normalizeTime(MisfitBenchmarkCandidate candidate) {
    return _value(
      _required(
        _timePattern,
        candidate.resultText,
        '${candidate.benchmarkName} result does not contain a time',
      ),
    );
  }

  _NormalizedValue _normalizeCube(MisfitBenchmarkCandidate candidate) {
    final match =
        _totalCaloriesPattern.firstMatch(candidate.resultText) ??
        _totalPattern.firstMatch(candidate.resultText);

    if (match == null) {
      throw FormatException(
        '${candidate.benchmarkName} result does not contain '
        'total calories',
      );
    }

    return _NormalizedValue(
      score: match.group(1)!,
      details: candidate.resultText,
    );
  }

  _NormalizedValue _normalizeRoundsReps(MisfitBenchmarkCandidate candidate) {
    final match =
        _plusScorePattern.firstMatch(candidate.resultText) ??
        _writtenRoundsRepsPattern.firstMatch(candidate.resultText);

    if (match == null) {
      throw FormatException(
        '${candidate.benchmarkName} result does not contain '
        'a rounds-and-reps score',
      );
    }

    return _NormalizedValue(
      score: '${match.group(1)}+${match.group(2)}',
      details: candidate.benchmarkKey == 'hurt_and_injured'
          ? candidate.resultText
          : '',
    );
  }

  _NormalizedValue _normalizeKillOWatt(MisfitBenchmarkCandidate candidate) {
    final rounds = RegExp(
      r'^\s*(\d+)\s*/\s*(\d+)\s*$',
      multiLine: true,
    ).allMatches(candidate.resultText).toList();

    if (rounds.isEmpty) {
      throw FormatException(
        'Kill-O-Watt result does not contain RPM/watts rounds',
      );
    }

    final lowestWatts = rounds
        .map((round) => int.parse(round.group(2)!))
        .reduce((left, right) => left < right ? left : right);

    return _NormalizedValue(
      score: lowestWatts.toString(),
      details: candidate.resultText,
    );
  }

  _NormalizedValue _normalizeKillOMeter(MisfitBenchmarkCandidate candidate) {
    final times = _timePattern
        .allMatches(candidate.resultText)
        .map((match) => match.group(1)!)
        .toList();

    if (times.isEmpty) {
      throw FormatException(
        'Kill-O-Meter result does not contain interval times',
      );
    }

    var slowest = times.first;
    var slowestSeconds = _seconds(slowest);

    for (final time in times.skip(1)) {
      final seconds = _seconds(time);
      if (seconds > slowestSeconds) {
        slowest = time;
        slowestSeconds = seconds;
      }
    }

    return _NormalizedValue(score: slowest, details: candidate.resultText);
  }

  _NormalizedValue _normalizeMountDoom(MisfitBenchmarkCandidate candidate) {
    final match = _mountDoomPattern.firstMatch(candidate.resultText);

    if (match == null) {
      throw FormatException(
        'Mount Doom result does not identify the failed round',
      );
    }

    final partial = int.parse(match.group(1)!);
    final failedRound = int.parse(match.group(2)!);

    if (failedRound < 20 || partial < 0 || partial >= failedRound) {
      throw FormatException('Invalid Mount Doom result');
    }

    var score = partial;
    for (var round = 20; round < failedRound; round++) {
      score += round;
    }

    return _NormalizedValue(
      score: score.toString(),
      details:
          'Completed rounds 20 through ${failedRound - 1}, '
          'then $partial of $failedRound in the failed round.',
    );
  }

  String _required(RegExp pattern, String text, String error) {
    final match = pattern.firstMatch(text);
    if (match == null) {
      throw FormatException(error);
    }
    return match.group(1)!;
  }

  String _lastCalories(String text) {
    final matches = _caloriesPattern.allMatches(text).toList();

    if (matches.isEmpty) {
      throw FormatException(
        'Spiders on Mars result does not contain final-row calories',
      );
    }

    return matches.last.group(1)!;
  }

  double _seconds(String value) {
    final parts = value.split(':');
    return int.parse(parts[0]) * 60 + double.parse(parts[1]);
  }

  _NormalizedValue _value(String score) {
    return _NormalizedValue(score: score);
  }
}

class _NormalizedValue {
  final String? benchmarkId;
  final String score;
  final String details;

  const _NormalizedValue({
    this.benchmarkId,
    required this.score,
    this.details = '',
  });
}
