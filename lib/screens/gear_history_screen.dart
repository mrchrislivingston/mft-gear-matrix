import 'package:flutter/material.dart';

import '../models/gear.dart';
import '../models/log_entry.dart';
import '../services/app_state.dart';
import 'workout_detail_screen.dart';

class GearHistoryScreen extends StatelessWidget {
  final Gear gear;

  const GearHistoryScreen({
    super.key,
    required this.gear,
  });

  double _toDouble(String value) =>
      double.tryParse(value.trim()) ?? 0;

  int _paceToSeconds(String pace) {
    final parts = pace.split(':');
    if (parts.length != 2) return 0;

    final minutes = int.tryParse(parts[0]) ?? 0;
    final seconds = int.tryParse(parts[1]) ?? 0;

    return (minutes * 60) + seconds;
  }

  String _secondsToPace(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;

    return '$minutes:${secs.toString().padLeft(2, '0')}';
  }

  Widget buildSummary(LogEntry log) {
    final totalDistance = log.intervals.fold<double>(
      0,
      (sum, interval) => sum + _toDouble(interval.distance),
    );

    final paceSeconds = log.intervals
        .map((e) => _paceToSeconds(e.avgPace))
        .where((e) => e > 0)
        .toList();

    final avgPace = paceSeconds.isEmpty
        ? '-'
        : _secondsToPace(
            (paceSeconds.reduce((a, b) => a + b) / paceSeconds.length).round(),
          );

    final avgHr = log.intervals
            .map((e) => _toDouble(e.avgHr))
            .reduce((a, b) => a + b) /
        log.intervals.length;

    final avgRpe = log.intervals
            .map((e) => _toDouble(e.rpe))
            .reduce((a, b) => a + b) /
        log.intervals.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '${log.date.month}/${log.date.day}/${log.date.year}',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        Text('${totalDistance.toStringAsFixed(2)} mi'),
        Text('$avgPace / mi'),
        Text('${avgHr.toStringAsFixed(0)} bpm'),
        Text('RPE ${avgRpe.toStringAsFixed(1)}'),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final logs = AppState.instance.logs
        .where((log) => log.gearNumber == gear.number)
        .toList()
        .reversed
        .toList();

    return Scaffold(
      appBar: AppBar(
  title: Text('Gear ${gear.number} History'),
  actions: [
    IconButton(
      icon: const Icon(Icons.home),
      onPressed: () {
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
    ),
  ],
),
      body: logs.isEmpty
          ? const Center(child: Text('No history for this gear yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: logs.length,
              itemBuilder: (context, index) {
                final log = logs[index];

                return Card(
                  child: ListTile(
                    title: buildSummary(log),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => WorkoutDetailScreen(log: log),
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