import 'package:flutter_test/flutter_test.dart';
import 'package:mft_gear_matrix/services/misfit_interval_time_parser.dart';

void main() {
  const parser = MisfitIntervalTimeParser();

  test('extracts interval completion times before pace values', () {
    const text =
        'Total time/Pace - per round\n'
        '4:47.4/1:53.4\n'
        '4:43.8/1:52.7\n'
        '4:41.5/1:52.4\n'
        '4:35.8/1:51.3';

    expect(parser.extract(text), ['4:47.4', '4:43.8', '4:41.5', '4:35.8']);
  });

  test('returns no times when no time slash pairs exist', () {
    expect(parser.extract('Average watts 183'), isEmpty);
  });
}
