import 'package:flutter/material.dart';

class ContinuousWorkoutCard extends StatelessWidget {
  final String duration;

  const ContinuousWorkoutCard({
    super.key,
    required this.duration,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Continuous Workout',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Duration',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            Text(
              duration,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ],
        ),
      ),
    );
  }
}