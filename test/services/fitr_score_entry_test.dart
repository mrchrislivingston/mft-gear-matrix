import 'package:flutter_test/flutter_test.dart';
import 'package:mft_gear_matrix/services/fitr_score_entry.dart';
void main() {
  test('FITR calorie and rep sub-values retain each round and aggregate', () {
    const spec=FitrScoreSpec({'measure':'calories','count_sub_value':5,'custom_type':'sum_all','direction':'ascending'});
    expect(spec.count,5);
    expect(spec.summarize(['60','61','62','63','64']),contains('Sum of entries: 310 calories'));
    expect(spec.summarize(['60','','','','']),contains('1/5 entries'));
  });
  test('best score respects direction and time retains seconds', () {
    const spec=FitrScoreSpec({'measure':'time','count_sub_value':3,'custom_type':'best','direction':'descending'});
    expect(spec.validate('1:75'),isNotNull);
    expect(spec.validate('1:35'),isNull);
    expect(spec.summarize(['1:35','1:25','1:40']),contains('Best entry: 1:25.00'));
  });
  test('rounds/reps and unknown formats are handled explicitly', () {
    const spec=FitrScoreSpec({'measure':'round_reps'});
    expect(spec.count,1);
    expect(spec.validate('5 + 12'),isNull);
    expect(spec.validate('5.12'),isNotNull);
    expect(const FitrScoreSpec({'measure':'unknown'}).supported,isFalse);
    expect(const FitrScoreSpec({'measure':'reps'}).validate('NaN'),isNotNull);
    expect(const FitrScoreSpec({'measure':'reps'}).validate('1.5'),isNotNull);
  });
}
