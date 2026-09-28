import 'package:flutter_test/flutter_test.dart';
import 'package:mft_gear_matrix/services/working_max_service.dart';

Map<String, Object?> attempt(String date, String weight) => {
  'benchmark_id': 'bench_press_1rm', 'attempt_date': date, 'score': weight,
};
void main() {
  final asOf = DateTime(2026, 9, 28);
  test('keeps calculated weight and removes duplicate FITR codes', () {
    final calculations = percentageCalculations('5x5 @75% @75%1RM_BACKSQ',
      asOf: asOf, attempts: [{'benchmark_id':'back_squat_1rm',
        'attempt_date':'2026-08-07', 'score':'305'}], overrides: []);
    expect(calculations, contains('228.75 lb'));
    expect(readablePrescription('5x5 @75% @75%1RM_BACKSQ', calculations),
      '5x5 @75% → 228.75 lb');
    // Existing saved sessions retain the original exact weight.
    expect(readablePrescription('@75%1RM_BACKSQ',
      'Back Squat: 75% × 305 lb = 228.75 lb'), '@75% → 228.75 lb');
    expect(readablePrescription('@75%1RM_BACKSQ', ''),
      '@75% (set working 1RM)');
  });
  test('uses latest recent max, not historical highest', () {
    final max = resolveWorkingMax(liftId: 'bench_press_1rm', asOf: asOf, overrides: [], attempts: [
      attempt('2025-01-01','250'), attempt('2026-05-01','225'), attempt('2026-08-28','205'),
    ]);
    expect(max!.pounds, 205);
    expect(max.date, DateTime(2026,8,28));
  });
  test('six calendar months is inclusive and future records are excluded', () {
    expect(sixMonthsBefore(DateTime(2026,8,31)), DateTime(2026,2,28));
    expect(resolveWorkingMax(liftId:'bench_press_1rm', asOf: asOf, overrides: [], attempts:[attempt('2026-03-28','205')]), isNotNull);
    expect(resolveWorkingMax(liftId:'bench_press_1rm', asOf: asOf, overrides: [], attempts:[attempt('2026-03-27','205'),attempt('2026-10-01','225')]), isNull);
  });
  test('manual override wins and an automatic reset restores recent selection', () {
    final rows = <Map<String,Object?>>[{'id':1,'lift_id':'bench_press_1rm','pounds':190.0,'effective_date':'2026-09-01'}];
    WorkingMax? resolve() => resolveWorkingMax(liftId:'bench_press_1rm', asOf:asOf, overrides:rows, attempts:[attempt('2026-09-10','205')]);
    expect(resolve()!.pounds,190);
    rows.add({'id':2,'lift_id':'bench_press_1rm','pounds':null,'effective_date':'2026-09-28'});
    expect(resolve()!.pounds,205);
  });
  test('FITR grams use measurement date, and a newer local max takes priority', () {
    final benchmarks=[{'code':'1RM_BPRESS','last_value':{'value':92986,'units':'gram','date':'2026-08-28','created_at':9999999999}}];
    expect(resolveWorkingMax(liftId:'bench_press_1rm', asOf:asOf, overrides:[], attempts:[], fitrBenchmarks:benchmarks)!.pounds,205);
    expect(resolveWorkingMax(liftId:'bench_press_1rm', asOf:asOf, overrides:[], attempts:[attempt('2026-09-20','200')], fitrBenchmarks:benchmarks)!.pounds,200);
    expect(resolveWorkingMax(liftId:'bench_press_1rm', asOf:DateTime(2027,9,1), overrides:[], attempts:[], fitrBenchmarks:benchmarks),isNull);
  });
  test('percentage reference determines lift even when exercise title differs', () {
    final text=percentageCalculations('Clean deadlift @85%1RM_CLEAN - @95%1RM_CLEAN',asOf:asOf,
      attempts:[{'benchmark_id':'squat_clean_1rm','attempt_date':'2026-08-12','score':'225'}],overrides:[]);
    expect(text,contains('85% × 225 lb = 191.25 lb'));
    expect(text,contains('95% × 225 lb = 213.75 lb'));
    expect(percentageCalculations('@75%1RM_BPRESS',asOf:asOf,attempts:[],overrides:[]),contains('set a working 1RM'));
    expect(parseLiftPounds('100 kg'),closeTo(220.462262185,0.0001));
    expect(parseLiftPounds('3 x 205'),isNull);
  });
}
