import 'package:flutter/material.dart';

import '../data/run_gears.dart';
import 'gear_history_screen.dart';

class HistoryRunGearsScreen extends StatelessWidget {
  const HistoryRunGearsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Run History')),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: runGears.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final gear = runGears[index];

          return ListTile(
            title: Text('Gear ${gear.number}'),
            subtitle: Text('${gear.work} work / ${gear.rest} rest'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GearHistoryScreen(gear: gear),
                ),
              );
            },
          );
        },
      ),
    );
  }
}