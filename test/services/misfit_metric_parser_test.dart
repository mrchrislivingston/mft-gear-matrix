import 'package:flutter_test/flutter_test.dart';
import 'package:mft_gear_matrix/services/misfit_metric_parser.dart';

void main() {
  const parser = MisfitMetricParser();

  test('extracts minute duration', () {
    expect(
      parser.extractDuration('30 min avg watt - 170\n30 min avg hr - 128'),
      '00:30:00',
    );
  });

  test('converts durations longer than one hour', () {
    expect(parser.extractDuration('90 minutes total'), '01:30:00');
  });

  test('extracts a clock duration at the start of a line', () {
    expect(
      parser.extractDuration('60:00 Run in Zone 2 - 5.14 miles'),
      '01:00:00',
    );
  });

  test('extracts average watts and heart rate', () {
    const text =
        '30 min avg watt - 170\n'
        '30 min avg hr - 128';

    expect(parser.extractAverageMetrics(text), {
      'watts': '170',
      'heartRate': '128',
    });
  });

  test('extracts pace and distance from a Zone run', () {
    const text =
        '60:00 Run in Zone 2 - 5.14 miles\n'
        'Avg HR 129 / Pace 11:40';

    expect(parser.extractAverageMetrics(text), {
      'heartRate': '129',
      'primaryMetric': '11:40',
      'distance': '5.14',
    });
  });

  test('extracts pace written before mile average', () {
    const text = 'Outdoor run, but kept a 9:34/mile average.';

    expect(parser.extractAveragePace(text), {'primaryMetric': '9:34'});
  });

  test('extracts explicitly labeled actual run', () {
    const text = 'Actual - 7:27 pace / .17 miles';

    expect(parser.extractAverageMetrics(text), {
      'primaryMetric': '7:27',
      'distance': '.17',
    });
  });

  test('extracts a labeled meter distance', () {
    expect(
      parser.extractAverageMetrics(
        'Average watts: 183\n'
        'Average pace: 2:04\n'
        'Distance: 9680 meters',
      ),
      {'watts': '183', 'primaryMetric': '2:04', 'distance': '9680'},
    );
  });

  test('returns empty values when metrics are absent', () {
    expect(parser.extractDuration('Felt pretty good'), '');
    expect(parser.extractAverageMetrics('Felt pretty good'), isEmpty);
  });
}
