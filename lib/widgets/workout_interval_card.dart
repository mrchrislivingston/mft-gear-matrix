import 'package:flutter/material.dart';

import '../models/workout_metric.dart';

class WorkoutIntervalCard extends StatelessWidget {
  final int intervalNumber;
  final bool showTitle;

  /// Only used for continuous (Z1/Z2) workouts.
  final TextEditingController? durationController;

  final List<WorkoutMetric> workoutMetrics;
  final Map<WorkoutMetric, TextEditingController> controllers;

  final String Function(WorkoutMetric metric) labelForMetric;
  final String? Function(WorkoutMetric metric) helperTextForMetric;
  final TextInputType Function(WorkoutMetric metric) keyboardTypeForMetric;
  final String? Function(
    WorkoutMetric metric,
    String? value,
  ) validateMetric;

  const WorkoutIntervalCard({
    super.key,
    required this.intervalNumber,
    this.showTitle = true,
    this.durationController,
    required this.workoutMetrics,
    required this.controllers,
    required this.labelForMetric,
    required this.helperTextForMetric,
    required this.keyboardTypeForMetric,
    required this.validateMetric,
  });

  String? _validateDuration(String? value) {
    final text = value?.trim() ?? '';

    if (text.isEmpty) {
      return 'Duration required';
    }

    final match = RegExp(
      r'^(\d+):([0-5]\d)$',
    ).firstMatch(text);

    if (match == null) {
      return 'Use minutes:seconds, for example 47:32';
    }

    final minutes = int.tryParse(match.group(1) ?? '');
    final seconds = int.tryParse(match.group(2) ?? '');

    if (minutes == null || seconds == null) {
      return 'Invalid duration';
    }

    if (minutes == 0 && seconds == 0) {
      return 'Duration must be greater than zero';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (showTitle) ...[
              Text(
                'Interval $intervalNumber',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
            ],
            if (durationController != null) ...[
              TextFormField(
                controller: durationController,
                validator: _validateDuration,
                keyboardType: TextInputType.datetime,
                decoration: const InputDecoration(
                  labelText: 'Duration',
                  hintText: 'e.g. 47:32',
                  helperText: 'Minutes:seconds',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
            ],
            for (int metricIndex = 0;
                metricIndex < workoutMetrics.length;
                metricIndex++) ...[
              _buildMetricField(
                workoutMetrics[metricIndex],
              ),
              if (metricIndex < workoutMetrics.length - 1)
                const SizedBox(height: 10),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricField(
    WorkoutMetric workoutMetric,
  ) {
    return TextFormField(
      controller: controllers[workoutMetric],
      validator: (value) {
        return validateMetric(
          workoutMetric,
          value,
        );
      },
      keyboardType: keyboardTypeForMetric(
        workoutMetric,
      ),
      decoration: InputDecoration(
        labelText: labelForMetric(
          workoutMetric,
        ),
        helperText: helperTextForMetric(
          workoutMetric,
        ),
        border: const OutlineInputBorder(),
      ),
    );
  }
}