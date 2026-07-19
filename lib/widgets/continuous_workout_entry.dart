import 'package:flutter/material.dart';

class ContinuousWorkoutEntry extends StatelessWidget {
  final TextEditingController durationController;

  const ContinuousWorkoutEntry({
    super.key,
    required this.durationController,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Duration',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: durationController,
          keyboardType: TextInputType.text,
          decoration: const InputDecoration(
            hintText: 'e.g. 47:32',
            border: OutlineInputBorder(),
          ),
        ),
      ],
    );
  }
}