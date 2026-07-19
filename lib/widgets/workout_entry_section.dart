import 'package:flutter/material.dart';

import '../models/training_stimulus.dart';
import '../models/workout_metric.dart';
import 'prescription_header.dart';
import 'workout_interval_card.dart';

class WorkoutEntrySection extends StatelessWidget {
  final TrainingStimulus stimulus;
  final int intervals;
  final String? durationRange;

  final String prescriptionDetails;
  final String targetText;

  final TextEditingController durationController;

  final List<WorkoutMetric> workoutMetrics;

  final List<Map<WorkoutMetric, TextEditingController>> intervalControllers;

  final String Function(WorkoutMetric) labelForMetric;
  final String? Function(WorkoutMetric) helperTextForMetric;
  final TextInputType Function(WorkoutMetric) keyboardTypeForMetric;
  final String? Function(WorkoutMetric, String?) validateMetric;

  const WorkoutEntrySection({
    super.key,
    required this.stimulus,
    required this.intervals,
    required this.durationRange,
    required this.prescriptionDetails,
    required this.targetText,
    required this.durationController,
    required this.workoutMetrics,
    required this.intervalControllers,
    required this.labelForMetric,
    required this.helperTextForMetric,
    required this.keyboardTypeForMetric,
    required this.validateMetric,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PrescriptionHeader(
          title: 'Prescription',
          details: prescriptionDetails,
          target: targetText,
        ),

        if (stimulus == TrainingStimulus.belowThreshold &&
            durationRange != null)
          WorkoutIntervalCard(
            intervalNumber: 1,
            showTitle: false,
            durationController: durationController,
            workoutMetrics: workoutMetrics,
            controllers: intervalControllers.first,
            labelForMetric: labelForMetric,
            helperTextForMetric: helperTextForMetric,
            keyboardTypeForMetric: keyboardTypeForMetric,
            validateMetric: validateMetric,
          )
        else
          for (int intervalIndex = 0;
              intervalIndex < intervals;
              intervalIndex++) ...[
            WorkoutIntervalCard(
              intervalNumber: intervalIndex + 1,
              showTitle: true,
              workoutMetrics: workoutMetrics,
              controllers: intervalControllers[intervalIndex],
              labelForMetric: labelForMetric,
              helperTextForMetric: helperTextForMetric,
              keyboardTypeForMetric: keyboardTypeForMetric,
              validateMetric: validateMetric,
            ),
            const SizedBox(height: 12),
          ],
      ],
    );
  }
}