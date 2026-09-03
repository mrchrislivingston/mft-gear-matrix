import 'package:flutter_test/flutter_test.dart';
import 'package:mft_gear_matrix/services/misfit_distance_interval_parser.dart';

void main() {
  const parser = MisfitDistanceIntervalParser();

  test('converts labeled kilometer distances to meters', () {
    const text =
        'This was hard, but manageable.\n\n'
        'Distances in Km..Thanks Garmin\n'
        '1.03/1.03/1.03/1.03/1.03/1.04/1.06/1.04';

    expect(parser.extract(text), [
      {'distance': '1030'},
      {'distance': '1030'},
      {'distance': '1030'},
      {'distance': '1030'},
      {'distance': '1030'},
      {'distance': '1040'},
      {'distance': '1060'},
      {'distance': '1040'},
    ]);
  });

  test('parses sequential numbered meter distances', () {
    const text =
        'Probably should have done more than 18 box jump overs.\n\n'
        '1-500, 2-238, 3-532, 4-251, 5-522\n'
        'Total - 2043';

    expect(parser.extract(text), [
      {'distance': '500'},
      {'distance': '238'},
      {'distance': '532'},
      {'distance': '251'},
      {'distance': '522'},
    ]);
  });

  test('rejects nonsequential numbered values', () {
    expect(parser.extract('1-500, 3-532, 4-251'), isEmpty);
  });

  test('ignores unlabeled decimal sequences', () {
    expect(parser.extract('Rounds were 1.03/1.04/1.05'), isEmpty);
  });

  test('returns no distances when no distance block exists', () {
    expect(parser.extract('Average pace was 1:42 per kilometer.'), isEmpty);
    expect(parser.extract(null), isEmpty);
  });
}
