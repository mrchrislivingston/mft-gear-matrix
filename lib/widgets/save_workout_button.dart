import 'package:flutter/material.dart';

class SaveWorkoutButton extends StatelessWidget {
  final VoidCallback onPressed;

  const SaveWorkoutButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        child: const Text('Save Workout'),
      ),
    );
  }
}