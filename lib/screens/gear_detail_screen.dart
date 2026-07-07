import 'package:flutter/material.dart';

import '../models/gear.dart';
import 'gear_history_screen.dart';
import 'log_workout_screen.dart';

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
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Gear ${gear.number}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          Text('Prescription', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Text('Work: ${gear.work}'),
          Text('Rest: ${gear.rest}'),
          Text('Intervals: ${gear.intervals}'),
          const SizedBox(height: 24),
          Text('Target Pace', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 10),
          Text('${gear.targetPaceDisplay} / mile'),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LogWorkoutScreen(gear: gear),
                ),
              );
            },
            child: const Text('Log Workout'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GearHistoryScreen(gear: gear),
                ),
              );
            },
            child: const Text('View Gear History'),
          ),
        ],
      ),
    );
  }
}