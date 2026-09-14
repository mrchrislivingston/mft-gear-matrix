import 'fitr_workout_classifier.dart';

typedef GarminJson = Map<String, dynamic>;
typedef GarminGearTargetResolver =
    GarminGearTarget? Function(String prescription, String modality);

class GarminWorkoutBuilderException implements Exception {
  final String message;

  const GarminWorkoutBuilderException(this.message);

  @override
  String toString() => message;
}

class GarminGearTarget {
  final String metric;
  final String low;
  final String high;

  const GarminGearTarget({
    required this.metric,
    required this.low,
    required this.high,
  });
}

class GarminWorkoutBuilder {
  const GarminWorkoutBuilder();

  GarminJson buildCandidate(
    FitrWorkoutCandidate candidate, {
    required int age,
    GarminGearTargetResolver? gearTargetResolver,
  }) {
    if (age < 1 || age > 119) {
      throw const GarminWorkoutBuilderException(
        'Enter an age between 1 and 119.',
      );
    }

    return switch (candidate.type) {
      'MATT' => buildMattRowWorkout(),
      'Z2' => buildZone2Workout(candidate, age: age),
      'GEAR' => buildGearWorkout(
        candidate,
        gearTarget: gearTargetResolver?.call(
          candidate.prescription,
          candidate.modality,
        ),
      ),
      'MIXED_GEAR' => buildMixedGearWorkout(
        candidate,
        gearTargetResolver: gearTargetResolver,
      ),
      'POWER' => buildPowerWorkout(candidate),
      _ => throw GarminWorkoutBuilderException(
        'Unsupported FITR candidate type: ${candidate.type}',
      ),
    };
  }

  GarminJson timedStep(int order, int stepType, num seconds) {
    return {
      'type': 'ExecutableStepDTO',
      'stepOrder': order,
      'stepType': {'stepTypeId': stepType},
      'endCondition': {'conditionTypeId': 2, 'conditionTypeKey': 'time'},
      'endConditionValue': seconds,
      'targetType': {
        'workoutTargetTypeId': 1,
        'workoutTargetTypeKey': 'no.target',
      },
    };
  }

  GarminJson heartRateStep(
    int order,
    int stepType,
    num seconds, {
    num? low,
    num? high,
  }) {
    final step = timedStep(order, stepType, seconds);

    if (low != null || high != null) {
      step['targetType'] = {
        'workoutTargetTypeId': 4,
        'workoutTargetTypeKey': 'heart.rate.zone',
      };

      if (low != null) {
        step['targetValueOne'] = low;
      }

      if (high != null) {
        step['targetValueTwo'] = high;
      }
    }

    return step;
  }

  GarminJson sportTypeForModality(String modality) {
    final normalized = modality.toLowerCase();

    if (normalized.contains('run')) {
      return {'sportTypeId': 1, 'sportTypeKey': 'running'};
    }

    if (normalized.contains('c2 bike') || normalized == 'bike') {
      return {'sportTypeId': 2, 'sportTypeKey': 'cycling'};
    }

    return {'sportTypeId': 6, 'sportTypeKey': 'cardio_training'};
  }

  GarminJson buildMattRowWorkout() {
    const sportType = {'sportTypeId': 6, 'sportTypeKey': 'fitness_equipment'};

    return {
      'workoutName': 'M.A.T.T. Row Test',
      'estimatedDurationInSecs': 2400,
      'sportType': sportType,
      'workoutSegments': [
        {
          'segmentOrder': 1,
          'sportType': sportType,
          'workoutSteps': [
            timedStep(1, 3, 600.0),
            timedStep(2, 3, 1200.0),
            timedStep(3, 3, 600.0),
          ],
        },
      ],
    };
  }

  List<GarminJson> buildZone2Steps(
    FitrWorkoutCandidate candidate, {
    required int age,
  }) {
    final workSeconds = _requiredInt(candidate.classification, 'work_seconds');

    final hr160 = 160 - age;
    final hr165 = 165 - age;
    final hr170 = 170 - age;
    final hr180 = 180 - age;

    return [
      heartRateStep(1, 1, 300, low: 100, high: hr160),
      heartRateStep(2, 1, 300, low: hr160, high: hr165),
      heartRateStep(3, 1, 300, low: hr165, high: hr170),
      heartRateStep(4, 3, workSeconds, low: hr170, high: hr180),
      heartRateStep(5, 2, 300, low: hr165, high: hr170),
      heartRateStep(6, 2, 300, low: hr160, high: hr165),
      heartRateStep(7, 2, 300, low: 100, high: hr160),
    ];
  }

  GarminJson buildZone2Workout(
    FitrWorkoutCandidate candidate, {
    required int age,
  }) {
    final modality = candidate.modality;
    final normalized = modality.toLowerCase();

    final GarminJson sportType;

    if (normalized.contains('run')) {
      sportType = {'sportTypeId': 1, 'sportTypeKey': 'running'};
    } else if (normalized.contains('bike')) {
      sportType = {'sportTypeId': 2, 'sportTypeKey': 'cycling'};
    } else {
      sportType = {'sportTypeId': 6, 'sportTypeKey': 'cardio_training'};
    }

    return {
      'workoutName': 'Z2 $modality - ${candidate.date}',
      'sportType': sportType,
      'workoutSegments': [
        {
          'segmentOrder': 1,
          'sportType': sportType,
          'workoutSteps': buildZone2Steps(candidate, age: age),
        },
      ],
    };
  }

