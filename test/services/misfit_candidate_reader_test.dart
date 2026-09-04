import 'package:flutter_test/flutter_test.dart';
import 'package:mft_gear_matrix/services/misfit_candidate_reader.dart';
import 'package:mft_gear_matrix/services/misfit_csv_service.dart';
import 'package:mft_gear_matrix/services/misfit_workout_parser.dart';

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
  test('resolves an ambiguous Zone erg using result consistency', () {
    const document = MisfitCsvDocument(
      rows: [
        [
          'Thurs - Feb 5 - W5D4',
          'Zone 2 - C2 Bike or Row\n'
              '45:00 C2 Bike or Row @ Zone 2',
        ],
        [
          'Notes / Results',
          '45:00 in Z2\n'
              'Avg Power - 173\n'
              'Avg HR - 126\n'
              'Avg Pace - 2:01\n'
              'Distance - 22.40 KM',
        ],
      ],
    );

    final summary = reader.read(document, startYear: 2026);
    final candidate = summary.candidates.single;

    expect(candidate.programDay, 'W5D4');
    expect(candidate.modality, 'bikeErg');
    expect(candidate.importStatus, MisfitImportStatus.ready);
    expect(
      candidate.statusReason,
      'Result duration, pace, and distance identify the modality',
    );
  });

  test('keeps an ambiguous erg deferred when metrics do not agree', () {
    const document = MisfitCsvDocument(
      rows: [
        [
          'W1D1',
          'Zone 2 - C2 Bike or Row\n'
              '45:00 C2 Bike or Row @ Zone 2',
        ],
        [
          'Notes / Results',
          '45:00 in Z2\n'
              'Avg Pace - 2:01\n'
              'Distance - 16 KM',
        ],
      ],
    );

    final candidate = reader.read(document).candidates.single;

    expect(candidate.modality, 'row/bikeErg');
    expect(candidate.importStatus, MisfitImportStatus.tbdLater);
  });
  test('splits a supported mixed-Gear result into separate candidates', () {
    const document = MisfitCsvDocument(
      rows: [
        [
          'Wed - Feb 11 - W6D3',
          'Build Row - 7th/8th Gear\n'
              'AMRAP 2:30 x 3\n'
              'Row for Meters @ 7th Gear\n'
              'Rest 3:15\n'
              'Then\n'
              'AMRAP 1:30 x 3\n'
              'Row for Meters @ 8th Gear\n'
              'Rest 3:30',
        ],
        [
          'Notes / Results',
          'Dist/Watts/Cals/Pace\n'
              '692/275/52/1:48.4\n'
              '703/288/54/1:46.7\n'
              '709/295/55/1:45.8\n'
              '443/333/36/1:41.6\n'
              '454/359/38/1:39.1\n'
              '461/376/40/1:37.6\n'
              'Back feels really good and ready to go!!',
        ],
      ],
    );

    final summary = reader.read(document, startYear: 2026);

    expect(summary.total, 2);
    expect(summary.ready, 2);
    expect(summary.deferred, 0);
    expect(summary.candidates.map((candidate) => candidate.prescription), [
      'G7',
      'G8',
    ]);

    final gearSeven = summary.candidates[0];
    final gearEight = summary.candidates[1];

    expect(gearSeven.executionPlan?.intervalCount, 3);
    expect(gearSeven.executionPlan?.workDuration, '2:30');
    expect(gearSeven.resultText, contains('692/275/52/1:48.4'));
    expect(gearSeven.resultText, isNot(contains('443/333/36/1:41.6')));

    expect(gearEight.executionPlan?.intervalCount, 3);
    expect(gearEight.executionPlan?.workDuration, '1:30');
    expect(gearEight.resultText, contains('443/333/36/1:41.6'));
    expect(gearEight.resultText, isNot(contains('692/275/52/1:48.4')));
  });

  test('keeps an unsafe mixed-Gear result deferred', () {
    const document = MisfitCsvDocument(
      rows: [
        [
          'W1D1',
          'Build Row - 7th/8th Gear\n'
              'AMRAP 2:30 x 3\n'
              'Row for Meters @ 7th Gear\n'
              'AMRAP 1:30 x 3\n'
              'Row for Meters @ 8th Gear',
        ],
        ['Notes / Results', 'Felt good but did not record every interval'],
      ],
    );

    final summary = reader.read(document);

    expect(summary.total, 1);
    expect(summary.deferred, 1);
    expect(summary.candidates.single.prescription, 'G7/G8');
  });
}
