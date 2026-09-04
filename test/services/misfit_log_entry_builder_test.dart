import 'package:flutter_test/flutter_test.dart';
import 'package:mft_gear_matrix/models/modality.dart';
import 'package:mft_gear_matrix/models/workout_metric.dart';
import 'package:mft_gear_matrix/services/misfit_candidate_reader.dart';
import 'package:mft_gear_matrix/services/misfit_execution_plan_parser.dart';
import 'package:mft_gear_matrix/services/misfit_log_entry_builder.dart';
import 'package:mft_gear_matrix/services/misfit_normalization_preview_service.dart';
import 'package:mft_gear_matrix/services/misfit_workout_normalizer.dart';
import 'package:mft_gear_matrix/services/misfit_workout_parser.dart';

void main() {
  const builder = MisfitLogEntryBuilder();

  MisfitWorkoutCandidate candidate({
    required String programDay,
    required String date,
    String modality = 'row',
  }) {
    return MisfitWorkoutCandidate(
      sourceRow: 10,
      sourceColumn: 4,
      dateHeader: programDay,
      programDay: programDay,
      date: date,
      workoutType: MisfitWorkoutType.gear,
      prescription: 'G3',
      modality: modality,
      importStatus: MisfitImportStatus.ready,
      statusReason: 'Single supported workout',
      resultDetail: MisfitResultDetail.intervalResults,
      programmingText: 'Aerobic Row - 3rd Gear',
      resultText: 'Recorded result and athlete notes',
    );
  }

  MisfitNormalizationAttempt attemptFor(
    MisfitWorkoutCandidate candidate, {
    WorkoutMetric? scoringMetric,
  }) {
    return MisfitNormalizationAttempt(
      candidate: candidate,
      workout: MisfitNormalizedWorkoutPreview(
        prescriptionId: 'G3',
        modality: 'row',
        executionPlan: MisfitExecutionPlan(
          workDuration: '8:00',
          intervalCount: 3,
        ),
        duration: '',
        scoringMetric: scoringMetric,
        intervals: [
          MisfitNormalizedInterval(
            intervalNumber: 1,
            values: {
              'distance': '1000',
              'primaryMetric': '1:55',
              'heartRate': '151',
            },
          ),
        ],
      ),
      error: null,
    );
  }

  test('builds a typed LogEntry from a normalized attempt', () {
    final sourceCandidate = candidate(programDay: 'W1D1', date: '2025-11-03');

    final log = builder.build(
      attempt: attemptFor(sourceCandidate),
      sourceWorkbook: 'Phase II 2025_2026',
    );

    expect(log.prescriptionId, 'G3');
    expect(log.modality, Modality.row);
    expect(log.date, DateTime(2025, 11, 3));
    expect(log.sourceWorkbook, 'Phase II 2025_2026');
    expect(log.programDay, 'W1D1');
    expect(log.workDuration, '8:00');
    expect(log.intervalCount, 3);
    expect(log.notes, 'Recorded result and athlete notes');
    expect(log.intervals, hasLength(1));
    expect(log.intervals.single.values, {
      WorkoutMetric.distance: '1000',
      WorkoutMetric.primaryMetric: '1:55',
      WorkoutMetric.heartRate: '151',
    });
  });

  test('preserves the normalized scoring metric', () {
    final sourceCandidate = candidate(
      programDay: 'W1D1',
      date: '2025-11-03',
      modality: 'echo',
    );

    final log = builder.build(
      attempt: attemptFor(
        sourceCandidate,
        scoringMetric: WorkoutMetric.distance,
      ),
      sourceWorkbook: 'Phase III 2026',
    );

    expect(log.scoringMetric, WorkoutMetric.distance);
  });

  test('buildSelected includes only checked candidates', () {
    final included = candidate(programDay: 'W1D1', date: '2025-11-03');
    final excluded = candidate(programDay: 'W1D2', date: '2025-11-04');

    final logs = builder.buildSelected(
      normalizationSummary: MisfitNormalizationSummary(
        attempts: [attemptFor(included), attemptFor(excluded)],
      ),
      includedCandidates: {included},
      sourceWorkbook: 'Phase II 2025_2026',
    );

    expect(logs, hasLength(1));
    expect(logs.single.programDay, 'W1D1');
  });

  test('rejects an unresolved workout date', () {
    final unresolved = candidate(programDay: 'W1D1', date: '');

    expect(
      () => builder.build(
        attempt: attemptFor(unresolved),
        sourceWorkbook: 'Phase II 2025_2026',
      ),
      throwsFormatException,
    );
  });
}
