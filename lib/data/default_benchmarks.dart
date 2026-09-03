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
      name: 'Power Output Bike Test',
      description: """
For Time

50/40 Calorie C2 Bike

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
  ];
}
