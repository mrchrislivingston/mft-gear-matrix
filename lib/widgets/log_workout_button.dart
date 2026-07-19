import 'package:flutter/material.dart';

class LogWorkoutButton extends StatelessWidget {
  final VoidCallback onPressed;

  const LogWorkoutButton({
    super.key,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: onPressed,
        child: const Text('Log Workout'),
      ),
    );
  }
}