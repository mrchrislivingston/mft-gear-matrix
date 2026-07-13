import 'package:flutter/material.dart';

import '../models/gear.dart';
import '../models/modality.dart';

class TargetHistoryScreen extends StatelessWidget {
  final Gear gear;
  final Modality modality;

  const TargetHistoryScreen({
    super.key,
    required this.gear,
    required this.modality,
  });

  @override
  Widget build(BuildContext context) {
    final target = gear.targetForModality(modality);
    final history = target?.history.reversed.toList() ?? [];

    if (history.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            '${modality.displayName} Gear ${gear.number} Target History',
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.home),
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
        ),
        body: const Center(
          child: Text('No target history available.'),
        ),
      );
    }

    final current = history.first;
    final previous = history.skip(1).toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${modality.displayName} Gear ${gear.number} Target History',
        ),
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
            'Current Target',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),

          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    target?.displayTarget ?? 'No target',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Effective '
                    '${current.effectiveDate.month}/'
                    '${current.effectiveDate.day}/'
                    '${current.effectiveDate.year}',
                  ),
                ],
              ),
            ),
          ),

          if (previous.isNotEmpty) ...[
            const SizedBox(height: 30),

            Text(
              'Previous Targets',
              style: Theme.of(context).textTheme.titleLarge,
            ),

            const SizedBox(height: 12),

            ...previous.map(
              (entry) => Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(
                    '${entry.displayTarget} ${target?.metric.name ?? ''}',
                  ),
                  subtitle: Text(
                    '${entry.effectiveDate.month}/'
                    '${entry.effectiveDate.day}/'
                    '${entry.effectiveDate.year}',
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}