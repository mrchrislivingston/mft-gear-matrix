import 'metric.dart';
import 'workout_metric.dart';

enum Modality {
  run,
  row,
  ski,
  bikeErg,
  echo;

  String get displayName {
    switch (this) {
      case Modality.run:
        return 'Run';
      case Modality.row:
        return 'Row';
      case Modality.ski:
        return 'SkiErg';
      case Modality.bikeErg:
        return 'C2 Bike';
      case Modality.echo:
        return 'Echo Bike';
    }
  }

  Metric get defaultMetric {
    switch (this) {
      case Modality.run:
        return Metric.minPerMile;
      case Modality.row:
        return Metric.minPer500m;
      case Modality.ski:
        return Metric.minPer500m;
      case Modality.bikeErg:
        return Metric.minPer1000m;
      case Modality.echo:
        return Metric.rpm;
    }
  }

  List<WorkoutMetric> get workoutMetrics {
    switch (this) {
      case Modality.run:
        return const [
          WorkoutMetric.distance,
          WorkoutMetric.primaryMetric,
          WorkoutMetric.heartRate,
          WorkoutMetric.rpe,
        ];

      case Modality.row:
        return const [
          WorkoutMetric.distance,
          WorkoutMetric.primaryMetric,
          WorkoutMetric.watts,
          WorkoutMetric.calories,
          WorkoutMetric.caloriesPerHour,
          WorkoutMetric.strokeRate,
          WorkoutMetric.heartRate,
          WorkoutMetric.rpe,
        ];

      case Modality.ski:
        return const [
          WorkoutMetric.distance,
          WorkoutMetric.primaryMetric,
          WorkoutMetric.watts,
          WorkoutMetric.calories,
          WorkoutMetric.caloriesPerHour,
          WorkoutMetric.strokeRate,
          WorkoutMetric.heartRate,
          WorkoutMetric.rpe,
        ];

      case Modality.bikeErg:
        return const [
          WorkoutMetric.distance,
          WorkoutMetric.primaryMetric,
          WorkoutMetric.watts,
          WorkoutMetric.calories,
          WorkoutMetric.caloriesPerHour,
          WorkoutMetric.rpm,
          WorkoutMetric.heartRate,
          WorkoutMetric.rpe,
        ];

      case Modality.echo:
        return const [
          WorkoutMetric.primaryMetric,
          WorkoutMetric.calories,
          WorkoutMetric.watts,
          WorkoutMetric.heartRate,
          WorkoutMetric.rpe,
        ];
    }
  }
}