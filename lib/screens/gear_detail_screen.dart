import 'package:flutter/material.dart';

import '../models/gear.dart';
import '../models/log_entry.dart';
import '../services/app_state.dart';

class GearDetailScreen extends StatelessWidget {
  final Gear gear;

  const GearDetailScreen({
    super.key,
    required this.gear,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gear ${gear.number}')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Work: ${gear.work}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text('Rest: ${gear.rest}', style: const TextStyle(fontSize: 18)),
            const SizedBox(height: 10),
            Text(
              'Intervals: ${gear.intervals}',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: () {
                AppState.instance.addLog(
                  LogEntry(
                    gearNumber: gear.number,
                    date: DateTime.now(),
                    actualWork: gear.work,
                    actualRest: gear.rest,
                    notes: 'placeholder',
                    success: true,
                  ),
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Logged workout')),
                );
              },
              child: const Text('Log Workout'),
            ),
          ],
        ),
      ),
    );
  }
}