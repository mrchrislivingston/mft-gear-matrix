import 'package:flutter/material.dart';

import '../models/gear.dart';
import '../models/log_entry.dart';
import '../models/modality.dart';
import '../models/workout_metric.dart';
import '../services/app_state.dart';
import 'workout_summary_screen.dart';
import '../widgets/workout_interval_card.dart';
import '../models/training_stimulus.dart';
import '../widgets/continuous_workout_card.dart';
import '../widgets/prescription_header.dart';
import '../widgets/workout_notes.dart';
import '../widgets/log_workout_button.dart';
import '../widgets/save_workout_button.dart';
import '../widgets/workout_entry_section.dart';

class LogWorkoutScreen extends StatefulWidget {
  final Prescription prescription;
  final Modality modality;

  const LogWorkoutScreen({
    super.key,
    required this.prescription,
    required this.modality,
  });


  @override
  State<LogWorkoutScreen> createState() => _LogWorkoutScreenState();
}

class _LogWorkoutScreenState extends State<LogWorkoutScreen> {
final formKey = GlobalKey<FormState>();

late final List<Map<WorkoutMetric, TextEditingController>>
    intervalControllers;

final durationController = TextEditingController();

final notesController = TextEditingController();

  @override
  void initState() {
    super.initState();

    intervalControllers = List.generate(
      widget.prescription.intervals,
      (_) {
        return {
          for (final metric in widget.modality.workoutMetrics)
            metric: TextEditingController(),
        };
      },
    );
  }

  @override
  void dispose() {
    for (final controllers in intervalControllers) {
      for (final controller in controllers.values) {
        controller.dispose();
      }
    }

    durationController.dispose();
    notesController.dispose();

    super.dispose();
  }

  int? _paceToSeconds(String value) {
    final parts = value.trim().split(':');

    if (parts.length != 2) return null;

    final minutes = int.tryParse(parts[0]);
    final seconds = int.tryParse(parts[1]);

    if (minutes == null || seconds == null) return null;
    if (minutes < 0 || seconds < 0 || seconds > 59) return null;

    return (minutes * 60) + seconds;
  }

  String _secondsToPace(int seconds) {
    final minutes = seconds ~/ 60;
    final remainingSeconds = seconds % 60;

    return '$minutes:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Gear? get _gear {
    final prescription = widget.prescription;

    if (prescription is Gear) {
      return prescription;
    }

    return null;
  }

  String get _prescriptionLabel {
    final gear = _gear;

    if (gear != null) {
      return 'Gear ${gear.number}';
    }

    return widget.prescription.id;
  }

  String _labelForMetric(WorkoutMetric workoutMetric) {
    final target = widget.prescription.targetForModality(widget.modality);

    switch (workoutMetric) {
      case WorkoutMetric.distance:
        switch (widget.modality) {
          case Modality.run:
            return 'Distance (miles)';
          case Modality.row:
          case Modality.ski:
          case Modality.bikeErg:
            return 'Distance (meters)';
          case Modality.echo:
            return 'Distance';
        }

      case WorkoutMetric.primaryMetric:
        final metric = target?.metric;

        if (metric == null) {
          return 'Primary Metric';
        }

        return '${metric.displayName} (${metric.unitLabel})';

      case WorkoutMetric.watts:
        return 'Watts';

      case WorkoutMetric.calories:
        return 'Calories';

      case WorkoutMetric.caloriesPerHour:
        return 'Calories Per Hour';

      case WorkoutMetric.rpm:
        return 'RPM';

      case WorkoutMetric.strokeRate:
        return 'Stroke Rate';

      case WorkoutMetric.heartRate:
        return 'Avg HR';

      case WorkoutMetric.rpe:
        return 'RPE';
    }
  }

  String? _helperTextForMetric(WorkoutMetric workoutMetric) {
    switch (workoutMetric) {
      case WorkoutMetric.primaryMetric:
        return 'Target: '
            '${widget.prescription.targetDisplayForModality(widget.modality)}';

      case WorkoutMetric.strokeRate:
        return 'Strokes per minute';

      case WorkoutMetric.caloriesPerHour:
        return 'cal/hr';

      case WorkoutMetric.distance:
      case WorkoutMetric.watts:
      case WorkoutMetric.calories:
      case WorkoutMetric.rpm:
      case WorkoutMetric.heartRate:
      case WorkoutMetric.rpe:
        return null;
    }
  }

  TextInputType _keyboardTypeForMetric(
    WorkoutMetric workoutMetric,
  ) {
    final target = widget.prescription.targetForModality(widget.modality);

    if (workoutMetric == WorkoutMetric.primaryMetric &&
        target?.metric.usesTimeFormat == true) {
      return TextInputType.text;
    }

    return const TextInputType.numberWithOptions(
      decimal: true,
    );
  }