  double paceToSpeed(String pace, num distanceMeters) {
    final parts = pace.trim().split(':');

    if (parts.length != 2) {
      throw GarminWorkoutBuilderException('Invalid pace: $pace');
    }

    final minutes = int.tryParse(parts[0]);
    final seconds = double.tryParse(parts[1]);

    if (minutes == null || seconds == null) {
      throw GarminWorkoutBuilderException('Invalid pace: $pace');
    }

    final totalSeconds = minutes * 60 + seconds;

    if (totalSeconds <= 0) {
      throw GarminWorkoutBuilderException('Invalid pace: $pace');
    }

    return distanceMeters / totalSeconds;
  }

  double paceToMetersPerSecond(String pace) {
    return paceToSpeed(pace, 1609.344);
  }

  GarminJson applyRunPaceTarget(
    GarminJson step,
    String lowPace,
    String highPace,
  ) {
    final speeds = [
      paceToMetersPerSecond(lowPace),
      paceToMetersPerSecond(highPace),
    ];

    step['targetType'] = {
      'workoutTargetTypeId': 6,
      'workoutTargetTypeKey': 'pace.zone',
    };
    step['targetValueOne'] = speeds.reduce((a, b) => a > b ? a : b);
    step['targetValueTwo'] = speeds.reduce((a, b) => a < b ? a : b);

    return step;
  }

  String formatGearTarget(GarminGearTarget target) {
    const units = {
      'minPerMile': 'min/mile',
      'minPer500m': 'min/500m',
      'minPer1000m': 'min/1000m',
      'rpm': 'RPM',
    };

    final unit = units[target.metric];

    if (unit == null) {
      throw GarminWorkoutBuilderException(
        'Unsupported Gear target metric: ${target.metric}',
      );
    }

    final value = target.low == target.high
        ? target.low
        : '${target.low}-${target.high}';

    return 'Target $value $unit';
  }

  bool modalityUsesStructuredTarget(String modality) {
    final normalized = modality.toLowerCase();

    return (normalized.contains('run') ||
            normalized.contains('row') ||
            normalized.contains('bike')) &&
        !normalized.contains('echo');
  }

  GarminJson applyGearTarget(
    GarminJson step,
    GarminGearTarget target, {
    bool enforce = true,
  }) {
    step['description'] = formatGearTarget(target);

    if (!enforce) {
      return step;
    }

    if (target.metric == 'minPerMile') {
      return applyRunPaceTarget(step, target.low, target.high);
    }

    if (target.metric == 'minPer500m' || target.metric == 'minPer1000m') {
      final distance = target.metric == 'minPer500m' ? 500 : 1000;
      final speeds = [
        paceToSpeed(target.low, distance),
        paceToSpeed(target.high, distance),
      ];

      step['targetType'] = {
        'workoutTargetTypeId': 5,
        'workoutTargetTypeKey': 'speed.zone',
      };
      step['targetValueOne'] = speeds.reduce((a, b) => a < b ? a : b);
      step['targetValueTwo'] = speeds.reduce((a, b) => a > b ? a : b);

      return step;
    }

    throw GarminWorkoutBuilderException(
      'Structured target is not supported for metric: ${target.metric}',
    );
  }

  List<GarminJson> buildGearSteps(
    FitrWorkoutCandidate candidate, {
    GarminGearTarget? gearTarget,
  }) {
    final classification = candidate.classification;
    final rounds = _requiredInt(classification, 'rounds');
    final workSeconds = _requiredInt(classification, 'work_seconds');
    final restSeconds = _requiredInt(classification, 'rest_seconds');
    final paceLow = classification['pace_low']?.toString();
    final paceHigh = classification['pace_high']?.toString();
    final hasInlineRunPace =
        candidate.modality.toLowerCase() == 'run' &&
        paceLow != null &&
        paceLow.isNotEmpty &&
        paceHigh != null &&
        paceHigh.isNotEmpty;

    if (gearTarget == null && !hasInlineRunPace) {
      throw GarminWorkoutBuilderException(
        '${candidate.prescription} ${candidate.modality} requires a current '
        'athlete target. Restore or enter the target before building Garmin '
        'workouts.',
      );
    }

    final steps = <GarminJson>[];
    var order = 1;

    for (var round = 0; round < rounds; round++) {
      final workStep = timedStep(order, 3, workSeconds);

      if (gearTarget != null) {
        applyGearTarget(
          workStep,
          gearTarget,
          enforce: modalityUsesStructuredTarget(candidate.modality),
        );
      } else if (hasInlineRunPace) {
        applyRunPaceTarget(workStep, paceLow, paceHigh);
      }

      steps.add(workStep);
      order++;

      if (round < rounds - 1) {
        steps.add(timedStep(order, 4, restSeconds));
        order++;
      }
    }

    return steps;
  }

