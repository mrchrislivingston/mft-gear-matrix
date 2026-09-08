import '../models/benchmark.dart';
import 'benchmark_descriptions.dart';
import '../models/benchmark_category.dart';
import '../models/benchmark_score_type.dart';

Benchmark _benchmark(
  String id,
  String name,
  BenchmarkScoreType scoreType, {
  String description = '',
}) {
  return Benchmark(
    id: id,
    name: name,
    description: benchmarkDescription(
      id: id,
      name: name,
      fallback: description,
    ),
    scoreType: scoreType,
    category: _categoryFor(id),
  );
}

BenchmarkCategory _categoryFor(String id) {
  return switch (id) {
    'power_output_echo_bike_test' ||
    'power_output_row_test' ||
    'power_output_ski_test' ||
    'power_output_bike_test' => BenchmarkCategory.powerOutput,

    'back_squat_1rm' ||
    'strict_press_1rm' ||
    'deadlift_1rm' ||
    'bench_press_1rm' ||
    'squat_clean_1rm' ||
    'overhead_squat_1rm' ||
    'front_squat_1rm' ||
    'power_snatch_1rm' ||
    'power_clean_1rm' ||
    'squat_snatch_1rm' ||
    'split_jerk_1rm' ||
    'push_jerk_1rm' ||
    'clean_and_jerk_1rm' ||
    'push_press_1rm' => BenchmarkCategory.weightlifting,

    'enzo_gorlomi' ||
    'cupcake_lungs' ||
    'might_not' ||
    'im_the_yaptain_now' ||
    'bumper_cables' ||
    'speed_not_volume' ||
    'pennies' ||
    'continental_drive_75' ||
    'king_larry_i' ||
    'chuckles_1_2' ||
    'hurt_and_injured' ||
    'fairy_dust' ||
    'rule_8' => BenchmarkCategory.namedMetcon,

    'skill_30_wall_walks' ||
    'skill_80_kipping_hspu' ||
    'skill_50_strict_hspu' ||
    'skill_100_toes_to_bar' ||
    'skill_80_chest_to_bar' ||
    'skill_40_bar_muscle_ups' ||
    'skill_30_ring_muscle_ups' ||
    'skill_15_rope_climbs' ||
    'skill_10_legless_rope_climbs' ||
    'skill_100_ghd_sit_ups' => BenchmarkCategory.skillChipper,

    _ => BenchmarkCategory.machineBenchmark,
  };
}

