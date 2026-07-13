import 'package:flutter/material.dart';

import '../models/modality.dart';
import '../services/app_state.dart';
import 'gear_history_screen.dart';

class HistoryGearsScreen extends StatelessWidget {
  final Modality modality;

  const HistoryGearsScreen({
    super.key,
    required this.modality,
  });

  @override
  Widget build(BuildContext context) {
    final gears = AppState.instance.gears;

    return Scaffold(
      appBar: AppBar(
        title: Text('${modality.displayName} History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: gears.length,
        separatorBuilder: (_, __) => const Divider(),
        itemBuilder: (context, index) {
          final gear = gears[index];

          return ListTile(
            title: Text('Gear ${gear.number}'),
            subtitle: Text('${gear.work} work / ${gear.rest} rest'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GearHistoryScreen(
                    gear: gear,
                    modality: modality,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}