  String? _validateMetric(
    WorkoutMetric workoutMetric,
    String? value,
  ) {
    final text = value?.trim() ?? '';
    final target = widget.prescription.targetForModality(widget.modality);

    if (workoutMetric == WorkoutMetric.primaryMetric) {
      if (text.isEmpty) {
        return '${target?.metric.displayName ?? 'Primary metric'} required';
      }

      if (target?.metric.usesTimeFormat == true) {
        final regex = RegExp(r'^\d{1,2}:\d{2}$');

        if (!regex.hasMatch(text)) {
          return 'Use m:ss or mm:ss';
        }

        if (_paceToSeconds(text) == null) {
          return 'Invalid pace';
        }

        return null;
      }

      final number = double.tryParse(text);

      if (number == null) {
        return 'Enter a number';
      }

      if (number <= 0) {
        return 'Check value';
      }

      return null;
    }

    // Secondary metrics are optional.
    if (text.isEmpty) {
      return null;
    }

    final number = double.tryParse(text);

    if (number == null) {
      return 'Enter a number';
    }

    if (number < 0) {
      return 'Check value';
    }

    switch (workoutMetric) {
      case WorkoutMetric.heartRate:
        if (number < 30 || number > 240) {
          return 'Check HR';
        }

      case WorkoutMetric.rpe:
        if (number < 1 || number > 10) {
          return 'RPE must be 1-10';
        }

      case WorkoutMetric.rpm:
      case WorkoutMetric.watts:
      case WorkoutMetric.calories:
      case WorkoutMetric.caloriesPerHour:
      case WorkoutMetric.strokeRate:
      case WorkoutMetric.distance:
      case WorkoutMetric.primaryMetric:
        break;
    }

    return null;
  }

  List<String> _primaryMetricValues() {
    return intervalControllers
        .map(
          (controllers) =>
              controllers[WorkoutMetric.primaryMetric]
                  ?.text
                  .trim() ??
              '',
        )
        .where((value) => value.isNotEmpty)
        .toList();
  }

  ({String lowTarget, String highTarget})?
      _calculateInitialTarget() {
    final target = widget.prescription.targetForModality(widget.modality);
    final values = _primaryMetricValues();

    if (target == null || values.isEmpty) {
      return null;
    }

    if (target.metric.usesTimeFormat) {
      final valuesInSeconds = values
          .map(_paceToSeconds)
          .whereType<int>()
          .toList();

      if (valuesInSeconds.isEmpty) {
        return null;
      }

      valuesInSeconds.sort();

      return (
        lowTarget: _secondsToPace(valuesInSeconds.first),
        highTarget: _secondsToPace(valuesInSeconds.last),
      );
    }

    final numericValues = values
        .map(double.tryParse)
        .whereType<double>()
        .toList();

    if (numericValues.isEmpty) {
      return null;
    }

    numericValues.sort();

    String formatNumber(double value) {
      if (value == value.roundToDouble()) {
        return value.toInt().toString();
      }

      return value.toString();
    }

    return (
      lowTarget: formatNumber(numericValues.first),
      highTarget: formatNumber(numericValues.last),
    );
  }

  bool _primaryMetricIsOutsideTarget(String value) {
    final target = widget.prescription.targetForModality(widget.modality);
    final currentTarget = target?.currentTarget;

    if (target == null || currentTarget == null) {
      return false;
    }

    if (target.metric.usesTimeFormat) {
      final actualSeconds = _paceToSeconds(value);
      final lowSeconds = _paceToSeconds(currentTarget.lowTarget);
      final highSeconds = _paceToSeconds(currentTarget.highTarget);

      if (actualSeconds == null ||
          lowSeconds == null ||
          highSeconds == null) {
        return false;
      }

      return actualSeconds < lowSeconds ||
          actualSeconds > highSeconds;
    }

    final actualValue = double.tryParse(value);
    final lowValue = double.tryParse(currentTarget.lowTarget);
    final highValue = double.tryParse(currentTarget.highTarget);

    if (actualValue == null ||
        lowValue == null ||
        highValue == null) {
      return false;
    }

    return actualValue < lowValue || actualValue > highValue;
  }

