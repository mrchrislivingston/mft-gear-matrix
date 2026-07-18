import 'package:flutter/material.dart';

import '../models/log_entry.dart';
import '../models/modality.dart';
import '../models/workout_metric.dart';
import '../services/app_state.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final LogEntry log;

  const WorkoutDetailScreen({
    super.key,
    required this.log,
  });

  String get distanceUnit {
    switch (log.modality) {
      case Modality.run:
        return 'mi';

      case Modality.row:
      case Modality.ski:
      case Modality.bikeErg:
        return 'm';

      case Modality.echo:
        return '';
    }
  }

  String labelForMetric(
    WorkoutMetric workoutMetric,
    String primaryMetricName,
  ) {
    switch (workoutMetric) {
      case WorkoutMetric.primaryMetric:
        return primaryMetricName;

      case WorkoutMetric.heartRate:
        return 'HR';

      default:
        return workoutMetric.displayName;
    }
  }

  String unitForMetric(
    WorkoutMetric workoutMetric,
    String primaryMetricUnit,
  ) {
    switch (workoutMetric) {
      case WorkoutMetric.distance:
        return distanceUnit;

      case WorkoutMetric.primaryMetric:
        return primaryMetricUnit;

      case WorkoutMetric.watts:
        return 'W';

      case WorkoutMetric.calories:
        return 'cal';

      case WorkoutMetric.caloriesPerHour:
        return 'cal/hr';

      case WorkoutMetric.rpm:
        return 'RPM';

      case WorkoutMetric.strokeRate:
        return 'spm';

      case WorkoutMetric.heartRate:
        return 'bpm';

      case WorkoutMetric.rpe:
        return '';
    }
  }

  String buildIntervalDetails(
    IntervalResult interval,
    String primaryMetricName,
    String primaryMetricUnit,
  ) {
    final lines = <String>[];

    for (final workoutMetric
        in log.modality.workoutMetrics) {
      final value =
          interval.valueFor(workoutMetric).trim();

      if (value.isEmpty) {
        continue;
      }

      final label = labelForMetric(
        workoutMetric,
        primaryMetricName,
      );

      final unit = unitForMetric(
        workoutMetric,
        primaryMetricUnit,
      );

      lines.add(
        '$label: $value${unit.isEmpty ? '' : ' $unit'}',
      );
    }

    return lines.join('\n');
  }

  @override
  Widget build(BuildContext context) {
    final prescriptionIndex =
        AppState.instance.prescriptions.indexWhere(
      (item) => item.id == log.prescriptionId,
    );

    final prescription = prescriptionIndex == -1
        ? null
        : AppState.instance.prescriptions[
            prescriptionIndex
          ];

    final target =
        prescription?.targetForModality(log.modality);

    final primaryMetricName =
        target?.metric.displayName ?? 'Primary Metric';

    final primaryMetricUnit =
        target?.metric.unitLabel ?? '';

    final prescriptionName =
        prescription?.name ?? log.prescriptionId;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${log.modality.displayName} '
          '$prescriptionName Details',
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).popUntil(
                (route) => route.isFirst,
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Date: '
            '${log.date.month}/'
            '${log.date.day}/'
            '${log.date.year}',
          ),
          const SizedBox(height: 20),
          for (final interval in log.intervals) ...[
            Card(
              child: ListTile(
                title: Text(
                  'Interval ${interval.intervalNumber}',
                ),
                subtitle: Text(
                  buildIntervalDetails(
                    interval,
                    primaryMetricName,
                    primaryMetricUnit,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],
          if (log.notes.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Notes',
              style:
                  Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(log.notes),
          ],
        ],
      ),
    );
  }
}