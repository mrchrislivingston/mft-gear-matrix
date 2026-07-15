import 'package:flutter/material.dart';

import '../models/gear.dart';
import '../models/log_entry.dart';
import '../models/modality.dart';
import '../models/workout_metric.dart';
import '../services/app_state.dart';
import 'workout_detail_screen.dart';

class GearHistoryScreen extends StatelessWidget {
  final Gear gear;
  final Modality modality;

  const GearHistoryScreen({
    super.key,
    required this.gear,
    required this.modality,
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
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  String get distanceUnit {
    switch (modality) {
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

  Widget buildSummary(LogEntry log) {
    final target = gear.targetForModality(modality);
    final metric = target?.metric;

    final totalDistance = log.intervals.fold<double>(
      0,
      (sum, interval) {
        return sum +
            _toDouble(
              interval.valueFor(WorkoutMetric.distance),
            );
      },
    );

    final metricValues = log.intervals
        .map(
          (interval) =>
              interval.valueFor(WorkoutMetric.primaryMetric),
        )
        .where((value) => value.trim().isNotEmpty)
        .toList();

    String averageMetric = '-';

    if (metric?.usesTimeFormat == true) {
      final valuesInSeconds = metricValues
          .map(_paceToSeconds)
          .where((value) => value > 0)
          .toList();

      if (valuesInSeconds.isNotEmpty) {
        final averageSeconds =
            valuesInSeconds.reduce((a, b) => a + b) /
                valuesInSeconds.length;

        averageMetric = _secondsToPace(
          averageSeconds.round(),
        );
      }
    } else {
      final numericValues = metricValues
          .map(_toDouble)
          .where((value) => value > 0)
          .toList();

      if (numericValues.isNotEmpty) {
        final average =
            numericValues.reduce((a, b) => a + b) /
                numericValues.length;

        averageMetric = average.toStringAsFixed(1);
      }
    }

    final hrValues = log.intervals
        .map(
          (interval) => _toDouble(
            interval.valueFor(WorkoutMetric.heartRate),
          ),
        )
        .where((value) => value > 0)
        .toList();

    final rpeValues = log.intervals
        .map(
          (interval) => _toDouble(
            interval.valueFor(WorkoutMetric.rpe),
          ),
        )
        .where((value) => value > 0)
        .toList();

    final averageHr = hrValues.isEmpty
        ? null
        : hrValues.reduce((a, b) => a + b) /
            hrValues.length;

    final averageRpe = rpeValues.isEmpty
        ? null
        : rpeValues.reduce((a, b) => a + b) /
            rpeValues.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${log.date.month}/${log.date.day}/${log.date.year}',
          style: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        if (totalDistance > 0)
          Text(
            distanceUnit.isEmpty
                ? totalDistance.toStringAsFixed(2)
                : '${totalDistance.toStringAsFixed(2)} $distanceUnit',
          ),
        Text(
          metric == null
              ? averageMetric
              : '$averageMetric ${metric.unitLabel}',
        ),
        Text(
          averageHr == null
              ? 'HR -'
              : '${averageHr.toStringAsFixed(0)} bpm',
        ),
        Text(
          averageRpe == null
              ? 'RPE -'
              : 'RPE ${averageRpe.toStringAsFixed(1)}',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final logs = AppState.instance.logs
        .where(
          (log) =>
              log.gearNumber == gear.number &&
              log.modality == modality,
        )
        .toList()
        .reversed
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${modality.displayName} Gear ${gear.number} History',
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
      body: logs.isEmpty
          ? Center(
              child: Text(
                'No ${modality.displayName} history for this gear yet',
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];

                return Card(
                  child: ListTile(
                    title: buildSummary(log),
                    trailing: const Icon(
                      Icons.chevron_right,
                    ),
                    onTap: () {
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
                  ),
                );
              },
            ),
    );
  }
}