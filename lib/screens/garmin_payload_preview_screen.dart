import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/fitr_workout_classifier.dart';
import '../services/garmin_workout_builder.dart';

class GarminPayloadPreviewScreen extends StatefulWidget {
  final List<FitrWorkoutCandidate> candidates;
  final GarminGearTargetResolver? gearTargetResolver;
  final GarminWorkoutBuilder builder;

  const GarminPayloadPreviewScreen({
    super.key,
    required this.candidates,
    this.gearTargetResolver,
    this.builder = const GarminWorkoutBuilder(),
  });

  @override
  State<GarminPayloadPreviewScreen> createState() {
    return _GarminPayloadPreviewScreenState();
  }
}

class _GarminPayloadPreviewScreenState
    extends State<GarminPayloadPreviewScreen> {
  final _ageController = TextEditingController();

  List<_BuiltPayload> _payloads = const [];
  String? _errorMessage;

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  void _hideKeyboard() {
    FocusManager.instance.primaryFocus?.unfocus();
  }

  void _buildPayloads() {
    _hideKeyboard();

    final age = int.tryParse(_ageController.text.trim());

    if (age == null || age < 1 || age > 119) {
      setState(() {
        _payloads = const [];
        _errorMessage = 'Enter the athlete’s current age from 1 through 119.';
      });
      return;
    }

    try {
      final payloads = widget.candidates
          .map((candidate) {
            return _BuiltPayload(
              candidate: candidate,
              payload: widget.builder.buildCandidate(
                candidate,
                age: age,
                gearTargetResolver: widget.gearTargetResolver,
              ),
            );
          })
          .toList(growable: false);

      setState(() {
        _payloads = payloads;
        _errorMessage = null;
      });
    } catch (error) {
      setState(() {
        _payloads = const [];
        _errorMessage = error.toString();
      });
    }
  }

  List<Map<String, dynamic>> _steps(Map<String, dynamic> payload) {
    final segments = payload['workoutSegments'];

    if (segments is! List) {
      return const [];
    }

    final steps = <Map<String, dynamic>>[];

    for (final segment in segments) {
      if (segment is! Map) {
        continue;
      }

      final rawSteps = segment['workoutSteps'];

      if (rawSteps is! List) {
        continue;
      }

      for (final rawStep in rawSteps) {
        if (rawStep is Map) {
          steps.add(Map<String, dynamic>.from(rawStep));
        }
      }
    }

    return steps;
  }

  int _stepCount(Map<String, dynamic> payload) {
    return _steps(payload).length;
  }

  num _totalDuration(Map<String, dynamic> payload) {
    final estimated = payload['estimatedDurationInSecs'];

    if (estimated is num) {
      return estimated;
    }

    return _steps(payload).fold<num>(
      0,
      (total, step) => total + ((step['endConditionValue'] as num?) ?? 0),
    );
  }

  String _formatDuration(num seconds) {
    final rounded = seconds.round();
    final minutes = rounded ~/ 60;
    final remaining = rounded % 60;

    return '$minutes:${remaining.toString().padLeft(2, '0')}';
  }

  String _sportName(Map<String, dynamic> payload) {
    final sportType = payload['sportType'];

    if (sportType is! Map) {
      return 'Unknown sport';
    }

    return switch (sportType['sportTypeKey']) {
      'running' => 'Running',
      'cycling' => 'Cycling',
      'fitness_equipment' => 'Fitness equipment',
      'cardio_training' => 'Cardio',
      _ => sportType['sportTypeKey']?.toString() ?? 'Unknown sport',
    };
  }

  String _stepName(Map<String, dynamic> step) {
    final stepType = step['stepType'];

    if (stepType is! Map) {
      return 'Interval';
    }

    return switch (stepType['stepTypeId']) {
      1 => 'Warm-up',
      2 => 'Cool-down',
      3 => 'Work',
      4 => 'Recovery',
      _ => 'Interval',
    };
  }

  String _targetSummary(Map<String, dynamic> step) {
    final description = step['description']?.toString().trim() ?? '';
    final targetType = step['targetType'];

    if (targetType is! Map) {
      return description.isEmpty ? 'No target' : description;
    }

    final key = targetType['workoutTargetTypeKey']?.toString();

    if (key == 'no.target') {
      if (description.isNotEmpty) {
        return '$description • description only';
      }

      return 'No structured target';
    }

    if (key == 'heart.rate.zone') {
      final low = step['targetValueOne'];
      final high = step['targetValueTwo'];

      return 'Heart rate: $low–$high bpm';
    }

    if (description.isNotEmpty) {
      return description;
    }

    final low = step['targetValueOne'];
    final high = step['targetValueTwo'];

    if (key == 'pace.zone') {
      return 'Garmin pace target: $low–$high';
    }

    if (key == 'speed.zone') {
      return 'Garmin speed target: $low–$high';
    }

    return 'Target: $low–$high';
  }

  String _prettyJson(Map<String, dynamic> payload) {
    return const JsonEncoder.withIndent('  ').convert(payload);
  }

  Widget _payloadDetails(_BuiltPayload built) {
    final steps = _steps(built.payload);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            Chip(label: Text(_sportName(built.payload))),
            Chip(
              label: Text(
                'Total ${_formatDuration(_totalDuration(built.payload))}',
              ),
            ),
            Chip(label: Text('${steps.length} steps')),
          ],
        ),
        const SizedBox(height: 12),
        for (var index = 0; index < steps.length; index++) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Step ${index + 1} • ${_stepName(steps[index])}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                const SizedBox(height: 4),
                Text(
                  'Duration: '
                  '${_formatDuration((steps[index]['endConditionValue'] as num?) ?? 0)}',
                ),
                Text(_targetSummary(steps[index])),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        ExpansionTile(
          key: Key('garminTechnicalJson-${built.candidate.id}'),
          tilePadding: EdgeInsets.zero,
          title: const Text('Technical JSON'),
          subtitle: const Text('Raw Garmin payload for troubleshooting'),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: SelectableText(
                _prettyJson(built.payload),
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _hideKeyboard,
      behavior: HitTestBehavior.translucent,
      child: Scaffold(
        appBar: AppBar(title: const Text('Garmin Payload Preview')),
        body: ListView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              color: Theme.of(context).colorScheme.secondaryContainer,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'Preview only. These payloads are built locally on this '
                  'phone. Nothing on Garmin will be created, scheduled, '
                  'changed, or deleted.',
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              '${widget.candidates.length} selected workout'
              '${widget.candidates.length == 1 ? '' : 's'}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            TextField(
              key: const Key('garminPayloadAgeField'),
              controller: _ageController,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(
                labelText: 'Athlete’s current age',
                helperText:
                    'Used to calculate this athlete’s Zone 2 heart-rate targets.',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _buildPayloads(),
              onTapOutside: (_) => _hideKeyboard(),
            ),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                key: const Key('garminHideKeyboardButton'),
                onPressed: _hideKeyboard,
                icon: const Icon(Icons.keyboard_hide),
                label: const Text('Hide keyboard'),
              ),
            ),
            FilledButton.icon(
              key: const Key('garminBuildPayloadPreviewButton'),
              onPressed: widget.candidates.isEmpty ? null : _buildPayloads,
              icon: const Icon(Icons.build_outlined),
              label: const Text('Build payload preview'),
            ),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Card(
                color: Theme.of(context).colorScheme.errorContainer,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    _errorMessage!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ),
            ],
            if (_payloads.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text(
                'Built payloads',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 8),
              for (final built in _payloads)
                Card(
                  child: ExpansionTile(
                    key: Key('garminPayload-${built.candidate.id}'),
                    title: Text(
                      built.payload['workoutName']?.toString() ??
                          built.candidate.displayName,
                    ),
                    subtitle: Text(
                      '${built.candidate.type} • '
                      '${_stepCount(built.payload)} Garmin steps',
                    ),
                    childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                    children: [_payloadDetails(built)],
                  ),
                ),
              const SizedBox(height: 12),
              Card(
                color: Theme.of(context).colorScheme.secondaryContainer,
                child: const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Payload construction succeeded. Upload and scheduling '
                    'remain intentionally disabled.',
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _BuiltPayload {
  final FitrWorkoutCandidate candidate;
  final Map<String, dynamic> payload;

  const _BuiltPayload({required this.candidate, required this.payload});
}