  Future<bool> _confirmInitialTarget({
    required String lowTarget,
    required String highTarget,
  }) async {
    final target = widget.prescription.targetForModality(widget.modality);
    final unit = target?.metric.unitLabel ?? '';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Create initial target?'),
          content: Text(
            'No target exists for '
            '${widget.modality.displayName} '
            '$_prescriptionLabel.\n\n'
            'This workout will become your initial target.\n\n'
            'Target:\n'
            '$lowTarget–$highTarget'
            '${unit.isEmpty ? '' : ' $unit'}\n\n'
            'You can edit this target later.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Review'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Save Workout'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<bool> _confirmOutsideTarget() async {
    final outsideValues = <String>[];
    final target = widget.prescription.targetForModality(widget.modality);

    for (int index = 0;
        index < intervalControllers.length;
        index++) {
      final controller = intervalControllers[index]
          [WorkoutMetric.primaryMetric];

      final value = controller?.text.trim() ?? '';

      if (_primaryMetricIsOutsideTarget(value)) {
        outsideValues.add(
          'Interval ${index + 1}: $value',
        );
      }
    }

    if (outsideValues.isEmpty) {
      return true;
    }

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(
            '${target?.metric.displayName ?? 'Value'} outside target',
          ),
          content: Text(
            'Target: ${target?.displayTarget ?? 'No target'} '
            '${target?.metric.unitLabel ?? ''}\n\n'
            'The following intervals are outside target:\n\n'
            '${outsideValues.join('\n')}\n\n'
            'Save anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: const Text('Review'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Save Anyway'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  List<IntervalResult> _buildIntervals() {
    return List.generate(
      widget.prescription.intervals,
      (index) {
        final controllers = intervalControllers[index];
        final values = <WorkoutMetric, String>{};

        for (final entry in controllers.entries) {
          final value = entry.value.text.trim();

          if (value.isNotEmpty) {
            values[entry.key] = value;
          }
        }

        return IntervalResult(
          intervalNumber: index + 1,
          values: values,
        );
      },
    );
  }

  Future<void> _saveLog() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final target = widget.prescription.targetForModality(widget.modality);
final hasCurrentTarget = target?.currentTarget != null;

final usesTargetWorkflow =
    widget.prescription.stimulus != TrainingStimulus.belowThreshold;

String? initialLowTarget;
String? initialHighTarget;

if (usesTargetWorkflow) {
  if (!hasCurrentTarget) {
    final suggestedTarget = _calculateInitialTarget();

    if (suggestedTarget == null) {
      return;
    }

    final confirmed = await _confirmInitialTarget(
      lowTarget: suggestedTarget.lowTarget,
      highTarget: suggestedTarget.highTarget,
    );

    if (!confirmed) {
      return;
    }

    initialLowTarget = suggestedTarget.lowTarget;
    initialHighTarget = suggestedTarget.highTarget;
  } else {
    final confirmed = await _confirmOutsideTarget();

    if (!confirmed) {
      return;
    }
  }
}

    final intervals = _buildIntervals();

  final log = LogEntry.forPrescription(
  prescriptionId: widget.prescription.id,
  modality: widget.modality,
  date: DateTime.now(),
  duration: durationController.text.trim(),
  notes: notesController.text.trim(),
  intervals: intervals,
);

    final gear = _gear;

    if (initialLowTarget != null &&
        initialHighTarget != null &&
        gear != null) {
      await AppState.instance.updateTarget(
        gearNumber: gear.number,
        modality: widget.modality,
        lowTarget: initialLowTarget,
        highTarget: initialHighTarget,
      );
    }

    await AppState.instance.addLog(log);

    if (!mounted) {
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutSummaryScreen(
          log: log,
        ),
      ),
    );
  }

  @override
Widget build(BuildContext context) {
  final prescription = widget.prescription;
  final target = prescription.targetForModality(widget.modality);
  final metric = target?.metric;

  return Scaffold(
    appBar: AppBar(
      title: Text(
        'Log ${widget.modality.displayName} $_prescriptionLabel',
      ),
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
    body: Form(
      key: formKey,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
WorkoutEntrySection(
  stimulus: prescription.stimulus,
  intervals: prescription.intervals,
  durationRange: prescription.durationRange,
  prescriptionDetails: prescription.prescriptionDisplayForModality(
    widget.modality,
  ),
  targetText:
      'Target: '
      '${prescription.targetDisplayForModality(widget.modality)}'
      '${metric == null ? '' : ' ${metric.unitLabel}'}',
  workoutMetrics: widget.modality.workoutMetrics,
  intervalControllers: intervalControllers,
  durationController: durationController,
  labelForMetric: _labelForMetric,
  helperTextForMetric: _helperTextForMetric,
  keyboardTypeForMetric: _keyboardTypeForMetric,
  validateMetric: _validateMetric,
),
          const SizedBox(height: 20),
WorkoutNotes(
  controller: notesController,
),
          SaveWorkoutButton(
  onPressed: _saveLog,
),
        ],
      ),
    ),
  );
}
}