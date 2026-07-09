import 'package:flutter/material.dart';

import '../services/app_state.dart';
import '../widgets/gear_card.dart';
import 'gear_detail_screen.dart';

class RunGridScreen extends StatelessWidget {
  const RunGridScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gears = AppState.instance.gears;
    return Scaffold(
      appBar: AppBar(
  title: const Text('Run Grid'),
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
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final gear = gears[index];

          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => GearDetailScreen(gear: gear),
                ),
              );
            },
            child: GearCard(gear: gear),
          );
        },
      ),
    );
  }
}