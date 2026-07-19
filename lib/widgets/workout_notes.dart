import 'package:flutter/material.dart';

class WorkoutNotes extends StatelessWidget {
  final TextEditingController controller;

  const WorkoutNotes({
    super.key,
    required this.controller,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(
            labelText: 'Notes',
            border: OutlineInputBorder(),
          ),
        ),
        const SizedBox(height: 30),
      ],
    );
  }
}