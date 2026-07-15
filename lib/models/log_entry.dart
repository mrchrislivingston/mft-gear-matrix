import 'modality.dart';
import 'workout_metric.dart';

class IntervalResult {
  final int intervalNumber;
  final Map<WorkoutMetric, String> values;

  const IntervalResult({
    required this.intervalNumber,
    required this.values,
  });

  String valueFor(WorkoutMetric metric) {
    return values[metric] ?? '';
  }

  Map<String, dynamic> toJson() {
    return {
      'intervalNumber': intervalNumber,
      'values': values.map(
        (metric, value) => MapEntry(
          metric.storageKey,
          value,
        ),
      ),
    };
  }

  factory IntervalResult.fromJson(Map<String, dynamic> json) {
    final rawValues = json['values'];

    if (rawValues is Map<String, dynamic>) {
      final values = <WorkoutMetric, String>{};

      for (final entry in rawValues.entries) {
        final metric = WorkoutMetric.values.firstWhere(
          (item) => item.storageKey == entry.key,
        );

        values[metric] = entry.value as String;
      }

      return IntervalResult(
        intervalNumber: json['intervalNumber'] as int,
        values: values,
      );
    }

    // Backward compatibility for workouts saved before
    // the dynamic workout-metric model was introduced.
    return IntervalResult(
      intervalNumber: json['intervalNumber'] as int,
      values: {
        WorkoutMetric.distance:
            (json['distance'] as String?) ?? '',
        WorkoutMetric.primaryMetric:
            (json['primaryMetricValue'] ??
                    json['avgPace'] ??
                    '')
                as String,
        WorkoutMetric.heartRate:
            (json['avgHr'] as String?) ?? '',
        WorkoutMetric.rpe:
            (json['rpe'] as String?) ?? '',
      },
    );
  }
}

class LogEntry {
  final int gearNumber;
  final Modality modality;
  final DateTime date;
  final String notes;
  final List<IntervalResult> intervals;

  const LogEntry({
    required this.gearNumber,
    required this.modality,
    required this.date,
    required this.notes,
    required this.intervals,
  });

  Map<String, dynamic> toJson() {
    return {
      'gearNumber': gearNumber,
      'modality': modality.name,
      'date': date.toIso8601String(),
      'notes': notes,
      'intervals': intervals
          .map((interval) => interval.toJson())
          .toList(),
    };
  }

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      gearNumber: json['gearNumber'] as int,
      modality: json['modality'] == null
          ? Modality.run
          : Modality.values.byName(
              json['modality'] as String,
            ),
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String,
      intervals: (json['intervals'] as List)
          .map(
            (item) => IntervalResult.fromJson(
              item as Map<String, dynamic>,
            ),
          )
          .toList(),
    );
  }
}