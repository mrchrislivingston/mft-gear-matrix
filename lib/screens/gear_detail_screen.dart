import 'package:flutter/material.dart';

import '../models/gear.dart';
import '../services/app_state.dart';
import 'gear_history_screen.dart';
import 'log_workout_screen.dart';
import 'target_history_screen.dart';
import 'target_manager_screen.dart';

class GearDetailScreen extends StatefulWidget {
  final Gear gear;

  const GearDetailScreen({
    super.key,
    required this.gear,
  });

  @override
  State<GearDetailScreen> createState() => _GearDetailScreenState();
}

class _GearDetailScreenState extends State<GearDetailScreen> {
  @override
  Widget build(BuildContext context) {
    final currentGear = AppState.instance.gears.firstWhere(
      (item) => item.number == widget.gear.number,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text('Gear ${currentGear.number}'),
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
            'Gear ${currentGear.number}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),

          Text(
            'Prescription',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text('Work: ${currentGear.work}'),
          Text('Rest: ${currentGear.rest}'),
          Text('Intervals: ${currentGear.intervals}'),

          const SizedBox(height: 24),

          Text(
            'Run Target',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),

          Text('${currentGear.targetPaceDisplay} / mile'),

          const SizedBox(height: 16),

          ElevatedButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TargetManagerScreen(gear: currentGear),
                ),
              );

              if (mounted) {
                setState(() {});
              }
            },
            child: const Text('Edit Target'),
          ),

          const SizedBox(height: 10),

          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TargetHistoryScreen(
                    gear: currentGear,
                  ),
                ),
              );
            },
            child: const Text('View Target History'),
          ),

          const SizedBox(height: 30),

          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LogWorkoutScreen(
                    gear: currentGear,
                  ),
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
                  builder: (_) => GearHistoryScreen(
                    gear: currentGear,
                  ),
                ),
              );
            },
            child: const Text('View Workout History'),
          ),
        ],
      ),
    );
  }
}