/// Complete benchmark catalog.
///
/// Current skill-chipper definitions come from the 2026 Gears + Benchmarks
/// sheet. M.A.T.T., Mount Doom, and Rule 8 definitions that only appear in
/// the 2025 sheet are retained for historical tracking.
List<Benchmark> buildDefaultBenchmarks() {
  return [
    // Power-output tests.
    _benchmark(
      'power_output_echo_bike_test',
      'Power Output Echo Bike Test',
      BenchmarkScoreType.forTime,
      description: '50/40 calorie Echo Bike for time.',
    ),
    _benchmark(
      'power_output_row_test',
      'Power Output Row Test',
      BenchmarkScoreType.forTime,
      description: '50/40 calorie Row for time.',
    ),
    _benchmark(
      'power_output_ski_test',
      'Power Output Ski Test',
      BenchmarkScoreType.forTime,
      description: '50/40 calorie Ski for time.',
    ),
    _benchmark(
      'power_output_bike_test',
      'Power Output C2 Bike Test',
      BenchmarkScoreType.forTime,
      description: '50/40 calorie C2 Bike for time.',
    ),

    // Current Cube and aerobic machine tests.
    _benchmark(
      'run_cube_test',
      'Run Cube Test',
      BenchmarkScoreType.totalCalories,
    ),
    _benchmark(
      'ski_cube_test',
      'Ski Cube Test',
      BenchmarkScoreType.totalCalories,
    ),
    _benchmark(
      'c2_bike_cube_test',
      'C2 Bike Cube Test',
      BenchmarkScoreType.totalCalories,
    ),
    _benchmark(
      'row_cube_test',
      'Row Cube Test',
      BenchmarkScoreType.totalCalories,
      description:
          'Four 4:00 calorie-row intervals with 4:00 rest. '
          'Score is total calories.',
    ),
    _benchmark(
      'the_cube_test',
      '"The" Cube Test',
      BenchmarkScoreType.unconfigured,
    ),
    _benchmark(
      'echo_bike_cube_test',
      'Echo Bike Cube Test',
      BenchmarkScoreType.totalCalories,
      description:
          'Four 4:00 calorie Echo Bike intervals with 4:00 rest. '
          'Score is total calories.',
    ),
    _benchmark(
      'cube_steaked',
      'Cube Steaked',
      BenchmarkScoreType.totalReps,
      description:
          'Four 4:00 AMRAP sections with 4:00 rest. '
          'Score is total reps in the max-rep sections.',
    ),
    _benchmark(
      'cleo',
      'Cleo',
      BenchmarkScoreType.forTime,
      description:
          '10-20-30-40-30-20-10 calories on the Echo Bike, Row, and Ski.',
    ),
    _benchmark(
      'kill_o_meter',
      'Run "Kill-O-Meter" Test',
      BenchmarkScoreType.slowestIntervalTime,
    ),
    _benchmark(
      'spiders_on_mars',
      'Spiders on Mars',
      BenchmarkScoreType.totalCalories,
      description:
          'Score is calories completed on the final row after the '
          'prescribed chipper.',
    ),
    _benchmark(
      'kill_o_watt_ski',
      'Ski "Kill-O-Watt" Test',
      BenchmarkScoreType.lowestIntervalWatts,
    ),
    _benchmark(
      'kill_o_watt_row',
      'Row "Kill-O-Watt" Test',
      BenchmarkScoreType.lowestIntervalWatts,
    ),
    _benchmark(
      'kill_o_watt_c2_bike',
      'C2 Bike "Kill-O-Watt" Test',
      BenchmarkScoreType.lowestIntervalWatts,
    ),
    // Preserve this ID because the existing Echo attempt uses kill_o_watt.
    _benchmark(
      'kill_o_watt',
      'Echo "Kill-O-Watt" Test',
      BenchmarkScoreType.lowestIntervalWatts,
    ),
    _benchmark(
      'matt_c2_bike',
      'M.A.T.T. C2 Bike Test',
      BenchmarkScoreType.averageWatts,
      description: '40-minute C2 Bike test. Score is average watts.',
    ),
    _benchmark(
      'tour_de_misfit',
      'Tour de Misfit',
      BenchmarkScoreType.unconfigured,
    ),
    _benchmark(
      'riverside_time_trial',
      'Riverside Time Trial',
      BenchmarkScoreType.unconfigured,
    ),

    // Weightlifting 1RM benchmarks.
    _benchmark(
      'back_squat_1rm',
      'Back Squat 1RM',
      BenchmarkScoreType.maxWeight,
    ),
    _benchmark(
      'strict_press_1rm',
      'Strict Press 1RM',
      BenchmarkScoreType.maxWeight,
    ),
    _benchmark('deadlift_1rm', 'Deadlift 1RM', BenchmarkScoreType.maxWeight),
    _benchmark(
      'bench_press_1rm',
      'Bench Press 1RM',
      BenchmarkScoreType.maxWeight,
    ),
    _benchmark(
      'squat_clean_1rm',
      'Squat Clean 1RM',
      BenchmarkScoreType.maxWeight,
    ),
    _benchmark(
      'overhead_squat_1rm',
      'Overhead Squat 1RM',
      BenchmarkScoreType.maxWeight,
    ),
    _benchmark(
      'front_squat_1rm',
      'Front Squat 1RM',
      BenchmarkScoreType.maxWeight,
    ),
    _benchmark(
      'power_snatch_1rm',
      'Power Snatch 1RM',
      BenchmarkScoreType.maxWeight,
    ),
    _benchmark(
      'power_clean_1rm',
      'Power Clean 1RM',
      BenchmarkScoreType.maxWeight,
    ),
    _benchmark(
      'squat_snatch_1rm',
      'Squat Snatch 1RM',
      BenchmarkScoreType.maxWeight,
    ),
    _benchmark(
      'split_jerk_1rm',
      'Split Jerk 1RM',
      BenchmarkScoreType.maxWeight,
    ),
    _benchmark('push_jerk_1rm', 'Push Jerk 1RM', BenchmarkScoreType.maxWeight),
    _benchmark(
      'clean_and_jerk_1rm',
      'Clean and Jerk 1RM',
      BenchmarkScoreType.maxWeight,
    ),
    _benchmark(
      'push_press_1rm',
      'Push Press 1RM',
      BenchmarkScoreType.maxWeight,
    ),

    // Current 2026 metcons.
    _benchmark(
      'enzo_gorlomi',
      'Enzo Gorlomi',
      BenchmarkScoreType.forTime,
      description: '''
For Time

20 Front Rack Walking Lunges 115/80
25 Kipping HSPU
20 Front Rack Walking Lunges 115/80
20 Strict HSPU
20 Front Rack Walking Lunges 115/80
100-foot Handstand Walk
''',
    ),
    _benchmark('cupcake_lungs', 'Cupcake Lungs', BenchmarkScoreType.roundsReps),
    _benchmark('might_not', 'Might Not', BenchmarkScoreType.roundsReps),
    _benchmark(
      'im_the_yaptain_now',
      "I'm the Yaptain Now",
      BenchmarkScoreType.forTime,
    ),
    _benchmark('bumper_cables', 'Bumper Cables', BenchmarkScoreType.forTime),
    _benchmark(
      'speed_not_volume',
      'Speed, Not Volume',
      BenchmarkScoreType.roundsReps,
    ),
    _benchmark('pennies', 'Pennies', BenchmarkScoreType.forTime),
    _benchmark(
      'continental_drive_75',
      '75 Continental Drive',
      BenchmarkScoreType.forTime,
    ),
    _benchmark('king_larry_i', 'King Larry I', BenchmarkScoreType.unconfigured),
    _benchmark('chuckles_1_2', 'Chuckles 1 & 2', BenchmarkScoreType.forTime),
    _benchmark(
      'hurt_and_injured',
      'Hurt and Injured',
      BenchmarkScoreType.roundsReps,
    ),
    _benchmark('fairy_dust', 'Fairy Dust', BenchmarkScoreType.unconfigured),

    // Current 2026 skill chippers.
    _benchmark(
      'skill_30_wall_walks',
      '30 Wall Walks',
      BenchmarkScoreType.forTime,
    ),
    _benchmark(
      'skill_80_kipping_hspu',
      '80 Kipping HSPU',
      BenchmarkScoreType.forTime,
    ),
    _benchmark(
      'skill_50_strict_hspu',
      '50 Strict HSPU',
      BenchmarkScoreType.forTime,
    ),
    _benchmark(
      'skill_100_toes_to_bar',
      '100 Toes to Bar',
      BenchmarkScoreType.forTime,
    ),
    _benchmark(
      'skill_80_chest_to_bar',
      '80 Chest to Bar Pull Ups',
      BenchmarkScoreType.forTime,
    ),
    _benchmark(
      'skill_40_bar_muscle_ups',
      '40 Bar Muscle Ups',
      BenchmarkScoreType.forTime,
    ),
    _benchmark(
      'skill_30_ring_muscle_ups',
      '30 Ring Muscle Ups',
      BenchmarkScoreType.forTime,
    ),
    _benchmark(
      'skill_15_rope_climbs',
      '15 Rope Climbs',
      BenchmarkScoreType.forTime,
    ),
    _benchmark(
      'skill_10_legless_rope_climbs',
      '10 Legless Rope Climbs',
      BenchmarkScoreType.forTime,
    ),
    _benchmark(
      'skill_100_ghd_sit_ups',
      '100 GHD Sit Ups',
      BenchmarkScoreType.unconfigured,
    ),

    // Historical definitions retained from the 2025 sheet.
    _benchmark(
      'matt_echo_bike',
      'M.A.T.T. Echo Bike Test',
      BenchmarkScoreType.averageWatts,
      description: '40-minute Echo Bike test. Score is average watts.',
    ),
    _benchmark(
      'matt_ski',
      'M.A.T.T. Ski Test',
      BenchmarkScoreType.averageWatts,
      description: '40-minute Ski test. Score is average watts.',
    ),
    _benchmark(
      'matt_row',
      'M.A.T.T. Row Test',
      BenchmarkScoreType.averageWatts,
      description: '40-minute Row test. Score is average watts.',
    ),
    _benchmark(
      'runner_mount_doom',
      'Runner Mount Doom',
      BenchmarkScoreType.totalDistance,
    ),
    _benchmark(
      'ski_mount_doom',
      'Ski Mount Doom',
      BenchmarkScoreType.totalCalories,
    ),
    _benchmark(
      'row_mount_doom',
      'Row Mount Doom',
      BenchmarkScoreType.totalCalories,
      description:
          'Every 2:00, beginning at 20/13 calories and adding one calorie '
          'per round. Score includes calories in the failed round.',
    ),
    _benchmark(
      'bike_mount_doom',
      'C2 Bike Mount Doom',
      BenchmarkScoreType.totalCalories,
      description:
          'Every 2:00, beginning at 20/13 calories and adding one calorie '
          'per round. Score includes calories in the failed round.',
    ),
    _benchmark(
      'echo_bike_mount_doom',
      'Echo Bike Mount Doom',
      BenchmarkScoreType.totalCalories,
    ),
    _benchmark('rule_8', 'Rule 8', BenchmarkScoreType.forTime),
  ];
}
