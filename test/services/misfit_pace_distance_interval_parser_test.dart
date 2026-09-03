import 'package:flutter_test/flutter_test.dart';
import 'package:mft_gear_matrix/services/misfit_pace_distance_interval_parser.dart';

void main() {
  const parser = MisfitPaceDistanceIntervalParser();

  test('parses run mile pace and distance pairs', () {
    const text =
        'Per Rd Pace/Mile - '
        '7:27/.17, 6:35/.19, 6:35/.19, 6:20/.20';

    expect(parser.extract(text), [
      {'primaryMetric': '7:27', 'distance': '.17'},
      {'primaryMetric': '6:35', 'distance': '.19'},
      {'primaryMetric': '6:35', 'distance': '.19'},
      {'primaryMetric': '6:20', 'distance': '.20'},
    ]);
  });

  test('converts kilometer distances to meters', () {
    const text = '6:44/.42KM, 6:48/.41KM, 7:04/.40KM';

    expect(parser.extract(text), [
      {'primaryMetric': '6:44', 'distance': '420'},
      {'primaryMetric': '6:48', 'distance': '410'},
      {'primaryMetric': '7:04', 'distance': '400'},
    ]);
  });

  test('repairs missing BikeErg pace colons', () {
    const text =
        '155.3/3121, 154.5/3143, '
        '152.8/3189, 151.1/3240';

    expect(parser.extract(text), [
      {'primaryMetric': '1:55.3', 'distance': '3121'},
      {'primaryMetric': '1:54.5', 'distance': '3143'},
      {'primaryMetric': '1:52.8', 'distance': '3189'},
      {'primaryMetric': '1:51.1', 'distance': '3240'},
    ]);
  });

  test('does not parse pace-only sequences', () {
    expect(parser.extract('1:50.4/1:50.0/1:50.8/1:50.4'), isEmpty);
  });
}