  GarminJson buildGearWorkout(
    FitrWorkoutCandidate candidate, {
    GarminGearTarget? gearTarget,
  }) {
    final steps = buildGearSteps(candidate, gearTarget: gearTarget);
    final sportType = sportTypeForModality(candidate.modality);

    return {
      'workoutName':
          '${candidate.prescription} ${candidate.modality} - ${candidate.date}',
      'sportType': sportType,
      'estimatedDurationInSecs': _totalDuration(steps),
      'workoutSegments': [
        {'segmentOrder': 1, 'sportType': sportType, 'workoutSteps': steps},
      ],
    };
  }

  GarminJson buildMixedGearWorkout(
    FitrWorkoutCandidate candidate, {
    GarminGearTargetResolver? gearTargetResolver,
  }) {
    final rawSteps = candidate.classification['steps'];

    if (rawSteps is! List) {
      throw const GarminWorkoutBuilderException(
        'Mixed Gear candidate is missing steps.',
      );
    }

    final workoutSteps = <GarminJson>[];

    for (var index = 0; index < rawSteps.length; index++) {
      final rawStep = rawSteps[index];

      if (rawStep is! Map) {
        throw const GarminWorkoutBuilderException(
          'Mixed Gear candidate contains an invalid step.',
        );
      }

      final candidateStep = Map<String, dynamic>.from(rawStep);
      final isWork = candidateStep['kind'] == 'work';
      final seconds = _requiredInt(candidateStep, 'seconds');
      final modality =
          candidateStep['modality']?.toString().trim().isNotEmpty == true
          ? candidateStep['modality'].toString()
          : 'Recovery';
      final rawPrescription = candidateStep['prescription']?.toString().trim();
      final hasStepPrescription =
          rawPrescription != null && rawPrescription.isNotEmpty;
      final prescription = hasStepPrescription
          ? rawPrescription
          : candidate.prescription;

      final step = timedStep(index + 1, isWork ? 3 : 4, seconds);

      final target = isWork
          ? gearTargetResolver?.call(prescription, modality)
          : null;

      if (isWork && target == null) {
        throw GarminWorkoutBuilderException(
          '$prescription $modality requires a current athlete '
          'target. Restore or enter the target before building Garmin '
          'workouts.',
        );
      }

      if (target != null) {
        applyGearTarget(
          step,
          target,
          enforce: modalityUsesStructuredTarget(modality),
        );
        final label = hasStepPrescription
            ? '$prescription $modality'
            : modality;
        step['description'] = '$label - ${formatGearTarget(target)}';
      } else {
        step['description'] = modality;
      }

      workoutSteps.add(step);
    }

    final GarminJson sportType = candidate.modality.contains('+')
        ? {'sportTypeId': 6, 'sportTypeKey': 'cardio_training'}
        : sportTypeForModality(candidate.modality);

    return {
      'workoutName':
          '${candidate.prescription} ${candidate.modality} - ${candidate.date}',
      'sportType': sportType,
      'estimatedDurationInSecs': _totalDuration(workoutSteps),
      'workoutSegments': [
        {
          'segmentOrder': 1,
          'sportType': sportType,
          'workoutSteps': workoutSteps,
        },
      ],
    };
  }

  List<GarminJson> buildPowerSteps(FitrWorkoutCandidate candidate) {
    final classification = candidate.classification;
    final rounds = _requiredInt(classification, 'rounds');
    final workSeconds = _requiredInt(classification, 'work_seconds');
    final recoverySeconds = _requiredInt(classification, 'recovery_seconds');

    final steps = <GarminJson>[];
    var order = 1;

    for (var round = 0; round < rounds; round++) {
      steps.add(timedStep(order, 3, workSeconds));
      order++;

      if (round < rounds - 1 && recoverySeconds > 0) {
        steps.add(timedStep(order, 4, recoverySeconds));
        order++;
      }
    }

    return steps;
  }

  GarminJson buildPowerWorkout(FitrWorkoutCandidate candidate) {
    final steps = buildPowerSteps(candidate);
    final sportType = sportTypeForModality(candidate.modality);

    return {
      'workoutName':
          '${candidate.prescription} ${candidate.modality} - ${candidate.date}',
      'sportType': sportType,
      'estimatedDurationInSecs': _totalDuration(steps),
      'workoutSegments': [
        {'segmentOrder': 1, 'sportType': sportType, 'workoutSteps': steps},
      ],
    };
  }

  int _requiredInt(Map<dynamic, dynamic> values, String key) {
    final value = values[key];

    if (value is int) {
      return value;
    }

    if (value is num) {
      return value.toInt();
    }

    final parsed = int.tryParse(value?.toString() ?? '');

    if (parsed == null) {
      throw GarminWorkoutBuilderException(
        'Candidate is missing a valid $key value.',
      );
    }

    return parsed;
  }

  num _totalDuration(List<GarminJson> steps) {
    return steps.fold<num>(
      0,
      (total, step) => total + (step['endConditionValue'] as num),
    );
  }
}
