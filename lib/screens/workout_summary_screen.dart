import 'package:flutter/material.dart';

import '../models/log_entry.dart';
import 'history_screen.dart';
import 'home_screen.dart';

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

    if (parts.length == 2) {
      final minutes = int.tryParse(parts[0]) ?? 0;
      final seconds = int.tryParse(parts[1]) ?? 0;
      return (minutes * 60) + seconds;
    }

    return 0;
  }

  String _secondsToPace(int seconds) {
    if (seconds <= 0) return '-';

    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final totalDistance = log.intervals.fold<double>(
      0,
      (sum, interval) => sum + _toDouble(interval.distance),
    );

    final validPaces = log.intervals
        .map((interval) => _paceToSeconds(interval.avgPace))
        .where((seconds) => seconds > 0)
        .toList();

    final avgPaceSeconds = validPaces.isEmpty
        ? 0
        : (validPaces.reduce((a, b) => a + b) / validPaces.length).round();

    final avgHr = log.intervals.isEmpty
        ? 0
        : log.intervals
                .map((interval) => _toDouble(interval.avgHr))
                .reduce((a, b) => a + b) /
            log.intervals.length;

    final avgRpe = log.intervals.isEmpty
        ? 0
        : log.intervals
                .map((interval) => _toDouble(interval.rpe))
                .reduce((a, b) => a + b) /
            log.intervals.length;

    return Scaffold(
      appBar: AppBar(
  title: const Text('Workout Summary'),
  actions: [
    IconButton(
      icon: const Icon(Icons.home),
      onPressed: () {
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
    ),
  ],
),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Gear ${log.gearNumber}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 10),
          Text('Date: ${log.date.month}/${log.date.day}/${log.date.year}'),
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
                  Text('Total Distance: ${totalDistance.toStringAsFixed(2)} mi'),
                  const SizedBox(height: 8),
                  Text('Average Pace: ${_secondsToPace(avgPaceSeconds)} / mi'),
                  const SizedBox(height: 8),
                  Text('Average HR: ${avgHr.toStringAsFixed(0)}'),
                  const SizedBox(height: 8),
                  Text('Average RPE: ${avgRpe.toStringAsFixed(1)}'),
                ],
              ),
            ),
          ),

          if (log.notes.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Notes', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(log.notes),
          ],

          const SizedBox(height: 30),

          ElevatedButton(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const HomeScreen()),
                (route) => false,
              );
            },
            child: const Text('Return Home'),
          ),

          const SizedBox(height: 10),

          OutlinedButton(
            onPressed: () {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (_) => const HistoryScreen()),
              );
            },
            child: const Text('View History'),
          ),
        ],
      ),
    );
  }
}