import 'package:flutter/material.dart';

import '../models/log_entry.dart';

class WorkoutDetailScreen extends StatelessWidget {
  final LogEntry log;

  const WorkoutDetailScreen({
    super.key,
    required this.log,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
  title: Text('Gear ${log.gearNumber} Details'),
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
          Text('Date: ${log.date.month}/${log.date.day}/${log.date.year}'),
          const SizedBox(height: 20),

          for (final interval in log.intervals) ...[
            Card(
              child: ListTile(
                title: Text('Interval ${interval.intervalNumber}'),
                subtitle: Text(
                  'Distance: ${interval.distance} mi\n'
                  'Pace: ${interval.avgPace} / mi\n'
                  'HR: ${interval.avgHr}\n'
                  'RPE: ${interval.rpe}',
                ),
              ),
            ),
            const SizedBox(height: 8),
          ],

          if (log.notes.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('Notes', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(log.notes),
          ],
        ],
      ),
    );
  }
}