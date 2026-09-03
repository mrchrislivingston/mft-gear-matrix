import 'package:flutter_test/flutter_test.dart';
import 'package:mft_gear_matrix/services/misfit_candidate_reader.dart';
import 'package:mft_gear_matrix/services/misfit_duplicate_check_service.dart';
import 'package:mft_gear_matrix/services/misfit_execution_plan_parser.dart';
import 'package:mft_gear_matrix/services/misfit_normalization_preview_service.dart';
import 'package:mft_gear_matrix/services/misfit_workout_normalizer.dart';
import 'package:mft_gear_matrix/services/misfit_workout_parser.dart';

void main() {
  MisfitWorkoutCandidate candidate({
    required String programDay,
    required String date,
  }) {
    return MisfitWorkoutCandidate(
      sourceRow: 10,
      sourceColumn: 4,
      dateHeader: programDay,
      programDay: programDay,
      date: date,
      workoutType: MisfitWorkoutType.gear,
      prescription: 'G3',
      modality: 'row',
      importStatus: MisfitImportStatus.ready,
      statusReason: 'Single supported workout',
      resultDetail: MisfitResultDetail.intervalResults,
      programmingText: 'Aerobic Row - 3rd Gear',
      resultText: '1000/990/980',
    );
  }

  MisfitNormalizationAttempt attemptFor(MisfitWorkoutCandidate candidate) {
    return MisfitNormalizationAttempt(
      candidate: candidate,
      workout: const MisfitNormalizedWorkoutPreview(
        prescriptionId: 'G3',
        modality: 'row',
        executionPlan: MisfitExecutionPlan(
          workDuration: '8:00',
          intervalCount: 3,
        ),
        duration: '',
        intervals: [],
      ),
      error: null,
    );
  }

  test(
    'checks the same workout identity used by the Python importer',
    () async {
      final first = candidate(programDay: 'W1D1', date: '2025-11-03');
      final second = candidate(programDay: 'W2D1', date: '2025-11-10');

      final calls = <String>[];

      final service = MisfitDuplicateCheckService(
        lookupOverride:
            ({
              required prescriptionId,
              required modality,
              required date,
              required workDuration,
              required intervalCount,
              required sourceWorkbook,
              required programDay,
            }) async {
              calls.add(
                '$prescriptionId|$modality|$date|$workDuration|'
                '$intervalCount|$sourceWorkbook|$programDay',
              );
              return programDay == 'W1D1';
            },
      );

      final summary = await service.check(
        normalizationSummary: MisfitNormalizationSummary(
          attempts: [attemptFor(first), attemptFor(second)],
        ),
        sourceWorkbook: 'Phase II 2025_2026',
      );

      expect(summary.checked, 2);
      expect(summary.duplicates, 1);
      expect(summary.newWorkouts, 1);
      expect(summary.isDuplicate(first), isTrue);
      expect(summary.isDuplicate(second), isFalse);

      expect(calls, [
        'G3|row|2025-11-03|8:00|3|Phase II 2025_2026|W1D1',
        'G3|row|2025-11-10|8:00|3|Phase II 2025_2026|W2D1',
      ]);
    },
  );

  test('rejects a normalized workout with no resolved date', () async {
    final unresolved = candidate(programDay: 'W1D1', date: '');

    final service = MisfitDuplicateCheckService(
      lookupOverride:
          ({
            required prescriptionId,
            required modality,
            required date,
            required workDuration,
            required intervalCount,
            required sourceWorkbook,
            required programDay,
          }) async {
            return false;
          },
    );

    expect(
      () => service.check(
        normalizationSummary: MisfitNormalizationSummary(
          attempts: [attemptFor(unresolved)],
        ),
        sourceWorkbook: 'Phase II 2025_2026',
      ),
      throwsFormatException,
    );
  });
}
