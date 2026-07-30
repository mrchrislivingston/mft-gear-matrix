import 'package:flutter/material.dart';

import '../models/gear.dart';
import '../models/log_entry.dart';
import '../models/modality.dart';
import '../models/workout_metric.dart';
import '../services/app_state.dart';
import '../services/personal_record_service.dart';
import '../services/workout_analytics.dart';
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

  String _secondsToPace(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    return '$minutes:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
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

  String _formattedDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _averagePrimaryMetric(LogEntry log) {
    final target = gear.targetForModality(modality);
    final metric = target?.metric;

    final metricValues = log.intervals
        .map(
          (interval) =>
              interval.valueFor(WorkoutMetric.primaryMetric),
        )
        .where((value) => value.trim().isNotEmpty)
        .toList();

    if (metricValues.isEmpty) {
      return '-';
    }

    if (metric?.usesTimeFormat == true) {
      final valuesInSeconds = metricValues
          .map(_paceToSeconds)
          .where((value) => value > 0)
          .toList();

      if (valuesInSeconds.isEmpty) {
        return '-';
      }

      final averageSeconds =
          valuesInSeconds.reduce((a, b) => a + b) /
              valuesInSeconds.length;

      return _secondsToPace(
        averageSeconds.round(),
      );
    }

    final numericValues = metricValues
        .map(_toDouble)
        .where((value) => value > 0)
        .toList();

    if (numericValues.isEmpty) {
      return '-';
    }

    final average =
        numericValues.reduce((a, b) => a + b) /
            numericValues.length;

    return average.toStringAsFixed(1);
  }

  double _totalDistance(LogEntry log) {
    return log.intervals.fold<double>(
      0,
      (sum, interval) {
        return sum +
            _toDouble(
              interval.valueFor(WorkoutMetric.distance),
            );
      },
    );
  }

  double? _averageMetric(
    LogEntry log,
    WorkoutMetric workoutMetric,
  ) {
    final values = log.intervals
        .map(
          (interval) => _toDouble(
            interval.valueFor(workoutMetric),
          ),
        )
        .where((value) => value > 0)
        .toList();

    if (values.isEmpty) {
      return null;
    }

    return values.reduce((a, b) => a + b) / values.length;
  }

  Widget _summaryRow({
    required String label,
    required String value,
    bool emphasize = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 105,
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.grey,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontWeight: emphasize
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildSummary(
    BuildContext context,
    LogEntry log,
    List<LogEntry> allLogs,
  ) {
    final target = gear.targetForModality(modality);
    final metric = target?.metric;

    final averagePrimaryMetric =
        _averagePrimaryMetric(log);

    final totalDistance = _totalDistance(log);

    final averageHr = _averageMetric(
      log,
      WorkoutMetric.heartRate,
    );

    final averageRpe = _averageMetric(
      log,
      WorkoutMetric.rpe,
    );

    final primaryMetricUsesTimeFormat =
        metric?.usesTimeFormat == true;

    final executionScore =
        WorkoutAnalytics.executionScore(
      log: log,
      primaryMetricUsesTimeFormat:
          primaryMetricUsesTimeFormat,
    );

    final isPersonalRecord =
        PersonalRecordService.isPersonalRecord(
      log: log,
      allLogs: allLogs,
      primaryMetricUsesTimeFormat:
          primaryMetricUsesTimeFormat,
    );

    final performanceValue =
        metric == null || averagePrimaryMetric == '-'
            ? averagePrimaryMetric
            : '$averagePrimaryMetric ${metric.unitLabel}';

    final distanceValue = totalDistance <= 0
        ? '-'
        : distanceUnit.isEmpty
            ? totalDistance.toStringAsFixed(2)
            : '${totalDistance.toStringAsFixed(2)} '
                '$distanceUnit';

    final heartRateValue = averageHr == null
        ? '-'
        : '${averageHr.toStringAsFixed(0)} bpm';

    final rpeValue = averageRpe == null
        ? '-'
        : averageRpe.toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 4,
        vertical: 8,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  _formattedDate(log.date),
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
              ),
              if (isPersonalRecord)
                const Tooltip(
                  message: 'Personal Record',
                  child: Icon(
                    Icons.emoji_events,
                    size: 22,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          _summaryRow(
            label: 'Performance',
            value: performanceValue,
            emphasize: true,
          ),
          _summaryRow(
            label: 'Execution',
            value: executionScore,
          ),
          if (totalDistance > 0)
            _summaryRow(
              label: 'Distance',
              value: distanceValue,
            ),
          _summaryRow(
            label: 'Average HR',
            value: heartRateValue,
          ),
          _summaryRow(
            label: 'Average RPE',
            value: rpeValue,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final allLogs = AppState.instance.logs;

    final logs = allLogs
        .where(
          (log) =>
              log.prescriptionId == gear.id &&
              log.modality == modality,
        )
        .toList()
        .reversed
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${modality.displayName} '
          'Gear ${gear.number} History',
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
                'No ${modality.displayName} '
                'history for this gear yet',
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
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
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        16,
                        12,
                        8,
                        12,
                      ),
                      child: Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.center,
                        children: [
                          Expanded(
                            child: buildSummary(
                              context,
                              log,
                              allLogs,
                            ),
                          ),
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.chevron_right,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}