import 'package:flutter_test/flutter_test.dart';
import 'package:mft_gear_matrix/services/misfit_structured_interval_parser.dart';

void main() {
  const parser = MisfitStructuredIntervalParser();

  test('parses Echo watts, RPM, and calories', () {
    const text =
        'Avg Watts/Avg RPM/Cals\n'
        'Rd1 - 691/87/18, '
        'Rd2 - 683/87/20, '
        'Rd3 - 934/96/20, '
        'Rd4 - 871/94/19';

    expect(parser.extract(text), [
      {'watts': '691', 'rpm': '87', 'calories': '18'},
      {'watts': '683', 'rpm': '87', 'calories': '20'},
      {'watts': '934', 'rpm': '96', 'calories': '20'},
      {'watts': '871', 'rpm': '94', 'calories': '19'},
    ]);
  });

  test('parses BikeErg data and repairs missing pace colons', () {
    const text =
        'Rd1-8 '
        '1019/1:57.7/86, '
        '1095/1:49.5/94, '
        '1120/1:47.1/90, '
        '1129/1:46.2/91, '
        '1105/1:48.5/95, '
        '1122/1:46.9/96, '
        '1129/146.2/97, '
        '1145/144.8/98 '
        '| Average 1108/1:49/93';

    final intervals = parser.extract(text);

    expect(intervals.length, 8);
    expect(intervals.first, {
      'watts': '1019',
      'primaryMetric': '1:57.7',
      'rpm': '86',
    });
    expect(intervals[6], {
      'watts': '1129',
      'primaryMetric': '1:46.2',
      'rpm': '97',
    });
    expect(intervals[7], {
      'watts': '1145',
      'primaryMetric': '1:44.8',
      'rpm': '98',
    });
  });

  test('does not mistake pace sequences for BikeErg data', () {
    const text =
        'Definitely burned. Lowered the damper after Rd 1.\n'
        'Averaged out to 1:50/km\n'
        'Per Rd - 1:50.4/1:50.0/1:50.8/1:50.4';

    expect(parser.extract(text), isEmpty);
  });

  test('parses calorie-only sequences', () {
    const text =
        '18/19/19 @ 7/8/6 damper - '
        '8 was the highest output, but the hardest.';

    expect(parser.extract(text), [
      {'calories': '18'},
      {'calories': '19'},
      {'calories': '19'},
    ]);
  });

  test('parses calories per hour and calories', () {
    const text =
        'Avg Cals/hr/cals in time\n'
        '2970/20, 2732/18, 2897/20, 2802/19';

    expect(parser.extract(text), [
      {'caloriesPerHour': '2970', 'calories': '20'},
      {'caloriesPerHour': '2732', 'calories': '18'},
      {'caloriesPerHour': '2897', 'calories': '20'},
      {'caloriesPerHour': '2802', 'calories': '19'},
    ]);
  });

  test('parses labeled Echo calories and RPM rounds', () {
    const text =
        'Rd1 - Cals 79, Avg RPM 66\n'
        'Rd2 - Cals 83, Avg RPM 68\n'
        'Rd3 - Cals 84, Avg RPM 68\n'
        'Rd4 - Cals 84, Avg RPM 68\n'
        'Rd5 - Cals 85, Avg RPM 68';

    expect(parser.extract(text), [
      {'calories': '79', 'rpm': '66'},
      {'calories': '83', 'rpm': '68'},
      {'calories': '84', 'rpm': '68'},
      {'calories': '84', 'rpm': '68'},
      {'calories': '85', 'rpm': '68'},
    ]);
  });

  test('parses calories, RPM, and watts tables', () {
    const text =
        'Avg per round - Cals/RPM/Watts\n'
        '1 - 72/70/370\n'
        '2 - 80/72/403\n'
        '3 - 81/72/403\n'
        '4 - 83/73/420\n'
        'Total cals - 316';

    expect(parser.extract(text), [
      {'calories': '72', 'rpm': '70', 'watts': '370'},
      {'calories': '80', 'rpm': '72', 'watts': '403'},
      {'calories': '81', 'rpm': '72', 'watts': '403'},
      {'calories': '83', 'rpm': '73', 'watts': '420'},
    ]);
  });
}
