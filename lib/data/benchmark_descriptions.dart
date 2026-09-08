const _sourceDescriptions = <String, String>{
  'run_cube_test': '''
For Total Calories

AMRAP 4:00 × 4
Run for Calories
Rest 4:00

This follows the Cube-family structure. Score is total calories.
''',
  'ski_cube_test': '''
For Total Calories

AMRAP 4:00 × 4
Calorie Ski
Rest 4:00

This follows the Cube-family structure. Score is total calories.
''',
  'c2_bike_cube_test': '''
For Total Calories

AMRAP 4:00 × 4
Calorie C2 Bike
Rest 4:00

Score is total calories.
''',
  'row_cube_test': '''
For Total Calories

AMRAP 4:00 × 4
Calorie Row
Rest 4:00

Score is total calories.
''',
  'echo_bike_cube_test': '''
For Total Calories

AMRAP 4:00 × 4
Calorie Echo Bike
Rest 4:00

Score is total calories.
''',
  'cube_steaked': '''
AMRAP 4:00
20/16 Calorie Row
16 Bar-Facing Burpees
24 Wallballs 20/14 lb to 10 feet
Max Double Unders in remaining time
Rest 4:00

AMRAP 4:00
72 Double Unders
20/16 Calorie Row
16 Bar-Facing Burpees
Max Wallballs in remaining time
Rest 4:00

AMRAP 4:00
24 Wallballs
72 Double Unders
20/16 Calorie Row
Max Bar-Facing Burpees in remaining time
Rest 4:00

AMRAP 4:00
16 Bar-Facing Burpees
24 Wallballs
72 Double Unders
Max Calorie Row in remaining time

Score is total reps from the four max-rep sections.
''',
  'cleo': '''
For Time

10-20-30-40-30-20-10
Echo Bike Calories
Row Calories
Ski Calories
''',
  'kill_o_meter': '''
Every 5:00 × 6

Run 800 meters

Score is the slowest interval.
''',
  'spiders_on_mars': '''
AMRAP 25:00

50 Burpee Box Jump Overs 24/20 inches
75/65 Calorie Row
100 Wallballs 20/14 lb to 10/9 feet
75/65 Calorie Row
200 Double Unders
Max Calorie Row in remaining time

Score is calories completed on the final row.
''',
  'kill_o_watt_ski': '''
Six Ski intervals scored by watts.

Score is the lowest interval watts. The exact interval and recovery
prescription has not yet been located in the historical worksheets.
''',
  'kill_o_watt_row': '''
Six Row intervals scored by watts.

Score is the lowest interval watts. The exact interval and recovery
prescription has not yet been located in the historical worksheets.
''',
  'kill_o_watt_c2_bike': '''
Six C2 Bike intervals scored by watts.

Score is the lowest interval watts. The exact interval and recovery
prescription has not yet been located in the historical worksheets.
''',
  'kill_o_watt': '''
Six Echo Bike intervals scored by watts.

Score is the lowest interval watts. The exact interval and recovery
prescription has not yet been located in the historical worksheets.
''',
  'matt_c2_bike': '''
AMRAP 40:00

C2 Bike for average pace

Score is average watts. Pace intelligently; the effort should become
progressively harder to maintain.
''',
  'matt_echo_bike': '''
AMRAP 40:00

Echo Bike for average pace

Score is average watts.
''',
  'matt_ski': '''
AMRAP 40:00

Ski for average pace

Score is average watts. This follows the M.A.T.T. test family.
''',
  'matt_row': '''
AMRAP 40:00

Row for average pace

Score is average watts.

First 10:00: establish a sustainable rhythm.
Middle 20:00: maintain breathing, stroke length, and split.
Final 10:00: increase effort if pacing allows.
''',
  'ski_mount_doom': '''
Every 2:00 Until Failure

Ski 20/13 Calories
Add 1 calorie every round

Score is total accumulated calories, including calories completed in
the failed round. This follows the Mount Doom test family.
''',
  'row_mount_doom': '''
Every 2:00 Until Failure

Row 20/13 Calories
Add 1 calorie every round

Score is total accumulated calories, including calories completed in
the failed round.
''',
  'bike_mount_doom': '''
Every 2:00 Until Failure

C2 Bike 20/13 Calories
Add 1 calorie every round

Score is total accumulated calories, including calories completed in
the failed round.
''',
  'echo_bike_mount_doom': '''
Every 2:00 Until Failure

Echo Bike 20/13 Calories
Add 1 calorie every round

Score is total accumulated calories, including calories completed in
the failed round. This follows the Mount Doom test family.
''',
  'enzo_gorlomi': '''
For Time

20 Front Rack Walking Lunges 115/80 lb
25 Kipping HSPU
20 Front Rack Walking Lunges 115/80 lb
20 Strict HSPU
20 Front Rack Walking Lunges 115/80 lb
100-foot Handstand Walk
''',
  'cupcake_lungs': '''
AMRAP 8:00

8 Bar-Facing Burpees
8 Power Snatches 95/65 lb
''',
  'might_not': '''
AMRAP 9:00

10 Overhead Squats 75/55 lb
8 Chest-to-Bar Pull Ups
10 Box Jump Overs
''',
  'im_the_yaptain_now': '''
For Time

6 Sandbag to Shoulder
50-foot Sandbag Carry
12 Wall Walks
100-foot Sandbag Carry
200-foot Farmers Carry 60/40 lb
100-foot Sandbag Carry
24 Dumbbell Bench Press 60/40 lb
50-foot Sandbag Carry
6 Sandbag to Shoulder
''',
  'bumper_cables': '''
4 Rounds for Time

500/400-meter Ski
20 GHD Sit Ups
7 Bar Muscle Ups
''',
  'speed_not_volume': '''
AMRAP 14:00

15/13 Calorie Row
45 Double Unders
15 Alternating Dumbbell Snatches 50/35 lb
''',
  'pennies': '''
For Time

4 Rounds:
6 Squat Cleans
6 Muscle Ups
400-meter Run
''',
  'continental_drive_75': '''
For Time

200 Double Unders
60-foot Handstand Walk
20 Devils Press 50/35 lb
60-foot Handstand Walk
30 Alternating Goblet Pistols 35/20 lb
60-foot Handstand Walk
20 Clean and Jerks 115/80 lb
60-foot Back-Rack Walking Lunge 115/80 lb

Handstand walks and lunges are 30 feet out and 30 feet back and must
be completed in unbroken sections of at least 15 feet.
''',
  'chuckles_1_2': '''
For Time

4 Rope Climbs
35/30 Calorie Echo Bike
21 Wallballs 30/20 lb to 10/9 feet
3 Rope Climbs
25/20 Calorie Echo Bike
15 Wallballs
2 Rope Climbs
15/10 Calorie Echo Bike
9 Wallballs
3 Rope Climbs
25/20 Calorie Echo Bike
15 Wallballs
4 Rope Climbs
35/30 Calorie Echo Bike
21 Wallballs
''',
  'hurt_and_injured': '''
AMRAP 20:00

10 Toes to Bar
10 Dumbbell Thrusters 50/35 lb
Four 50-foot Shuttle Runs

Increase the shuttle runs by two every round.
''',
  'fairy_dust': '''
For Time

2.4-kilometer Echo Bike
18 Front Squats 165 lb
15 Shuttle Runs
18 Calorie Row
15/12 Muscle Ups
12 Shuttle Runs
15 Calorie Ski
12 Squat Snatches 135 lb
9 Shuttle Runs
900-meter C2 Bike
5/4 Legless Rope Climbs
5 Shuttle Runs
''',
  'rule_8': '''
For Time

10 Box Step Ups 24/20 inches with 50/35 lb dumbbells
10 Around-the-World Box Jumps 24 inches
10 Box Step Overs 24/20 inches with 50/35 lb dumbbells
10 Burpee Box Jump Overs 30 inches
10 Box Jump Overs 30 inches
10 Sandbag Get Overs 125 lb to 40 inches
10 Burpee Get Overs at 40 inches
''',
};

