import 'package:flutter_test/flutter_test.dart';

import 'package:mft_gear_matrix/services/misfit_benchmark_candidate_reader.dart';
import 'package:mft_gear_matrix/services/misfit_csv_service.dart';

void main() {
  const reader = MisfitBenchmarkCandidateReader();

  test('discovers a benchmark with split date and program-day columns', () {
    const document = MisfitCsvDocument(
      rows: [
        ['Mon - 2/16', 'W1D1', 'M.A.T.T. Echo Bike Test'],
        ['NOTES / RESULTS', '', 'Avg Watts - 288\nAvg RPM - 75\n300 Cals'],
      ],
    );

    final summary = reader.read(document, startYear: 2026);

    expect(summary.total, 1);
    expect(summary.selected, 1);

    final candidate = summary.candidates.single;
    expect(candidate.benchmarkKey, 'matt');
    expect(candidate.benchmarkName, 'M.A.T.T.');
    expect(candidate.modality, 'echo');
    expect(candidate.date, '2026-02-16');
    expect(candidate.programDay, 'W1D1');
    expect(candidate.sourceRow, 1);
    expect(candidate.sourceColumn, 3);
    expect(candidate.resultSourceRow, 2);
    expect(candidate.resultStatus, MisfitBenchmarkResultStatus.selected);
  });

  test('finds a compatible Cube result in another column', () {
    const document = MisfitCsvDocument(
      rows: [
        ['Wed - 2/18', 'W1D3', 'Row Cube Test', ''],
        ['NOTES / RESULTS', '', '', 'Rd1 - 80\nRd2 - 82\nTotal Calories - 330'],
      ],
    );

    final candidate = reader.read(document, startYear: 2026).candidates.single;

    expect(candidate.benchmarkKey, 'row_cube_test');
    expect(candidate.resultSourceRow, 2);
    expect(candidate.resultText, contains('Total Calories - 330'));
    expect(candidate.resultReason, 'Compatible result found in another column');
  });

  test('keeps a benchmark with no recorded result visible', () {
    const document = MisfitCsvDocument(
      rows: [
        ['Fri - 2/20', 'W1D5', 'Power Output Row Test'],
        ['NOTES / RESULTS', '', ''],
      ],
    );

    final summary = reader.read(document, startYear: 2026);

    expect(summary.total, 1);
    expect(summary.missing, 1);
    expect(
      summary.candidates.single.resultStatus,
      MisfitBenchmarkResultStatus.missing,
    );
    expect(
      summary.candidates.single.resultReason,
      'No recorded benchmark result',
    );
  });

  test('ignores an empty duplicate header row', () {
    const document = MisfitCsvDocument(
      rows: [
        ['3/30', 'W7D1', ''],
        [],
        ['Mon - 4/6/2026', 'W8D1', 'Spiders on Mars'],
        ['NOTES / RESULTS', '', 'Final Row - 6 Cals'],
      ],
    );

    final summary = reader.read(document, startYear: 2026);

    expect(summary.total, 1);
    expect(summary.candidates.single.benchmarkKey, 'spiders_on_mars');
    expect(summary.candidates.single.date, '2026-04-06');
  });

  test('excludes known non-results and modified attempts', () {
    const document = MisfitCsvDocument(
      rows: [
        ['Mon - W1D1 July 27', '', 'Fairy Dust'],
        ['NOTES / RESULTS', '', 'Skipped Gym'],
        ['Tues - W1D2 July 28', '', 'Enzo Gorlomi'],
        [
          'NOTES / RESULTS',
          '',
          'Replaced the walking lunges with GHDs.\n17:27',
        ],
        ['Wed - W1D3 July 29', '', 'Speed, Not Volume'],
        ['NOTES / RESULTS', '', 'You better get into the 6th Rd'],
      ],
    );

    final summary = reader.read(document, startYear: 2026);

    expect(summary.total, 3);
    expect(summary.selected, 0);
    expect(summary.excluded, 3);
    expect(summary.candidates.map((candidate) => candidate.resultReason), [
      'Result indicates benchmark was not completed',
      'Recorded workout was modified',
      'No completed benchmark score was recorded',
    ]);
  });

  test('keeps a written Speed Not Volume score selected', () {
    const document = MisfitCsvDocument(
      rows: [
        ['Sat - W1D6 August 1', '', 'Speed, Not Volume'],
        [
          'NOTES / RESULTS',
          '',
          'Went about 70% effort and still got 5 rds 11 reps.',
        ],
      ],
    );

    final summary = reader.read(document, startYear: 2026);

    expect(summary.total, 1);
    expect(summary.selected, 1);
    expect(summary.excluded, 0);
    expect(
      summary.candidates.single.resultStatus,
      MisfitBenchmarkResultStatus.selected,
    );
  });
}
