import 'package:flutter_test/flutter_test.dart';

import 'package:mft_gear_matrix/services/misfit_benchmark_candidate_reader.dart';
import 'package:mft_gear_matrix/services/misfit_benchmark_normalizer.dart';
import 'package:mft_gear_matrix/services/misfit_date_resolver.dart';

void main() {
  const normalizer = MisfitBenchmarkNormalizer();

  MisfitBenchmarkCandidate candidate({
    required String key,
    required String modality,
    required String result,
  }) {
    return MisfitBenchmarkCandidate(
      sourceRow: 1,
      sourceColumn: 2,
      resultSourceRow: 2,
      dateHeader: 'Mon - W1D1 July 27',
      programDay: 'W1D1',
      date: '2026-07-27',
      dateStatus: MisfitDateStatus.exact,
      benchmarkKey: key,
      benchmarkName: key,
      modality: modality,
      programmingText: key,
      resultText: result,
      resultStatus: MisfitBenchmarkResultStatus.selected,
      resultReason: 'Selected',
    );
  }

  String score(String key, String result, {String modality = ''}) {
    return normalizer
        .normalize(
          candidate(key: key, modality: modality, result: result),
          sourceWorkbook: 'Phase 0',
        )
        .score;
  }

  test('normalizes Phase 0 time scores', () {
    expect(score('cleo', '29:51\nVideo review'), '29:51');
    expect(score('pennies', '16:56 - Scaled to 185'), '16:56');
    expect(score('continental_drive_75', '21:33'), '21:33');
    expect(score('chuckles_1_2', '20:51'), '20:51');
    expect(score('bumper_cables', '19:44 - Sub 19'), '19:44');
  });

  test('normalizes Phase 0 rounds and reps scores', () {
    expect(score('hurt_and_injured', '6 + 12/14 Shuttle Runs'), '6+12');
    expect(score('cupcake_lungs', '5rds + 2 burpees'), '5+2');
    expect(score('might_not', '5+15'), '5+15');
    expect(score('speed_not_volume', '5 rds 11 reps'), '5+11');
  });

  test('normalizes Cube totals', () {
    expect(score('c2_bike_cube_test', 'Total - 351'), '351');
    expect(score('row_cube_test', 'Total - 329'), '329');
  });

  test('scores Kill-O-Watt by lowest watts', () {
    expect(
      score('kill_o_watt', '67/338\n67/338\n68/352\n67/338\n68/352\n68/352'),
      '338',
    );
  });

  test('scores Kill-O-Meter by slowest interval', () {
    expect(score('kill_o_meter', '3:16\n3:16\n3:19\n3:18\n3:20\n3:17'), '3:20');
  });

  test('normalizes Phase 0 MATT averages', () {
    final attempt = normalizer.normalize(
      candidate(
        key: 'matt',
        modality: 'bikeErg',
        result: 'Averages - 227/1081/1:55.5\nTotal Cals - 719',
      ),
      sourceWorkbook: 'Phase 0',
    );

    expect(attempt.benchmarkId, 'matt_c2_bike');
    expect(attempt.score, '227');
  });

  test('normalizes Spiders on Mars calories', () {
    expect(score('spiders_on_mars', '10 cals.\nThis was gross.'), '10');
  });
}
