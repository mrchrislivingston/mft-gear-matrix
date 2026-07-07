import 'package:flutter/material.dart';

import '../services/app_state.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final logs = AppState.instance.logs.reversed.toList();

    return Scaffold(
      appBar: AppBar(title: const Text('History')),
      body: logs.isEmpty
          ? const Center(child: Text('No workouts logged yet'))
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: logs.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final log = logs[index];

                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gear ${log.gearNumber}',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text('Date: ${log.date.month}/${log.date.day}/${log.date.year}'),
                        const SizedBox(height: 10),
                        Text('Intervals: ${log.intervals.length}'),
                        const SizedBox(height: 10),

                        for (final interval in log.intervals) ...[
                          Text(
                            'Interval ${interval.intervalNumber}: '
                            '${interval.distance} mi, '
                            '${interval.avgPace}/mi, '
                            'HR ${interval.avgHr}, '
                            'RPE ${interval.rpe}',
                          ),
                          const SizedBox(height: 4),
                        ],

                        if (log.notes.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text('Notes: ${log.notes}'),
                        ],
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}