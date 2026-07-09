import 'package:flutter/material.dart';

import '../models/gear.dart';
import '../models/log_entry.dart';
import '../services/app_state.dart';
import 'workout_summary_screen.dart';

class LogWorkoutScreen extends StatefulWidget {
  final Gear gear;

  const LogWorkoutScreen({
    super.key,
    required this.gear,
  });

  @override
  State<LogWorkoutScreen> createState() => _LogWorkoutScreenState();
}

class _LogWorkoutScreenState extends State<LogWorkoutScreen> {
  final formKey = GlobalKey<FormState>();

  late final List<TextEditingController> distanceControllers;
  late final List<TextEditingController> paceControllers;
  late final List<TextEditingController> hrControllers;
  late final List<TextEditingController> rpeControllers;
  final notesController = TextEditingController();

  @override
  void initState() {
    super.initState();

    distanceControllers = List.generate(
      widget.gear.intervals,
      (_) => TextEditingController(),
    );

    paceControllers = List.generate(
      widget.gear.intervals,
      (_) => TextEditingController(),
    );

    hrControllers = List.generate(
      widget.gear.intervals,
      (_) => TextEditingController(),
    );

    rpeControllers = List.generate(
      widget.gear.intervals,
      (_) => TextEditingController(),
    );
  }

  @override
  void dispose() {
    for (final controller in distanceControllers) {
      controller.dispose();
    }
    for (final controller in paceControllers) {
      controller.dispose();
    }
    for (final controller in hrControllers) {
      controller.dispose();
    }
    for (final controller in rpeControllers) {
      controller.dispose();
    }

    notesController.dispose();
    super.dispose();
  }

  String? validateDistance(String? value) {
    final text = value?.trim() ?? '';
    final number = double.tryParse(text);

    if (text.isEmpty) return 'Distance required';
    if (number == null) return 'Enter a number';
    if (number <= 0 || number > 5) return 'Check distance';

    return null;
  }

  int? paceToSeconds(String value) {
    final parts = value.trim().split(':');
    if (parts.length != 2) return null;

    final minutes = int.tryParse(parts[0]);
    final seconds = int.tryParse(parts[1]);

    if (minutes == null || seconds == null) return null;
    if (seconds < 0 || seconds > 59) return null;

    return (minutes * 60) + seconds;
  }

  String? validatePace(String? value) {
    final text = value?.trim() ?? '';
    final regex = RegExp(r'^\d{1,2}:\d{2}$');

    if (text.isEmpty) return 'Pace required';
    if (!regex.hasMatch(text)) return 'Use m:ss or mm:ss';
    if (paceToSeconds(text) == null) return 'Invalid pace';

    return null;
  }

  String? validateHr(String? value) {
    final text = value?.trim() ?? '';
    final number = int.tryParse(text);

    if (text.isEmpty) return 'HR required';
    if (number == null) return 'Enter a number';
    if (number < 30 || number > 240) return 'Check HR';

    return null;
  }

  String? validateRpe(String? value) {
    final text = value?.trim() ?? '';
    final number = double.tryParse(text);

    if (text.isEmpty) return 'RPE required';
    if (number == null) return 'Enter a number';
    if (number < 1 || number > 10) return 'RPE must be 1-10';

    return null;
  }

bool paceIsOutsideTarget(String pace) {
  final actualSeconds = paceToSeconds(pace);
  final runTarget = widget.gear.runPaceTarget?.currentTarget;

  final lowSeconds = paceToSeconds(runTarget?.lowTarget ?? '');
  final highSeconds = paceToSeconds(runTarget?.highTarget ?? '');

  if (actualSeconds == null || lowSeconds == null || highSeconds == null) {
    return false;
  }

    return actualSeconds < lowSeconds || actualSeconds > highSeconds;
  }

  Future<bool> confirmOutsideTarget() async {
    final outsidePaces = <String>[];

    for (int index = 0; index < paceControllers.length; index++) {
      final pace = paceControllers[index].text.trim();

      if (paceIsOutsideTarget(pace)) {
        outsidePaces.add('Interval ${index + 1}: $pace');
      }
    }

    if (outsidePaces.isEmpty) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Pace outside target'),
          content: Text(
            'Target pace: ${widget.gear.targetPaceDisplay} / mile\n\n'
            'The following intervals are outside target:\n\n'
            '${outsidePaces.join('\n')}\n\n'
            'Save anyway?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Review'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Save Anyway'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  Future<void> saveLog() async {
    if (!formKey.currentState!.validate()) {
      return;
    }

    final confirmed = await confirmOutsideTarget();
    if (!confirmed) return;

    final intervals = List.generate(widget.gear.intervals, (index) {
      return IntervalResult(
        intervalNumber: index + 1,
        distance: distanceControllers[index].text.trim(),
        avgPace: paceControllers[index].text.trim(),
        avgHr: hrControllers[index].text.trim(),
        rpe: rpeControllers[index].text.trim(),
      );
    });

    final log = LogEntry(
      gearNumber: widget.gear.number,
      date: DateTime.now(),
      notes: notesController.text.trim(),
      intervals: intervals,
    );

    await AppState.instance.addLog(log);

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => WorkoutSummaryScreen(log: log),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final gear = widget.gear;

    return Scaffold(
      appBar: AppBar(
  title: Text('Log Gear ${gear.number}'),
  actions: [
    IconButton(
      icon: const Icon(Icons.home),
      onPressed: () {
        Navigator.of(context).popUntil((route) => route.isFirst);
      },
    ),
  ],
),
      body: Form(
        key: formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Text('Prescription', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 10),
            Text('Work: ${gear.work}'),
            Text('Rest: ${gear.rest}'),
            Text('Intervals: ${gear.intervals}'),
            const SizedBox(height: 10),
            Text('Target Pace: ${gear.targetPaceDisplay} / mile'),
            const SizedBox(height: 30),
            for (int index = 0; index < gear.intervals; index++) ...[
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Interval ${index + 1}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: distanceControllers[index],
                        validator: validateDistance,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Distance (miles)',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: paceControllers[index],
                        validator: validatePace,
                        decoration: InputDecoration(
                          labelText: 'Avg Pace (min/mile)',
                          helperText: 'Target: ${gear.targetPaceDisplay}',
                          border: const OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: hrControllers[index],
                        validator: validateHr,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Avg HR',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextFormField(
                        controller: rpeControllers[index],
                        validator: validateRpe,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'RPE',
                          border: OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 20),
            TextField(
              controller: notesController,
              maxLines: 4,
              decoration: const InputDecoration(
                labelText: 'Notes',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 30),
            ElevatedButton(
              onPressed: saveLog,
              child: const Text('Save Workout'),
            ),
          ],
        ),
      ),
    );
  }
}