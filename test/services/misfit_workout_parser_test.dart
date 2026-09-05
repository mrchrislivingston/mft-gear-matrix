import 'package:flutter_test/flutter_test.dart';
import 'package:mft_gear_matrix/services/misfit_workout_parser.dart';

void main() {
  const parser = MisfitWorkoutParser();

  test('detects Gear prescriptions', () {
    expect(parser.detectGears('Run - 5th Gear'), [5]);
    expect(parser.detectGears('G4 into G5'), [4, 5]);
  });

  test('prefers prescribed power over comparison text', () {
    expect(
      parser.detectPowerPrescriptions(
        'Max Calorie C2 Bike in :20 @ P2\n'
        'Use P3 session from last week for comparison.',
      ),
      [2],
    );

    expect(
      parser.detectPowerPrescriptions(
        'Max Calorie C2 Bike in :15 @ P1\n'
        'Goal is faster than P2.',
      ),
      [1],
    );
  });

  test('detects Zone prescriptions', () {
    expect(parser.detectZonePrescriptions('Zone 2 C2 Bike'), [2]);
  });

  test('detects workout types', () {
    expect(parser.detectWorkoutType('Run - 5th Gear'), MisfitWorkoutType.gear);
    expect(parser.detectWorkoutType('P3 SkiErg'), MisfitWorkoutType.power);
    expect(parser.detectWorkoutType('Zone 2 Run'), MisfitWorkoutType.zone);
    expect(
      parser.detectWorkoutType('Back Squat 5 x 5'),
      MisfitWorkoutType.unknown,
    );
  });

  test('detects modalities without counting Echo as BikeErg', () {
    expect(parser.detectModalities('Run and Row'), ['run', 'row']);
    expect(parser.detectModalities('C2 Bike'), ['bikeErg']);
    expect(parser.detectModalities('Echo Bike'), ['echo']);
  });

  test('uses the actual prescription line for modality', () {
    expect(
      parser.detectModalities(
        'Again, can be swapped into a C2 Bike piece\n\n'
        'Aerobic - Run\n\n'
        'AMRAP 4:00 x 5\n'
        'Run for Meters @ 3rd Gear',
      ),
      ['run'],
    );

    expect(
      parser.detectModalities(
        'Zone 2 - C2 Bike or Run\n\n'
        '15:00 Zone 2 Warm Up\n'
        '55:00 C2 Bike @ Zone 2\n'
        '15:00 Zone 2 Cool Down',
      ),
      ['bikeErg'],
    );
  });

  test('detects result detail', () {
    expect(parser.detectResultDetail(''), MisfitResultDetail.none);
    expect(
      parser.detectResultDetail('Average pace 7:35'),
      MisfitResultDetail.workoutAverage,
    );
    expect(
      parser.detectResultDetail('Round 1: 7:40\nRound 2: 7:35'),
      MisfitResultDetail.intervalResults,
    );
    expect(
      parser.detectResultDetail('Average 7:35\nRound 1: 7:40'),
      MisfitResultDetail.mixed,
    );
  });

  test('classifies a supported workout as ready', () {
    final result = parser.classifyCandidate(
      programmingText: 'Run - 5th Gear',
      resultText: 'Average pace 7:35',
    );

    expect(result.status, MisfitImportStatus.ready);
    expect(result.reason, 'Single supported workout');
  });

  test('defers mixed workouts', () {
    expect(
      parser
          .classifyCandidate(
            programmingText: 'G4 into G5 Run',
            resultText: 'Completed',
          )
          .reason,
      'Mixed-gear workout',
    );

    expect(
      parser
          .classifyCandidate(
            programmingText: 'Zone 2 Run and Row',
            resultText: 'Completed',
          )
          .reason,
      'Mixed-modality workout',
    );

    expect(
      parser
          .classifyCandidate(
            programmingText:
                'Max Calorie Ski in :20 @ P2\n'
                'Max Calorie Ski in :10 @ P3',
            resultText: 'Completed',
          )
          .reason,
      'Multiple power prescriptions',
    );
  });

  test('requires a detectable modality', () {
    final result = parser.classifyCandidate(
      programmingText: 'P2',
      resultText: 'Completed',
    );

    expect(result.status, MisfitImportStatus.review);
    expect(result.reason, 'Modality could not be detected');
  });

  test('skips workouts with no result', () {
    final result = parser.classifyCandidate(
      programmingText: 'Zone 2 C2 Bike',
      resultText: '',
    );

    expect(result.status, MisfitImportStatus.skip);
    expect(result.reason, 'No result recorded');
  });

  test('skips workouts explicitly not performed', () {
    final examples = [
      (programming: 'P2 Echo Bike', result: 'Skipped because sick'),
      (
        programming: 'Aerobic Row - 2nd Gear',
        result: 'Stomach bug took me out today',
      ),
      (
        programming: 'Zone 2 - C2 Bike',
        result:
            'Took care of some yardwork and house hold chores '
            'instead of zone 2 today.',
      ),
      (
        programming: 'Build Echo - 7th Gear',
        result: 'Saw this and said not today Satan.',
      ),
      (
        programming: 'Aerobic Row - 2nd Gear',
        result:
            'Obviously something was bugging me today...'
            'called it a day after sled and pull-ups',
      ),
      (
        programming: 'Zone 2 - Echo Bike',
        result:
            'Will do a Z2 session on the C2 bike '
            'later this evening.',
      ),
    ];

    for (final example in examples) {
      final result = parser.classifyCandidate(
        programmingText: example.programming,
        resultText: example.result,
      );

      expect(result.status, MisfitImportStatus.skip);
      expect(result.reason, 'Result indicates workout was not completed');
    }
  });

  test('marks partial workouts for review', () {
    final result = parser.classifyCandidate(
      programmingText: 'Aerobic Row - 3rd Gear',
      resultText: 'Stopped after 3 of 5 rounds',
    );

    expect(result.status, MisfitImportStatus.review);
    expect(result.reason, 'Result may describe a partial workout');
  });

  test('skips treadmill runs without the required distance', () {
    final skipped = parser.classifyCandidate(
      programmingText:
          'Build Run - 4th Gear\n'
          'AMRAP 6:00 x 3\n'
          'Run for Meters @ 4th Gear',
      resultText:
          'Rd 1 - 10:00 pace\n'
          'Rd 2 - 8:35 pace\n'
          'Rd 3 - 8:00 pace\n'
          'No idea on meters as this was all on a treadmill.',
    );

    expect(skipped.status, MisfitImportStatus.skip);
    expect(skipped.reason, 'Required run distance was not recorded');

    final recorded = parser.classifyCandidate(
      programmingText:
          'Build Run - 4th Gear\n'
          'Run for Meters @ 4th Gear',
      resultText: 'Treadmill displayed 1200 meters.',
    );

    expect(recorded.status, MisfitImportStatus.ready);
  });

  test('ignores repeated active-rest instructions', () {
    const instructions =
        'You may choose which rest day is your full rest and which '
        'is your active rest. The flush is meant to be done on your '
        'full rest day, and the Zone 2 Bike on your active rest day.';

    expect(parser.isRelevantWorkout(instructions), isFalse);
    expect(parser.isRelevantWorkout('Zone 2 C2 Bike'), isTrue);
    expect(
      parser.isRelevantWorkout('Zone 2 - Bike\n45:00-90:00 Row @ Zone 2'),
      isTrue,
    );
  });
}
