import '../models/log_entry.dart';
import '../models/workout_metric.dart';

class PersonalRecordService {
  const PersonalRecordService._();

  static bool isPersonalRecord({
    required LogEntry log,
    required List<LogEntry> allLogs,
    required bool primaryMetricUsesTimeFormat,
  }) {
    final performance = _performanceValue(
      log,
      primaryMetricUsesTimeFormat,
    );

    if (performance == null) {
      return false;
    }

    final previousLogs = allLogs.where(
      (item) =>
          item.date.isBefore(log.date) &&
          item.modality == log.modality &&
          item.prescriptionId == log.prescriptionId,
    );

    for (final previous in previousLogs) {
      final previousPerformance = _performanceValue(
        previous,
        primaryMetricUsesTimeFormat,
      );

      if (previousPerformance == null) {
        continue;
      }

      if (primaryMetricUsesTimeFormat) {
        // Faster pace = smaller number
        if (previousPerformance <= performance) {
          return false;
        }
      } else {
        // Bigger number wins
        if (previousPerformance >= performance) {
          return false;
        }
      }
    }

    return true;
  }

  static double? _performanceValue(
    LogEntry log,
    bool timeMetric,
  ) {
    final values = log.intervals
        .map(
          (interval) =>
              interval.valueFor(
                WorkoutMetric.primaryMetric,
              ),
        )
        .where((value) => value.trim().isNotEmpty)
        .toList();

    if (values.isEmpty) {
      return null;
    }

    if (timeMetric) {
      final seconds = values
          .map(_paceToSeconds)
          .where((value) => value > 0)
          .toList();

      if (seconds.isEmpty) {
        return null;
      }

      return seconds.reduce((a, b) => a + b) /
          seconds.length;
    }

    final numbers = values
        .map(_toDouble)
        .where((value) => value > 0)
        .toList();

    if (numbers.isEmpty) {
      return null;
    }

    return numbers.reduce((a, b) => a + b) /
        numbers.length;
  }

  static double _toDouble(String value) {
    return double.tryParse(value.trim()) ?? 0;
  }

  static int _paceToSeconds(String pace) {
    final parts = pace.split(':');

    if (parts.length != 2) {
      return 0;
    }

    final minutes = int.tryParse(parts[0]);
    final seconds = int.tryParse(parts[1]);

    if (minutes == null || seconds == null) {
      return 0;
    }

    return (minutes * 60) + seconds;
  }
}