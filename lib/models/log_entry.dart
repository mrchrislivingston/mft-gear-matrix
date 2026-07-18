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

  factory IntervalResult.fromJson(
    Map<String, dynamic> json,
  ) {
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
  final String prescriptionId;
  final Modality modality;
  final DateTime date;
  final String notes;
  final List<IntervalResult> intervals;

  /// Compatibility constructor for the existing Gear logger.
  ///
  /// Existing calls using gearNumber continue to work while the
  /// remaining screens are migrated to prescriptionId.
  LogEntry({
    required int gearNumber,
    required this.modality,
    required this.date,
    required this.notes,
    required this.intervals,
  }) : prescriptionId = 'G$gearNumber';

  /// Generic constructor for any prescription:
  /// G1–G8, P1–P3, or Z1–Z2.
  const LogEntry.forPrescription({
    required this.prescriptionId,
    required this.modality,
    required this.date,
    required this.notes,
    required this.intervals,
  });

  /// Temporary compatibility getter for screens that still expect
  /// a Gear number.
  ///
  /// Returns null for non-Gear prescriptions such as P1 or Z2.
  int? get gearNumber {
    if (!prescriptionId.startsWith('G')) {
      return null;
    }

    return int.tryParse(
      prescriptionId.substring(1),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'prescriptionId': prescriptionId,
      'modality': modality.name,
      'date': date.toIso8601String(),
      'notes': notes,
      'intervals': intervals
          .map((interval) => interval.toJson())
          .toList(),
    };
  }

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    final savedPrescriptionId =
        json['prescriptionId'] as String?;

    final legacyGearNumber = json['gearNumber'] as int?;

    final prescriptionId = savedPrescriptionId ??
        (legacyGearNumber == null
            ? 'G1'
            : 'G$legacyGearNumber');

    return LogEntry.forPrescription(
      prescriptionId: prescriptionId,
      modality: json['modality'] == null
          ? Modality.run
          : Modality.values.byName(
              json['modality'] as String,
            ),
      date: DateTime.parse(json['date'] as String),
      notes: (json['notes'] as String?) ?? '',
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