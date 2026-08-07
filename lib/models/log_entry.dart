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
                    '') as String,
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

  /// Historical source workbook.
  ///
  /// Empty for workouts logged directly in the app.
  final String sourceWorkbook;

  /// Historical program-position identifier such as W5D2.
  ///
  /// Empty for workouts logged directly in the app.
  final String programDay;

  /// Only used for continuous Z1/Z2 workouts.
  final String duration;

  /// Prescribed work duration for each interval.
  final String workDuration;

  /// Number of prescribed work intervals.
  final int intervalCount;

  /// Identifies the prescribed scoring metric for workouts
  /// that may be scored using either distance or calories.
  ///
  /// This is currently intended for Power workouts.
  final WorkoutMetric? scoringMetric;

  final String notes;
  final List<IntervalResult> intervals;

  /// Compatibility constructor for the existing Gear logger.
  LogEntry({
    required int gearNumber,
    required this.modality,
    required this.date,
    this.sourceWorkbook = '',
    this.programDay = '',
    this.duration = '',
    this.workDuration = '',
    int? intervalCount,
    this.scoringMetric,
    required this.notes,
    required List<IntervalResult> intervals,
  })  : prescriptionId = 'G$gearNumber',
        intervals = intervals,
        intervalCount = intervalCount ?? intervals.length;

  /// Generic constructor for any prescription.
  LogEntry.forPrescription({
    required this.prescriptionId,
    required this.modality,
    required this.date,
    this.sourceWorkbook = '',
    this.programDay = '',
    this.duration = '',
    this.workDuration = '',
    int? intervalCount,
    this.scoringMetric,
    required this.notes,
    required List<IntervalResult> intervals,
  })  : intervals = intervals,
        intervalCount = intervalCount ?? intervals.length;

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
      'sourceWorkbook': sourceWorkbook,
      'programDay': programDay,
      'duration': duration,
      'workDuration': workDuration,
      'intervalCount': intervalCount,
      'scoringMetric': scoringMetric?.storageKey,
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

    final savedScoringMetric =
        json['scoringMetric'] as String?;

    WorkoutMetric? scoringMetric;

    if (savedScoringMetric != null) {
      for (final metric in WorkoutMetric.values) {
        if (metric.storageKey == savedScoringMetric) {
          scoringMetric = metric;
          break;
        }
      }
    }

    final intervals = (json['intervals'] as List)
        .map(
          (item) => IntervalResult.fromJson(
            item as Map<String, dynamic>,
          ),
        )
        .toList();

    return LogEntry.forPrescription(
      prescriptionId: prescriptionId,
      modality: json['modality'] == null
          ? Modality.run
          : Modality.values.byName(
              json['modality'] as String,
            ),
      date: DateTime.parse(json['date'] as String),
      sourceWorkbook:
          (json['sourceWorkbook'] as String?) ?? '',
      programDay:
          (json['programDay'] as String?) ?? '',
      duration: (json['duration'] as String?) ?? '',
      workDuration:
          (json['workDuration'] as String?) ?? '',
      intervalCount:
          (json['intervalCount'] as int?) ?? intervals.length,
      scoringMetric: scoringMetric,
      notes: (json['notes'] as String?) ?? '',
      intervals: intervals,
    );
  }
}