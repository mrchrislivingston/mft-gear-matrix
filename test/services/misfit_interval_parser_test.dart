import 'package:flutter_test/flutter_test.dart';
import 'package:mft_gear_matrix/services/misfit_interval_parser.dart';

void main() {
  const parser = MisfitIntervalParser();

  test('parses a labeled per-round pace sequence', () {
    const text =
        'Definitely burned.\n'
        'Lowered the damper.\n'
        'Averaged out to 1:/km\n'
        'Per Rd - 1:50.4/1:50.0/1:50.8/1:50.4';

    expect(parser.extractIntervalPaces(text), [
      '1:50.4',
      '1:50.0',
      '1:50.8',
      '1:50.4',
    ]);
  });

  test('parses the longest plain pace sequence', () {
    const text =
        'Yes this was pretty shitty! I thought I could avg 1:50.\n'
        'Avg 8x 2:15/1:15 - 152.4\n'
        'Definitely fell off after rd 4\n'
        '1:51.7/1:50.8/1:51.2/1:51/'
        '1:53.6/1:53/1:54.4/1:53.8';

    expect(parser.extractIntervalPaces(text), [
      '1:51.7',
      '1:50.8',
      '1:51.2',
      '1:51',
      '1:53.6',
      '1:53',
      '1:54.4',
      '1:53.8',
    ]);
  });

  test('returns no paces when no sequence exists', () {
    expect(parser.extractIntervalPaces('Average watts 183'), isEmpty);
  });
}
