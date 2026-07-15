import 'package:flutter/material.dart';

import '../models/modality.dart';
import 'history_gear_grid_screen.dart';

class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  void _openModality(
    BuildContext context,
    Modality modality,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HistoryGearGridScreen(
          modality: modality,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).popUntil(
                (route) => route.isFirst,
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ListTile(
            title: const Text('Run'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _openModality(
                context,
                Modality.run,
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Echo Bike'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _openModality(
                context,
                Modality.echo,
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('C2 Bike'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _openModality(
                context,
                Modality.bikeErg,
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('Row'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _openModality(
                context,
                Modality.row,
              );
            },
          ),
          const Divider(),
          ListTile(
            title: const Text('SkiErg'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              _openModality(
                context,
                Modality.ski,
              );
            },
          ),
        ],
      ),
    );
  }
}