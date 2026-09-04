import 'package:flutter_test/flutter_test.dart';

import 'package:mft_gear_matrix/services/misfit_benchmark_registry.dart';

void main() {
  const registry = MisfitBenchmarkRegistry();

  test('matches punctuation-insensitive benchmark aliases', () {
    final matches = registry.findMatches([
      'Retest: M. A. T. T. Test - Echo Bike',
    ]);

    expect(matches.map((entry) => entry.key), ['matt']);
  });

  test('keeps the more specific Power Output match', () {
    final matches = registry.findMatches(['Power Output Echo Bike Test']);

    expect(matches.map((entry) => entry.key), ['power_output_echo_bike_test']);
  });

  test('contains an entry for every maintained benchmark family', () {
    expect(MisfitBenchmarkRegistry.entries.length, greaterThanOrEqualTo(30));
    expect(
      MisfitBenchmarkRegistry.entries.map((entry) => entry.key),
      containsAll([
        'matt',
        'row_cube_test',
        'spiders_on_mars',
        'power_output_row_test',
      ]),
    );
  });
}
