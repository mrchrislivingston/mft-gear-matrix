enum WorkoutMetric {
  distance,
  primaryMetric,
  watts,
  calories,
  caloriesPerHour,
  rpm,
  strokeRate,
  heartRate,
  rpe;

  String get displayName {
    switch (this) {
      case WorkoutMetric.distance:
        return 'Distance';

      case WorkoutMetric.primaryMetric:
        return 'Primary Metric';

      case WorkoutMetric.watts:
        return 'Watts';

      case WorkoutMetric.calories:
        return 'Calories';

      case WorkoutMetric.caloriesPerHour:
        return 'Calories Per Hour';

      case WorkoutMetric.rpm:
        return 'RPM';

      case WorkoutMetric.strokeRate:
        return 'Stroke Rate';

      case WorkoutMetric.heartRate:
        return 'Avg HR';

      case WorkoutMetric.rpe:
        return 'RPE';
    }
  }

  String get storageKey {
    return name;
  }

  bool get usesTimeFormat {
    switch (this) {
      case WorkoutMetric.primaryMetric:
      case WorkoutMetric.distance:
      case WorkoutMetric.watts:
      case WorkoutMetric.calories:
      case WorkoutMetric.caloriesPerHour:
      case WorkoutMetric.rpm:
      case WorkoutMetric.strokeRate:
      case WorkoutMetric.heartRate:
      case WorkoutMetric.rpe:
        return false;
    }
  }
}