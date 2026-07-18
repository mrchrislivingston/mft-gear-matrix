import 'package:flutter/material.dart';

import '../models/gear.dart';
import '../models/modality.dart';
import '../services/app_state.dart';

class TargetManagerScreen extends StatefulWidget {
  final Prescription prescription;
  final Modality modality;

  const TargetManagerScreen({
    super.key,
    required this.prescription,
    required this.modality,
  });

  @override
  State<TargetManagerScreen> createState() =>
      _TargetManagerScreenState();
}

class _TargetManagerScreenState
    extends State<TargetManagerScreen> {
  late final TextEditingController lowTargetController;
  late final TextEditingController highTargetController;

  @override
  void initState() {
    super.initState();

    final target = widget.prescription.targetForModality(
      widget.modality,
    );

    final currentTarget = target?.currentTarget;

    lowTargetController = TextEditingController(
      text: currentTarget?.lowTarget ?? '',
    );

    highTargetController = TextEditingController(
      text: currentTarget?.highTarget ?? '',
    );
  }

  @override
  void dispose() {
    lowTargetController.dispose();
    highTargetController.dispose();
    super.dispose();
  }

  int? _timeToSeconds(String value) {
    final parts = value.trim().split(':');

    if (parts.length != 2) return null;

    final minutes = int.tryParse(parts[0]);
    final seconds = int.tryParse(parts[1]);

    if (minutes == null || seconds == null) {
      return null;
    }

    if (seconds < 0 || seconds > 59) {
      return null;
    }

    return (minutes * 60) + seconds;
  }

  String? _validateTargetValue(
    String value,
    bool usesTimeFormat,
  ) {
    if (value.isEmpty) {
      return 'Enter both a low target and a high target.';
    }

    if (usesTimeFormat) {
      final regex = RegExp(r'^\d{1,2}:\d{2}$');

      if (!regex.hasMatch(value) ||
          _timeToSeconds(value) == null) {
        return 'Use a pace format such as 2:05.';
      }

      return null;
    }

    final number = double.tryParse(value);

    if (number == null || number <= 0) {
      return 'Enter a valid number greater than zero.';
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final target = widget.prescription.targetForModality(
      widget.modality,
    );

    final currentTarget = target?.currentTarget;
    final metric = target?.metric;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit ${widget.modality.displayName} '
          '${widget.prescription.name} Target',
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
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          Text(
            currentTarget == null
                ? 'No target currently set'
                : 'Current target: '
                    '${currentTarget.displayTarget} '
                    '${metric?.unitLabel ?? ''}',
          ),
          const SizedBox(height: 12),
          Text(
            metric == null
                ? 'Primary metric'
                : '${metric.displayName} '
                    '(${metric.unitLabel})',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          TextField(
            controller: lowTargetController,
            keyboardType: metric?.usesTimeFormat == true
                ? TextInputType.text
                : const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
            decoration: InputDecoration(
              labelText: 'Low Target',
              helperText: metric?.usesTimeFormat == true
                  ? 'Example: 2:05'
                  : metric?.unitLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: highTargetController,
            keyboardType: metric?.usesTimeFormat == true
                ? TextInputType.text
                : const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
            decoration: InputDecoration(
              labelText: 'High Target',
              helperText: metric?.usesTimeFormat == true
                  ? 'Example: 2:10'
                  : metric?.unitLabel,
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () async {
              final lowTarget =
                  lowTargetController.text.trim();

              final highTarget =
                  highTargetController.text.trim();

              final usesTimeFormat =
                  metric?.usesTimeFormat == true;

              final lowError = _validateTargetValue(
                lowTarget,
                usesTimeFormat,
              );

              final highError = _validateTargetValue(
                highTarget,
                usesTimeFormat,
              );

              final errorMessage = lowError ?? highError;

              if (errorMessage != null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(errorMessage),
                  ),
                );

                return;
              }

              await AppState.instance
                  .updatePrescriptionTarget(
                prescriptionId: widget.prescription.id,
                modality: widget.modality,
                lowTarget: lowTarget,
                highTarget: highTarget,
              );

              if (mounted) {
                Navigator.pop(context);
              }
            },
            child: Text(
              currentTarget == null
                  ? 'Create Target'
                  : 'Save Target',
            ),
          ),
        ],
      ),
    );
  }
}