import 'package:flutter_test/flutter_test.dart';
import 'package:mft_gear_matrix/services/misfit_benchmark_candidate_reader.dart';
import 'package:mft_gear_matrix/services/misfit_benchmark_normalizer.dart';
import 'package:mft_gear_matrix/services/misfit_date_resolver.dart';
import 'package:mft_gear_matrix/services/misfit_workout_parser.dart';

MisfitBenchmarkCandidate benchmarkCandidate({
  required String key,
  required String name,
  required String result,
}) {
  return MisfitBenchmarkCandidate(
    sourceRow: 1,
    sourceColumn: 1,
    resultSourceRow: 2,
    dateHeader: 'W1D1',
    programDay: 'W1D1',
    date: '2025-01-01',
    dateStatus: MisfitDateStatus.exact,
    benchmarkKey: key,
    benchmarkName: name,
    modality: '',
    programmingText: name,
    resultText: result,
    resultStatus: MisfitBenchmarkResultStatus.selected,
    resultReason: 'Result found',
  );
}

void main() {
  test('normalizes Rule 8 and Bike Mount Doom fresh exports', () {
    const normalizer = MisfitBenchmarkNormalizer();

    final summary = normalizer.normalizeAll(
      MisfitBenchmarkCandidateSummary(
        candidates: [
          benchmarkCandidate(key: 'rule_8', name: 'Rule 8', result: '7:23'),
          benchmarkCandidate(
            key: 'bike_mount_doom',
            name: 'Bike Mount Doom',
            result: 'Hit 40 cals on the round of 41',
          ),
        ],
      ),
      sourceWorkbook: 'Fresh export regression',
    );

    expect(summary.successful, 2);
    expect(summary.failed, 0);
    expect(summary.attempts[0].benchmarkAttempt?.score, '7:23');
    expect(summary.attempts[1].benchmarkAttempt?.score, '670');
    expect(
      summary.attempts[1].benchmarkAttempt?.details,
      contains('Completed rounds 20 through 40'),
    );
  });

  test('skips copied equipment-modification instructions', () {
    const parser = MisfitWorkoutParser();

    final classification = parser.classifyCandidate(
      programmingText: 'Zone 2 Row',
      resultText: 'Equipment Modification - Any machine 1:1',
    );

    expect(classification.status, MisfitImportStatus.skip);
    expect(
      classification.reason,
      'Result contains instructions, not a recorded result',
    );
  });

  test('skips target-only and non-importable result text', () {
    const parser = MisfitWorkoutParser();

    final cases = [
      (
        programming: 'Zone 1',
        result: 'Zone 1 yard work? moving rocks from here to there.',
      ),
      (programming: 'Zone 2 Echo Bike', result: 'Too much drama today.'),
      (
        programming: 'Zone 2 Echo Bike',
        result: 'Tell your parents you love them',
      ),
      (
        programming: 'G2 Row',
        result: 'Rd1 - ~1:30 - 15 BBJO Rd2 - ~1:10 - 15 BBJO',
      ),
      (programming: 'G5 C2 Bike', result: '1:47-1:49'),
      (programming: 'G6 C2 Bike', result: '1:44–1:46'),
    ];

    for (final entry in cases) {
      final classification = parser.classifyCandidate(
        programmingText: entry.programming,
        resultText: entry.result,
      );

      expect(
        classification.status,
        MisfitImportStatus.skip,
        reason: entry.result,
      );
    }
  });

  test('skips explicit alternate-day and did-not-run results', () {
    const parser = MisfitWorkoutParser();

    final moved = parser.classifyCandidate(
      programmingText: 'G7 Echo Bike',
      resultText: 'Moved this to tomorrow. Had to bounce for work.',
    );
    final didNotRun = parser.classifyCandidate(
      programmingText: 'G6 Run',
      resultText: 'Didnt run because I am giant baby',
    );

    expect(moved.status, MisfitImportStatus.skip);
    expect(didNotRun.status, MisfitImportStatus.skip);
  });
}
