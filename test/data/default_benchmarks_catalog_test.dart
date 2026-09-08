import 'package:flutter_test/flutter_test.dart';
import 'package:mft_gear_matrix/data/default_benchmarks.dart';
import 'package:mft_gear_matrix/models/benchmark_category.dart';
import 'package:mft_gear_matrix/models/benchmark_score_type.dart';

void main() {
  test('catalog contains the complete merged benchmark set', () {
    final benchmarks = buildDefaultBenchmarks();
    final ids = benchmarks.map((benchmark) => benchmark.id).toList();

    expect(benchmarks, hasLength(66));
    expect(ids.toSet(), hasLength(ids.length));

    const required2026Ids = {
      'the_cube_test',
      'kill_o_watt_ski',
      'kill_o_watt_row',
      'kill_o_watt_c2_bike',
      'im_the_yaptain_now',
      'back_squat_1rm',
      'clean_and_jerk_1rm',
      'skill_30_wall_walks',
      'skill_100_ghd_sit_ups',
    };

    const retained2025Ids = {
      'matt_echo_bike',
      'matt_ski',
      'matt_row',
      'runner_mount_doom',
      'ski_mount_doom',
      'row_mount_doom',
      'bike_mount_doom',
      'echo_bike_mount_doom',
      'rule_8',
    };

    expect(ids, containsAll(required2026Ids));
    expect(ids, containsAll(retained2025Ids));
  });

  test('catalog is divided into explicit benchmark categories', () {
    final benchmarks = buildDefaultBenchmarks();

    int count(BenchmarkCategory category) {
      return benchmarks
          .where((benchmark) => benchmark.category == category)
          .length;
    }

    expect(count(BenchmarkCategory.powerOutput), 4);
    expect(count(BenchmarkCategory.machineBenchmark), 25);
    expect(count(BenchmarkCategory.weightlifting), 14);
    expect(count(BenchmarkCategory.namedMetcon), 13);
    expect(count(BenchmarkCategory.skillChipper), 10);
  });

  test('configured score types match benchmark scoring direction', () {
    final byId = {
      for (final benchmark in buildDefaultBenchmarks()) benchmark.id: benchmark,
    };

    expect(byId['back_squat_1rm']!.scoreType, BenchmarkScoreType.maxWeight);
    expect(
      byId['kill_o_meter']!.scoreType,
      BenchmarkScoreType.slowestIntervalTime,
    );
    expect(
      byId['kill_o_watt']!.scoreType,
      BenchmarkScoreType.lowestIntervalWatts,
    );
    expect(byId['skill_30_wall_walks']!.scoreType, BenchmarkScoreType.forTime);
  });

  test('every benchmark has an honest description', () {
    final benchmarks = buildDefaultBenchmarks();

    expect(
      benchmarks.every((benchmark) => benchmark.description.trim().isNotEmpty),
      isTrue,
    );

    final byId = {for (final benchmark in benchmarks) benchmark.id: benchmark};

    expect(
      byId['enzo_gorlomi']!.description,
      contains('Front Rack Walking Lunges'),
    );
    expect(
      byId['fairy_dust']!.description,
      contains('2.4-kilometer Echo Bike'),
    );
    expect(byId['the_cube_test']!.description, contains('not yet located'));
  });

  test('100 GHD Sit Ups does not invent a for-time score', () {
    final benchmark = buildDefaultBenchmarks().singleWhere(
      (candidate) => candidate.id == 'skill_100_ghd_sit_ups',
    );

    expect(benchmark.scoreType, BenchmarkScoreType.unconfigured);
    expect(benchmark.description, contains('not for time'));
  });

  test('unconfigured score type has an honest display label', () {
    expect(
      BenchmarkScoreType.unconfigured.displayName,
      'Scoring details pending',
    );
  });
}
