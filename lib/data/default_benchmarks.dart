import '../models/benchmark.dart';
import '../models/benchmark_score_type.dart';

List<Benchmark> buildDefaultBenchmarks() {
  return const [
    Benchmark(
      id: 'matt_echo_bike',
      name: 'M.A.T.T. Echo Bike Test',
      description: """
AMRAP 40 Minutes

Echo Bike for Average Pace

Score is average Watts

""",
      scoreType: BenchmarkScoreType.averageWatts,
    ),
    Benchmark(
      id: 'cube_steaked',
      name: 'Cube Steaked',
      description: """
Four 4:00 AMRAP sections with 4:00 rest.

Score is total reps completed in the max-rep sections.

""",
      scoreType: BenchmarkScoreType.totalReps,
    ),
    Benchmark(
      id: 'row_mount_doom',
      name: 'Row Mount Doom',
      description: """
Every 2:00 Until Failure

Row 20/13 Calories

Add 1 Calorie Every Round

Score is total accumulated calories, including calories completed
in the failed round.

""",
      scoreType: BenchmarkScoreType.totalCalories,
    ),
    Benchmark(
      id: 'power_output_bike_test',
      name: 'Power Output C2 Bike Test',
      description: """
For Time

50/40 Calorie C2 Bike

""",
      scoreType: BenchmarkScoreType.forTime,
    ),
    Benchmark(
      id: 'power_output_echo_bike_test',
      name: 'Power Output Echo Bike Test',
      description: """
For Time

50/40 Calorie Echo Bike

""",
      scoreType: BenchmarkScoreType.forTime,
    ),
    Benchmark(
      id: 'power_output_ski_test',
      name: 'Power Output Ski Test',
      description: """
For Time

50/40 Calorie Ski

""",
      scoreType: BenchmarkScoreType.forTime,
    ),
    Benchmark(
      id: 'power_output_row_test',
      name: 'Power Output Row Test',
      description: """
For Time

50/40 Calorie Row

""",
      scoreType: BenchmarkScoreType.forTime,
    ),
    Benchmark(
      id: 'matt_row',
      name: 'M.A.T.T. Row Test',
      description: '''
AMRAP 40 Minutes
Row for Average Pace

Score is average Watts
''',
      scoreType: BenchmarkScoreType.averageWatts,
    ),
    Benchmark(
      id: 'echo_bike_cube_test',
      name: 'Echo Bike Cube Test',
      description: '''
For Total Calories

AMRAP 4:00 × 4
Calorie Echo Bike
Rest 4:00
''',
      scoreType: BenchmarkScoreType.totalCalories,
    ),
    Benchmark(
      id: 'cleo',
      name: 'Cleo',
      description: '''
For time

10-20-30-40-30-20-10

Echo Bike Calories
Row Calories
Ski Calories
''',
      scoreType: BenchmarkScoreType.forTime,
    ),
    Benchmark(
      id: 'speed_not_volume',
      name: 'Speed, Not Volume',
      description: '''
AMRAP 14 Minutes

15/13 Calorie Row
45 Double Unders
15 Alternating DB Snatch 50/35lbs
''',
      scoreType: BenchmarkScoreType.roundsReps,
    ),
    Benchmark(
      id: 'rule_8',
      name: 'Rule 8',
      description: '''
For time

10 Box Step Ups 24/20" with 50s
10 Box Jump ATWOs 24"
10 Box Step Overs 24/20" with 50s
10 Burpee Box Jump Overs 30"
10 Box Jump Overs 30"
10 Sandbag Get Overs 125lbs to 40"
10 Burpee Get Overs 40"
''',
      scoreType: BenchmarkScoreType.forTime,
    ),
    Benchmark(
      id: 'bike_mount_doom',
      name: 'Bike Mount Doom',
      description: '''
Every 2:00 Until Failure

C2 Bike 20/13 Calories
Add 1 Calorie Every Round

Score is total accumulated calories, including calories completed
in the failed round.
''',
      scoreType: BenchmarkScoreType.totalCalories,
    ),

    Benchmark(
      id: 'matt_c2_bike',
      name: 'M.A.T.T. C2 Bike Test',
      description: """
AMRAP 40 Minutes

C2 Bike for Average Pace

Score is average Watts

""",
      scoreType: BenchmarkScoreType.averageWatts,
    ),
    Benchmark(
      id: 'matt_ski',
      name: 'M.A.T.T. Ski Test',
      description: '',
      scoreType: BenchmarkScoreType.unconfigured,
    ),
    Benchmark(
      id: 'ski_cube_test',
      name: 'Ski Cube Test',
      description: '',
      scoreType: BenchmarkScoreType.unconfigured,
    ),
    Benchmark(
      id: 'c2_bike_cube_test',
      name: 'C2 Bike Cube Test',
      description: '',
      scoreType: BenchmarkScoreType.unconfigured,
    ),
    Benchmark(
      id: 'row_cube_test',
      name: 'Row Cube Test',
      description: """
For Total Calories

AMRAP 4:00 × 4

Calorie Row

Rest 4:00

""",
      scoreType: BenchmarkScoreType.totalCalories,
    ),
    Benchmark(
      id: 'run_cube_test',
      name: 'Run Cube Test',
      description: '',
      scoreType: BenchmarkScoreType.unconfigured,
    ),
    Benchmark(
      id: 'runner_mount_doom',
      name: 'Runner Mount Doom',
      description: '',
      scoreType: BenchmarkScoreType.unconfigured,
    ),
    Benchmark(
      id: 'ski_mount_doom',
      name: 'Ski Mount Doom',
      description: '',
      scoreType: BenchmarkScoreType.unconfigured,
    ),
    Benchmark(
      id: 'echo_bike_mount_doom',
      name: 'Echo Bike Mount Doom',
      description: '',
      scoreType: BenchmarkScoreType.unconfigured,
    ),
    Benchmark(
      id: 'kill_o_meter',
      name: 'Kill-O-Meter',
      description: '',
      scoreType: BenchmarkScoreType.unconfigured,
    ),
    Benchmark(
      id: 'kill_o_watt',
      name: 'Kill-O-Watt',
      description: '',
      scoreType: BenchmarkScoreType.unconfigured,
    ),
    Benchmark(
      id: 'spiders_on_mars',
      name: 'Spiders on Mars',
      description: """
AMRAP 25 Minutes

50 Burpee Box Jump Overs
75/65 Calorie Row
100 Wallballs
75/65 Calorie Row
200 Double Unders
Max Calorie Row in Remaining Time

Score is calories completed on the final row.

""",
      scoreType: BenchmarkScoreType.totalCalories,
    ),
    Benchmark(
      id: 'tour_de_misfit',
      name: 'Tour de Misfit',
      description: '',
      scoreType: BenchmarkScoreType.unconfigured,
    ),
    Benchmark(
      id: 'riverside_time_trial',
      name: 'Riverside Time Trial',
      description: '',
      scoreType: BenchmarkScoreType.unconfigured,
    ),
    Benchmark(
      id: 'enzo_gorlomi',
      name: 'Enzo Gorlomi',
      description: '',
      scoreType: BenchmarkScoreType.unconfigured,
    ),
    Benchmark(
      id: 'cupcake_lungs',
      name: 'Cupcake Lungs',
      description: '',
      scoreType: BenchmarkScoreType.unconfigured,
    ),
    Benchmark(
      id: 'might_not',
      name: 'Might Not',
      description: '',
      scoreType: BenchmarkScoreType.unconfigured,
    ),
    Benchmark(
      id: 'bumper_cables',
      name: 'Bumper Cables',
      description: '',
      scoreType: BenchmarkScoreType.unconfigured,
    ),
    Benchmark(
      id: 'pennies',
      name: 'Pennies',
      description: '',
      scoreType: BenchmarkScoreType.unconfigured,
    ),
    Benchmark(
      id: 'continental_drive_75',
      name: '75 Continental Drive',
      description: '',
      scoreType: BenchmarkScoreType.unconfigured,
    ),
    Benchmark(
      id: 'king_larry_i',
      name: 'King Larry I',
      description: '',
      scoreType: BenchmarkScoreType.unconfigured,
    ),
    Benchmark(
      id: 'chuckles_1_2',
      name: 'Chuckles 1 & 2',
      description: '',
      scoreType: BenchmarkScoreType.unconfigured,
    ),
    Benchmark(
      id: 'hurt_and_injured',
      name: 'Hurt and Injured',
      description: '',
      scoreType: BenchmarkScoreType.unconfigured,
    ),
    Benchmark(
      id: 'fairy_dust',
      name: 'Fairy Dust',
      description: '',
      scoreType: BenchmarkScoreType.unconfigured,
    ),
  ];
}
