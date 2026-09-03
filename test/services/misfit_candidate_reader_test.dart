import 'package:flutter_test/flutter_test.dart';
import 'package:mft_gear_matrix/services/misfit_candidate_reader.dart';
import 'package:mft_gear_matrix/services/misfit_csv_service.dart';

void main() {
  const reader = MisfitCandidateReader();

  test('reads workout cells and pairs them with the following result row', () {
    const document = MisfitCsvDocument(
      rows: [
        [
          'W4D1 September 22',
          'Back Squat 5 x 5',
          'Aerobic Row - 3rd Gear\n3x3:00',
          'Zone 2 C2 Bike',
        ],
        [
          '',
          '225 pounds',
          'Round 1: 1000m\nRound 2: 990m',
          'Average watts 175',
        ],
      ],
    );

    final summary = reader.read(document);

    expect(summary.total, 2);
    expect(summary.ready, 2);
    expect(summary.review, 0);
    expect(summary.deferred, 0);
    expect(summary.skipped, 0);

    expect(summary.candidates.first.sourceRow, 1);
    expect(summary.candidates.first.sourceColumn, 3);
    expect(summary.candidates.first.programDay, 'W4D1');
    expect(summary.candidates.first.prescription, 'G3');
    expect(summary.candidates.first.modality, 'row');

    final executionPlan = summary.candidates.first.executionPlan;
    expect(executionPlan, isNotNull);
    expect(executionPlan!.intervalCount, 3);
    expect(executionPlan.workDuration, '3:00');
  });

  test('supports written, numeric, and week-day-only headers', () {
    const document = MisfitCsvDocument(
      rows: [
        ['September 22', 'Zone 2 Row'],
        ['', 'Average pace 2:04'],
        ['10/7', 'Build Echo - 6th Gear'],
        ['', '72/80/81/83'],
        ['W9D3', 'P2 SkiErg'],
        ['', 'Calories 20'],
      ],
    );

    final summary = reader.read(document);

    expect(summary.total, 3);
    expect(summary.candidates.map((candidate) => candidate.prescription), [
      'Z2',
      'G6',
      'P2',
    ]);
  });

  test('classifies missing results and mixed workouts', () {
    const document = MisfitCsvDocument(
      rows: [
        ['W5D1', 'Zone 2 Run', 'G4 into G5 Row', 'Zone 2 Run and Row'],
        ['', '', 'Completed', 'Completed'],
      ],
    );

    final summary = reader.read(document);

    expect(summary.total, 3);
    expect(summary.skipped, 1);
    expect(summary.deferred, 2);
  });

  test('ignores non-workout spreadsheet content', () {
    const document = MisfitCsvDocument(
      rows: [
        ['Instructions', 'Zone 2 Row'],
        ['Notes', 'Average pace 2:04'],
        ['W1D1', 'Back Squat 5 x 5'],
        ['', '225 pounds'],
      ],
    );

    final summary = reader.read(document);

    expect(summary.total, 0);
  });
}
