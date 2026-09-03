import 'package:flutter_test/flutter_test.dart';
import 'package:mft_gear_matrix/services/misfit_metric_parser.dart';
import 'package:mft_gear_matrix/services/misfit_pace_distance_interval_parser.dart';

void main() {
  const metrics = MisfitMetricParser();
  const intervals = MisfitPaceDistanceIntervalParser();

  test('parses labeled BikeErg distance and pace', () {
    expect(metrics.extractAverageMetrics('Distance - 16.11\nPace - 1:52'), {
      'primaryMetric': '1:52',
      'distance': '16.11',
    });
  });

  test('parses Row distance and pace rounds without Total', () {
    expect(
      intervals.extract(
        'Rd 1 - 3290m/1:58.5\n'
        'Rd 2 - 3289m/1:58.5\n'
        'Total - 6579m/1:58.5',
      ),
      [
        {'primaryMetric': '1:58.5', 'distance': '3290'},
        {'primaryMetric': '1:58.5', 'distance': '3289'},
      ],
    );
  });

  test('parses Run meter and pace table rows', () {
    expect(
      intervals.extract(
        '380m,6:21 min/mile\n'
        '413m,5:51 min/mile',
      ),
      [
        {'primaryMetric': '6:21', 'distance': '380'},
        {'primaryMetric': '5:51', 'distance': '413'},
      ],
    );
  });
}
