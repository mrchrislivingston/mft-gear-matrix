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

  double _paceToSeconds(String pace) {
    final parts = pace.trim().split(':');

    if (parts.length != 2) return 0;

    final minutes = int.tryParse(parts[0]);
    final seconds = double.tryParse(parts[1]);

    if (minutes == null || seconds == null) return 0;
    if (seconds < 0 || seconds >= 60) return 0;

    return (minutes * 60) + seconds;
  }

  String _secondsToPace(double seconds) {
    if (seconds <= 0) return '-';

    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds - (minutes * 60);

    if (remainingSeconds ==
        remainingSeconds.roundToDouble()) {
      return '$minutes:'
          '${remainingSeconds.toInt().toString().padLeft(2, '0')}';
    }

    final formattedSeconds =
        remainingSeconds.toStringAsFixed(1);

    final paddedSeconds =
        remainingSeconds < 10
            ? '0$formattedSeconds'
            : formattedSeconds;

    return '$minutes:$paddedSeconds';
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

  String averageLabelForMetric(
    WorkoutMetric workoutMetric,
    String primaryMetricName,
  ) {
    switch (workoutMetric) {
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

  String totalLabelForMetric(
    WorkoutMetric workoutMetric,
  ) {
    switch (workoutMetric) {
      case WorkoutMetric.distance:
        return 'Total Distance';

      case WorkoutMetric.calories:
        return 'Total Calories';

      default:
        return 'Total ${workoutMetric.displayName}';
    }
  }

  String averageForMetric(
    WorkoutMetric workoutMetric,
    bool primaryMetricUsesTimeFormat,
  ) {
    final values = log.intervals
        .map(
          (interval) =>
              interval.valueFor(workoutMetric),
        )
        .where(
          (value) => value.trim().isNotEmpty,
        )
        .toList();

    if (values.isEmpty) {
      return '-';
    }

    if (workoutMetric == WorkoutMetric.primaryMetric &&
        primaryMetricUsesTimeFormat) {
      final validValues = values
          .map(_paceToSeconds)
          .where((value) => value > 0)
          .toList();

      if (validValues.isEmpty) {
        return '-';
      }

      final averageSeconds =
          validValues.reduce((a, b) => a + b) /
              validValues.length;

      return _secondsToPace(
        averageSeconds,
      );
    }

    final numericValues = values
        .map(_toDouble)
        .where((value) => value > 0)
        .toList();

    if (numericValues.isEmpty) {
      return '-';
    }

    final average =
        numericValues.reduce((a, b) => a + b) /
            numericValues.length;

    switch (workoutMetric) {
      case WorkoutMetric.heartRate:
      case WorkoutMetric.watts:
      case WorkoutMetric.caloriesPerHour:
      case WorkoutMetric.rpm:
      case WorkoutMetric.strokeRate:
        return average.toStringAsFixed(0);

      case WorkoutMetric.rpe:
      case WorkoutMetric.primaryMetric:
      case WorkoutMetric.distance:
      case WorkoutMetric.calories:
        return average.toStringAsFixed(1);
    }
  }

  String totalForMetric(
    WorkoutMetric workoutMetric,
  ) {
    final total = log.intervals.fold<double>(
      0,
      (sum, interval) {
        return sum +
            _toDouble(
              interval.valueFor(workoutMetric),
            );
      },
    );

    if (total <= 0) {
      return '-';
    }

    switch (workoutMetric) {
      case WorkoutMetric.calories:
        return total.toStringAsFixed(0);

      case WorkoutMetric.distance:
        return total.toStringAsFixed(2);

      default:
        return total.toStringAsFixed(1);
    }
  }

  bool hasRecordedValue(
    WorkoutMetric workoutMetric,
  ) {
    return log.intervals.any(
      (interval) =>
          interval
              .valueFor(workoutMetric)
              .trim()
              .isNotEmpty,
    );
  }

  List<WorkoutMetric> get recordedMetrics {
    return WorkoutMetric.values
        .where(hasRecordedValue)
        .toList();
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
        prescription?.targetForModality(
      log.modality,
    );

    final primaryMetric =
        target?.metric ?? log.modality.defaultMetric;

    final primaryMetricName =
        primaryMetric.displayName;

    final primaryMetricUnit =
        primaryMetric.unitLabel;

    final primaryMetricUsesTimeFormat =
        primaryMetric.usesTimeFormat;

    final prescriptionName =
        prescription?.name ?? log.prescriptionId;

    final totalDistance =
        log.intervals.fold<double>(
      0,
      (sum, interval) {
        return sum +
            _toDouble(
              interval.valueFor(
                WorkoutMetric.distance,
              ),
            );
      },
    );

    final totalMetrics = recordedMetrics
        .where(
          (metric) =>
              metric == WorkoutMetric.calories,
        )
        .toList();

    final averageMetrics = recordedMetrics
        .where(
          (metric) =>
              metric != WorkoutMetric.distance,
        )
        .toList();

    final hasDuration =
        log.duration.trim().isNotEmpty;

    final hasWorkoutTotals =
        hasDuration ||
        totalDistance > 0 ||
        totalMetrics.isNotEmpty;

    final hasSourceWorkbook =
        log.sourceWorkbook.trim().isNotEmpty;

    final hasProgramDay =
        log.programDay.trim().isNotEmpty;

    final hasHistoricalSource =
        hasSourceWorkbook || hasProgramDay;

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
            '${log.modality.displayName} '
            '$prescriptionName',
            style:
                Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Text(
            'Date: '
            '${log.date.month}/'
            '${log.date.day}/'
            '${log.date.year}',
          ),
          if (hasHistoricalSource) ...[
            const SizedBox(height: 8),
            Text(
              [
                if (hasSourceWorkbook)
                  log.sourceWorkbook,
                if (hasProgramDay)
                  log.programDay,
              ].join(' • '),
            ),
          ],
          const SizedBox(height: 30),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start,
                children: [
                  Text(
                    'Workout Totals',
                    style: Theme.of(context)
                        .textTheme
                        .titleLarge,
                  ),
                  const SizedBox(height: 16),
                  if (hasDuration) ...[
                    Text(
                      'Duration: ${log.duration}',
                    ),
                    if (totalDistance > 0 ||
                        totalMetrics.isNotEmpty)
                      const SizedBox(height: 8),
                  ],
                  if (totalDistance > 0) ...[
                    Text(
                      'Total Distance: '
                      '${totalDistance.toStringAsFixed(2)}'
                      '${distanceUnit.isEmpty ? '' : ' $distanceUnit'}',
                    ),
                    if (totalMetrics.isNotEmpty)
                      const SizedBox(height: 8),
                  ],
                  for (
                    int index = 0;
                    index < totalMetrics.length;
                    index++
                  ) ...[
                    Builder(
                      builder: (context) {
                        final workoutMetric =
                            totalMetrics[index];

                        final total =
                            totalForMetric(
                          workoutMetric,
                        );

                        final label =
                            totalLabelForMetric(
                          workoutMetric,
                        );

                        final unit =
                            unitForMetric(
                          workoutMetric,
                          primaryMetricUnit,
                        );

                        return Text(
                          '$label: $total'
                          '${total == '-' || unit.isEmpty ? '' : ' $unit'}',
                        );
                      },
                    ),
                    if (index <
                        totalMetrics.length - 1)
                      const SizedBox(height: 8),
                  ],
                  if (!hasWorkoutTotals)
                    const Text(
                      'No workout totals recorded.',
                    ),
                ],
              ),
            ),
          ),
          if (averageMetrics.isNotEmpty) ...[
            const SizedBox(height: 20),
            Card(
              child: Padding(
                padding:
                    const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Interval Averages',
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge,
                    ),
                    const SizedBox(height: 16),
                    for (
                      int index = 0;
                      index < averageMetrics.length;
                      index++
                    ) ...[
                      Builder(
                        builder: (context) {
                          final workoutMetric =
                              averageMetrics[index];

                          final average =
                              averageForMetric(
                            workoutMetric,
                            primaryMetricUsesTimeFormat,
                          );

                          final label =
                              averageLabelForMetric(
                            workoutMetric,
                            primaryMetricName,
                          );

                          final unit =
                              unitForMetric(
                            workoutMetric,
                            primaryMetricUnit,
                          );

                          return Text(
                            '$label: $average'
                            '${average == '-' || unit.isEmpty ? '' : ' $unit'}',
                          );
                        },
                      ),
                      if (index <
                          averageMetrics.length - 1)
                        const SizedBox(height: 8),
                    ],
                  ],
                ),
              ),
            ),
          ],
          if (log.notes.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text(
              'Notes',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge,
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
                  builder: (_) =>
                      WorkoutDetailScreen(
                    log: log,
                  ),
                ),
              );
            },
            child:
                const Text('View Workout Details'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) =>
                      const HistoryScreen(),
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
                  builder: (_) =>
                      const HomeScreen(),
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