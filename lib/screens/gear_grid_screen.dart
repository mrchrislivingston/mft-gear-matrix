import 'package:flutter/material.dart';

import '../models/modality.dart';
import '../services/app_state.dart';
import '../widgets/gear_card.dart';
import 'gear_detail_screen.dart';

class GearGridScreen extends StatelessWidget {
  final Modality modality;

  const GearGridScreen({
    super.key,
    required this.modality,
  });

  String get title {
    switch (modality) {
      case Modality.run:
        return 'Run';
      case Modality.row:
        return 'Row';
      case Modality.ski:
        return 'SkiErg';
      case Modality.bikeErg:
        return 'C2 Bike';
      case Modality.echo:
        return 'Echo Bike';
    }
  }

  @override
  Widget build(BuildContext context) {
    final gears = AppState.instance.gears;

    return Scaffold(
      appBar: AppBar(
        title: Text('$title Gears'),
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
                  builder: (_) => GearDetailScreen(
                    gear: gear,
                    modality: modality,
                  ),
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