const _skillDescriptions = <String, String>{
  'skill_30_wall_walks': 'For Time\n\n30 Wall Walks',
  'skill_80_kipping_hspu': 'For Time\n\n80 Kipping HSPU',
  'skill_50_strict_hspu': 'For Time\n\n50 Strict HSPU',
  'skill_100_toes_to_bar': 'For Time\n\n100 Toes to Bar',
  'skill_80_chest_to_bar': 'For Time\n\n80 Chest-to-Bar Pull Ups',
  'skill_40_bar_muscle_ups': 'For Time\n\n40 Bar Muscle Ups',
  'skill_30_ring_muscle_ups': 'For Time\n\n30 Ring Muscle Ups',
  'skill_15_rope_climbs': 'For Time\n\n15 Rope Climbs',
  'skill_10_legless_rope_climbs': 'For Time\n\n10 Legless Rope Climbs',
  'skill_100_ghd_sit_ups': '''
100 GHD Sit Ups

The located 2026 programming marked this work as not for time.
Comparison scoring remains pending.
''',
};

const _pendingDescriptions = <String, String>{
  'the_cube_test':
      'Canonical prescription not yet located in the available worksheets.',
  'tour_de_misfit':
      'Canonical prescription not yet located in the available worksheets.',
  'riverside_time_trial':
      'Canonical prescription not yet located in the available worksheets.',
  'runner_mount_doom':
      'Canonical prescription not yet located in the available worksheets.',
  'king_larry_i':
      'Canonical prescription not yet located in the available worksheets.',
};

String benchmarkDescription({
  required String id,
  required String name,
  String fallback = '',
}) {
  final sourceDescription = _sourceDescriptions[id];

  if (sourceDescription != null) {
    return sourceDescription.trim();
  }

  final skillDescription = _skillDescriptions[id];

  if (skillDescription != null) {
    return skillDescription.trim();
  }

  if (id.endsWith('_1rm')) {
    final liftName = name.replaceFirst(RegExp(r'\s+1RM$'), '');

    return '''
Find a 1-rep max $liftName.

Score is the heaviest successful lift in pounds.
'''
        .trim();
  }

  if (fallback.trim().isNotEmpty) {
    return fallback.trim();
  }

  return _pendingDescriptions[id] ??
      'Canonical prescription not yet located in the available worksheets.';
}
