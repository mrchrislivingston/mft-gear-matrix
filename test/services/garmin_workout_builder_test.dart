import 'package:flutter_test/flutter_test.dart';
import 'package:mft_gear_matrix/services/fitr_workout_classifier.dart';
import 'package:mft_gear_matrix/services/garmin_workout_builder.dart';

FitrWorkoutCandidate candidate({
  required String type,
  required String prescription,
  required String modality,
  Map<String, dynamic> values = const {},
}) {
  return FitrWorkoutCandidate(
    id: 'schedule:0:$type',
    date: '2026-09-10',
    planTitle: 'Test Plan',
    sourceTitle: 'Conditioning',
    classification: {
      'status': 'CANDIDATE',
      'type': type,
      'prescription': prescription,
      'modality': modality,
      'source_title': 'Conditioning',
      'workout_date': '2026-09-10',
      ...values,
    },
  );
}

List<Map<String, dynamic>> workoutSteps(Map<String, dynamic> payload) {
  final segments = payload['workoutSegments']! as List;
  final segment = segments.single as Map<String, dynamic>;

  return (segment['workoutSteps']! as List).cast<Map<String, dynamic>>();
}

void main() {
  const builder = GarminWorkoutBuilder();

  test('builds age-based Zone 2 targets for a 28-year-old athlete', () {
    final workout = builder.buildCandidate(
      candidate(
        type: 'Z2',
        prescription: 'Z2',
        modality: 'C2 Bike',
        values: {'work_seconds': 1800},
      ),
      age: 28,
    );

    expect(workout['workoutName'], 'Z2 C2 Bike - 2026-09-10');
    expect(workout['sportType'], {'sportTypeId': 2, 'sportTypeKey': 'cycling'});

    final steps = workoutSteps(workout);

    expect(steps, hasLength(7));
    expect(
      steps
          .map((step) => [step['targetValueOne'], step['targetValueTwo']])
          .toList(),
      [
        [100, 132],
        [132, 137],
        [137, 142],
        [142, 152],
        [137, 142],
        [132, 137],
        [100, 132],
      ],
    );
    expect(steps[3]['endConditionValue'], 1800);
  });

  test('builds the established Zone 2 targets for age 50', () {
    final steps = builder.buildZone2Steps(
      candidate(
        type: 'Z2',
        prescription: 'Z2',
        modality: 'Row',
        values: {'work_seconds': 2400},
      ),
      age: 50,
    );

    expect(
      steps
          .map((step) => [step['targetValueOne'], step['targetValueTwo']])
          .toList(),
      [
        [100, 110],
        [110, 115],
        [115, 120],
        [120, 130],
        [115, 120],
        [110, 115],
        [100, 110],
      ],
    );
  });

  test('enforces structured pace targets for Run Gear intervals', () {
    final workout = builder.buildCandidate(
      candidate(
        type: 'GEAR',
        prescription: 'G3',
        modality: 'Run',
        values: {'rounds': 3, 'work_seconds': 480, 'rest_seconds': 90},
      ),
      age: 50,
      gearTargetResolver: (_, _) => const GarminGearTarget(
        metric: 'minPerMile',
        low: '8:30',
        high: '8:45',
      ),
    );

    final steps = workoutSteps(workout);

    expect(steps, hasLength(5));
    expect(workout['estimatedDurationInSecs'], 1620);
    expect(steps[0]['description'], 'Target 8:30-8:45 min/mile');
    expect(steps[0]['targetType'], {
      'workoutTargetTypeId': 6,
      'workoutTargetTypeKey': 'pace.zone',
    });
    expect(steps[0]['targetValueOne'], closeTo(1609.344 / 510, 0.0000001));
    expect(steps[0]['targetValueTwo'], closeTo(1609.344 / 525, 0.0000001));
    expect(steps[1]['stepType'], {'stepTypeId': 4});
    expect(steps.last['stepType'], {'stepTypeId': 3});
  });

  test('puts Echo Gear target in description without enforcing it', () {
    final workout = builder.buildCandidate(
      candidate(
        type: 'GEAR',
        prescription: 'G1',
        modality: 'Echo Bike',
        values: {'rounds': 2, 'work_seconds': 900, 'rest_seconds': 60},
      ),
      age: 50,
      gearTargetResolver: (_, _) =>
          const GarminGearTarget(metric: 'rpm', low: '63', high: '63'),
    );

    final firstStep = workoutSteps(workout).first;

    expect(firstStep['description'], 'Target 63 RPM');
    expect(firstStep['targetType'], {
      'workoutTargetTypeId': 1,
      'workoutTargetTypeKey': 'no.target',
    });
    expect(firstStep.containsKey('targetValueOne'), isFalse);
    expect(firstStep.containsKey('targetValueTwo'), isFalse);
  });

  test('uses structured targets only where supported in mixed Gear', () {
    final workout = builder.buildCandidate(
      candidate(
        type: 'MIXED_GEAR',
        prescription: 'G4',
        modality: 'Ski + C2 Bike',
        values: {
          'steps': [
            {'kind': 'work', 'modality': 'Ski', 'seconds': 180},
            {'kind': 'work', 'modality': 'C2 Bike', 'seconds': 180},
            {'kind': 'recovery', 'seconds': 150},
          ],
        },
      ),
      age: 50,
      gearTargetResolver: (_, modality) {
        if (modality == 'Ski') {
          return const GarminGearTarget(
            metric: 'minPer500m',
            low: '1:58',
            high: '1:58',
          );
        }

        if (modality == 'C2 Bike') {
          return const GarminGearTarget(
            metric: 'minPer1000m',
            low: '1:47',
            high: '1:48',
          );
        }

        return null;
      },
    );

    final steps = workoutSteps(workout);

    expect(steps[0]['description'], 'Ski - Target 1:58 min/500m');
    expect(steps[0]['targetType'], {
      'workoutTargetTypeId': 1,
      'workoutTargetTypeKey': 'no.target',
    });

    expect(steps[1]['description'], 'C2 Bike - Target 1:47-1:48 min/1000m');
    expect(steps[1]['targetType'], {
      'workoutTargetTypeId': 5,
      'workoutTargetTypeKey': 'speed.zone',
    });

    expect(steps[2]['description'], 'Recovery');
    expect(workout['estimatedDurationInSecs'], 510);
  });

  test('builds Power work and recovery intervals', () {
    final workout = builder.buildCandidate(
      candidate(
        type: 'POWER',
        prescription: 'P1',
        modality: 'Row',
        values: {'rounds': 4, 'work_seconds': 15, 'recovery_seconds': 105},
      ),
      age: 50,
    );

    final steps = workoutSteps(workout);

    expect(steps, hasLength(7));
    expect(workout['estimatedDurationInSecs'], 375);
    expect(steps.map((step) => step['endConditionValue']).toList(), [
      15,
      105,
      15,
      105,
      15,
      105,
      15,
    ]);
  });

  test('builds the proven M.A.T.T. Row payload', () {
    final workout = builder.buildCandidate(
      candidate(
        type: 'MATT',
        prescription: 'M.A.T.T. Row Test',
        modality: 'Row',
      ),
      age: 50,
    );

    expect(workout['workoutName'], 'M.A.T.T. Row Test');
    expect(workout['estimatedDurationInSecs'], 2400);
    expect(
      workoutSteps(workout).map((step) => step['endConditionValue']).toList(),
      [600.0, 1200.0, 600.0],
    );
  });

  test('rejects unsupported candidate types before any Garmin call', () {
    expect(
      () => builder.buildCandidate(
        candidate(type: 'UNKNOWN', prescription: 'Unknown', modality: 'Row'),
        age: 50,
      ),
      throwsA(
        isA<GarminWorkoutBuilderException>().having(
          (error) => error.message,
          'message',
          contains('Unsupported FITR candidate type'),
        ),
      ),
    );
  });
}
