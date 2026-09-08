import 'package:flutter_test/flutter_test.dart';
import 'package:mft_gear_matrix/models/benchmark_attempt.dart';
import 'package:mft_gear_matrix/models/benchmark_score_type.dart';
import 'package:mft_gear_matrix/services/benchmark_analysis_service.dart';

BenchmarkAttempt attempt(String score, int year, int month, int day) {
  return BenchmarkAttempt(
    benchmarkId: 'test',
    date: DateTime(year, month, day),
    score: score,
  );
}

void main() {
  const service = BenchmarkAnalysisService();

  test('lower time is better', () {
    final analysis = service.analyze(
      scoreType: BenchmarkScoreType.forTime,
      attempts: [attempt('10:00', 2026, 1, 1), attempt('9:30', 2026, 2, 1)],
    );

    expect(analysis.latest!.score, '9:30');
    expect(analysis.previous!.score, '10:00');
    expect(analysis.best!.score, '9:30');
    expect(analysis.trend, BenchmarkTrend.improved);
    expect(analysis.trendLabel, 'Faster by 0:30');
  });

  test('higher weight is better while retaining historical PR', () {
    final analysis = service.analyze(
      scoreType: BenchmarkScoreType.maxWeight,
      attempts: [
        attempt('315', 2025, 9, 12),
        attempt('320', 2025, 10, 27),
        attempt('305', 2026, 8, 7),
      ],
    );

    expect(analysis.latest!.score, '305');
    expect(analysis.previous!.score, '320');
    expect(analysis.best!.score, '320');
    expect(analysis.trend, BenchmarkTrend.declined);
    expect(analysis.trendLabel, 'Lower by 15 lb');
  });

  test('rounds and reps compare rounds before reps', () {
    final analysis = service.analyze(
      scoreType: BenchmarkScoreType.roundsReps,
      attempts: [attempt('5+74', 2025, 10, 3), attempt('5+11', 2026, 8, 29)],
    );

    expect(analysis.best!.score, '5+74');
    expect(analysis.trend, BenchmarkTrend.declined);
    expect(analysis.trendLabel, 'Fewer by 63 reps');
  });

  test('equal results are reported as tied', () {
    final analysis = service.analyze(
      scoreType: BenchmarkScoreType.maxWeight,
      attempts: [attempt('235', 2026, 1, 2), attempt('235', 2026, 7, 31)],
    );

    expect(analysis.trend, BenchmarkTrend.tied);
    expect(analysis.trendLabel, 'Matched previous result');
  });

  test('unconfigured benchmarks preserve history without comparing it', () {
    final analysis = service.analyze(
      scoreType: BenchmarkScoreType.unconfigured,
      attempts: [attempt('unknown', 2026, 1, 1)],
    );

    expect(analysis.latest, isNotNull);
    expect(analysis.best, isNull);
    expect(analysis.trend, BenchmarkTrend.unavailable);
    expect(analysis.trendLabel, 'Scoring analysis pending');
  });
}
