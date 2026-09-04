import 'package:flutter_test/flutter_test.dart';
import 'package:mft_gear_matrix/data/default_benchmarks.dart';
import 'package:mft_gear_matrix/models/benchmark_score_type.dart';

void main() {
  test('default benchmark catalog contains every known benchmark', () {
    final benchmarks = buildDefaultBenchmarks();
    final ids = benchmarks.map((benchmark) => benchmark.id).toList();

    expect(benchmarks, hasLength(37));
    expect(ids.toSet(), hasLength(ids.length));

    const pendingIds = {
      'matt_ski',
      'ski_cube_test',
      'c2_bike_cube_test',
      'run_cube_test',
      'runner_mount_doom',
      'ski_mount_doom',
      'echo_bike_mount_doom',
      'kill_o_meter',
      'kill_o_watt',
      'tour_de_misfit',
      'riverside_time_trial',
      'enzo_gorlomi',
      'cupcake_lungs',
      'might_not',
      'bumper_cables',
      'pennies',
      'continental_drive_75',
      'king_larry_i',
      'chuckles_1_2',
      'hurt_and_injured',
      'fairy_dust',
    };

    for (final id in pendingIds) {
      final benchmark = benchmarks.singleWhere(
        (candidate) => candidate.id == id,
      );

      expect(benchmark.description, isEmpty);
      expect(benchmark.scoreType, BenchmarkScoreType.unconfigured);
    }
  });

  test('unconfigured score type has an honest display label', () {
    expect(
      BenchmarkScoreType.unconfigured.displayName,
      'Scoring details pending',
    );
  });
}
