import 'dart:math' as math;

import '../models/log_entry.dart';
import '../models/workout_metric.dart';

class WorkoutAnalytics {
  const WorkoutAnalytics._();

  static String executionScore({
    required LogEntry log,
    required bool primaryMetricUsesTimeFormat,
  }) {
    final recordedValues = log.intervals
        .map(
          (interval) =>
              interval.valueFor(WorkoutMetric.primaryMetric),
        )
        .where((value) => value.trim().isNotEmpty)
        .toList();

    final values = primaryMetricUsesTimeFormat
        ? recordedValues
            .map(_paceToSeconds)
            .where((value) => value > 0)
            .map((value) => value.toDouble())
            .toList()
        : recordedValues
            .map(_toDouble)
            .where((value) => value > 0)
            .toList();

    if (values.length < 2) {
      return '--';
    }

    final average =
        values.reduce((a, b) => a + b) / values.length;

    if (average <= 0) {
      return '--';
    }

    final variance = values
            .map(
              (value) => math.pow(value - average, 2),
            )
            .reduce((a, b) => a + b) /
        values.length;

    final standardDeviation = math.sqrt(variance);

    final coefficientOfVariation =
        standardDeviation / average;

    final score = (100 - (coefficientOfVariation * 100))
        .clamp(0, 100)
        .round();

    return '$score%';
  }

  static double _toDouble(String value) {
    return double.tryParse(value.trim()) ?? 0;
  }

  static int _paceToSeconds(String pace) {
    final parts = pace.trim().split(':');

    if (parts.length != 2) {
      return 0;
    }

    final minutes = int.tryParse(parts[0]);
    final seconds = int.tryParse(parts[1]);

    if (minutes == null || seconds == null) {
      return 0;
    }

    if (seconds < 0 || seconds > 59) {
      return 0;
    }

    return (minutes * 60) + seconds;
  }
}