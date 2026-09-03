import 'package:flutter_test/flutter_test.dart';
import 'package:mft_gear_matrix/services/misfit_candidate_reader.dart';
import 'package:mft_gear_matrix/services/misfit_normalization_preview_service.dart';
import 'package:mft_gear_matrix/services/misfit_workout_parser.dart';

void main() {
  const service = MisfitNormalizationPreviewService();

  MisfitWorkoutCandidate candidate({
    required MisfitImportStatus status,
    required String result,
  }) {
    return MisfitWorkoutCandidate(
      sourceRow: 1,
      sourceColumn: 2,
      dateHeader: 'W1D1 April 17',
      programDay: 'W1D1',
      workoutType: MisfitWorkoutType.gear,
      prescription: 'G3',
      modality: 'row',
      importStatus: status,
      statusReason: 'Test',
      resultDetail: MisfitResultDetail.resultTextOnly,
      programmingText: 'Aerobic Row - 3rd Gear',
      resultText: result,
    );
  }

  test('normalizes ready candidates and records failures', () {
    final successfulCandidate = candidate(
      status: MisfitImportStatus.ready,
      result: 'Average pace 1:55',
    );
    final failedCandidate = candidate(
      status: MisfitImportStatus.ready,
      result: 'Felt pretty good',
    );
    final skippedCandidate = candidate(
      status: MisfitImportStatus.skip,
      result: '',
    );

    final summary = service.normalizeReady(
      MisfitCandidateSummary(
        candidates: [successfulCandidate, failedCandidate, skippedCandidate],
      ),
    );

    expect(summary.attempts.length, 2);
    expect(summary.successful, 1);
    expect(summary.failed, 1);

    expect(summary.attemptFor(successfulCandidate)!.workout, isNotNull);
    expect(
      summary.attemptFor(failedCandidate)!.error,
      'No supported workout metrics could be extracted',
    );
    expect(summary.attemptFor(skippedCandidate), isNull);
  });

  test('preserves normalized interval values', () {
    final rowCandidate = candidate(
      status: MisfitImportStatus.ready,
      result: '1-500, 2-510, 3-520',
    );

    final summary = service.normalizeReady(
      MisfitCandidateSummary(candidates: [rowCandidate]),
    );

    final workout = summary.attempts.single.workout!;

    expect(workout.intervals.map((interval) => interval.values['distance']), [
      '500',
      '510',
      '520',
    ]);
  });
}
