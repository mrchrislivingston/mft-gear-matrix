import 'package:flutter/material.dart';

import '../models/log_entry.dart';
import '../models/modality.dart';
import '../models/workout_metric.dart';
import '../services/app_state.dart';
import 'history_screen.dart';
import 'home_screen.dart';
import 'workout_detail_screen.dart';

class WorkoutSummaryScreen extends StatelessWidget {
  final LogEntry log;

  const WorkoutSummaryScreen({
    super.key,
    required this.log,
  });

  double _toDouble(String value) {
    return double.tryParse(value.trim()) ?? 0;
  }

  int _paceToSeconds(String pace) {
    final parts = pace.trim().split(':');

    if (parts.length != 2) return 0;

    final minutes = int.tryParse(parts[0]);
    final seconds = int.tryParse(parts[1]);

    if (minutes == null || seconds == null) return 0;
    if (seconds < 0 || seconds > 59) return 0;

    return (minutes * 60) + seconds;
  }

  String _secondsToPace(int seconds) {
    if (seconds <= 0) return '-';

    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

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

  String labelForMetric(
    WorkoutMetric workoutMetric,
    String primaryMetricName,
  ) {
    switch (workoutMetric) {
      case WorkoutMetric.distance:
        return 'Total Distance';
      case WorkoutMetric.primaryMetric:
        return 'Average $primaryMetricName';
      case WorkoutMetric.heartRate:
        return 'Average HR';
      case WorkoutMetric.rpe:
        return 'Average RPE';
      default:
        return 'Average ${workoutMetric.displayName}';
    }
  }

  String averageForMetric(
    WorkoutMetric workoutMetric,
    bool primaryMetricUsesTimeFormat,
  ) {
    final values = log.intervals
        .map(
          (interval) => interval.valueFor(workoutMetric),
        )
        .where((value) => value.trim().isNotEmpty)
        .toList();

    if (values.isEmpty) return '-';

    if (workoutMetric == WorkoutMetric.primaryMetric &&
        primaryMetricUsesTimeFormat) {
      final validValues = values
          .map(_paceToSeconds)
          .where((value) => value > 0)
          .toList();

      if (validValues.isEmpty) return '-';

      final averageSeconds =
          validValues.reduce((a, b) => a + b) /
              validValues.length;

      return _secondsToPace(averageSeconds.round());
    }

    final numericValues = values
        .map(_toDouble)
        .where((value) => value > 0)
        .toList();

    if (numericValues.isEmpty) return '-';

    final average =
        numericValues.reduce((a, b) => a + b) /
            numericValues.length;

    switch (workoutMetric) {
      case WorkoutMetric.heartRate:
      case WorkoutMetric.watts:
      case WorkoutMetric.calories:
      case WorkoutMetric.caloriesPerHour:
      case WorkoutMetric.rpm:
      case WorkoutMetric.strokeRate:
        return average.toStringAsFixed(0);

      case WorkoutMetric.rpe:
      case WorkoutMetric.primaryMetric:
      case WorkoutMetric.distance:
        return average.toStringAsFixed(1);
    }
  }

  @override
  Widget build(BuildContext context) {
    final gear = AppState.instance.gears.firstWhere(
      (item) => item.number == log.gearNumber,
    );

    final target = gear.targetForModality(log.modality);
    final primaryMetricName =
        target?.metric.displayName ?? 'Primary Metric';
    final primaryMetricUnit = target?.metric.unitLabel ?? '';
    final primaryMetricUsesTimeFormat =
        target?.metric.usesTimeFormat == true;

    final totalDistance = log.intervals.fold<double>(
      0,
      (sum, interval) {
        return sum +
            _toDouble(
              interval.valueFor(WorkoutMetric.distance),
            );
      },
    );

    final summaryMetrics = log.modality.workoutMetrics
        .where(
          (metric) =>
              metric != WorkoutMetric.distance &&
              log.intervals.any(
                (interval) =>
                    interval.valueFor(metric).trim().isNotEmpty,
              ),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Workout Summary'),
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
            '${log.modality.displayName} Gear ${log.gearNumber}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Text(
            'Date: ${log.date.month}/${log.date.day}/${log.date.year}',
          ),
          const SizedBox(height: 30),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Workout Totals',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  if (totalDistance > 0) ...[
                    Text(
                      'Total Distance: ${totalDistance.toStringAsFixed(2)}'
                      '${distanceUnit.isEmpty ? '' : ' $distanceUnit'}',
                    ),
                    if (summaryMetrics.isNotEmpty)
                      const SizedBox(height: 8),
                  ],
                  for (int index = 0;
                      index < summaryMetrics.length;
                      index++) ...[
                    Builder(
                      builder: (context) {
                        final workoutMetric =
                            summaryMetrics[index];

                        final average = averageForMetric(
                          workoutMetric,
                          primaryMetricUsesTimeFormat,
                        );

                        final label = labelForMetric(
                          workoutMetric,
                          primaryMetricName,
                        );

                        final unit = unitForMetric(
                          workoutMetric,
                          primaryMetricUnit,
                        );

                        return Text(
                          '$label: $average'
                          '${average == '-' || unit.isEmpty ? '' : ' $unit'}',
                        );
                      },
                    ),
                    if (index < summaryMetrics.length - 1)
                      const SizedBox(height: 8),
                  ],
                ],
              ),
            ),
          ),
          if (log.notes.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Notes',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(log.notes),
          ],
          const SizedBox(height: 30),

          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => WorkoutDetailScreen(
                    log: log,
                  ),
                ),
              );
            },
            child: const Text('View Workout Details'),
          ),

          const SizedBox(height: 10),

          OutlinedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const HistoryScreen(),
                ),
              );
            },
            child: const Text('View History'),
          ),

          const SizedBox(height: 10),

          OutlinedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(
                  builder: (_) => const HomeScreen(),
                ),
                (route) => false,
              );
            },
            child: const Text('Return Home'),
          ),
        ],
      ),
    );
  }
}