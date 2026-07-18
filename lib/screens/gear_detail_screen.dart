import 'package:flutter/material.dart';

import '../models/gear.dart';
import '../models/modality.dart';
import '../models/training_stimulus.dart';
import '../services/app_state.dart';
import 'gear_history_screen.dart';
import 'history_screen.dart';
import 'log_workout_screen.dart';
import 'target_history_screen.dart';
import 'target_manager_screen.dart';

class GearDetailScreen extends StatefulWidget {
  final Prescription prescription;
  final Modality modality;

  const GearDetailScreen({
    super.key,
    required this.prescription,
    required this.modality,
  });

  @override
  State<GearDetailScreen> createState() =>
      _GearDetailScreenState();
}

class _GearDetailScreenState extends State<GearDetailScreen> {
  String _prescriptionTypeLabel(
    Prescription prescription,
  ) {
    switch (prescription.stimulus) {
      case TrainingStimulus.aerobic:
        return 'Aerobic';

      case TrainingStimulus.belowThreshold:
        return 'Below Threshold';

      case TrainingStimulus.anaerobic:
        return 'Anaerobic';

      case TrainingStimulus.power:
        return 'Power';
    }
  }

  Widget _buildDetailLine(
    BuildContext context, {
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(label),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPowerProtocol(
    BuildContext context, {
    required String title,
    required PrescriptionProtocol protocol,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Text(
              'Every ${protocol.every}',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 4),
            Text('${protocol.rounds} rounds'),
            const SizedBox(height: 12),
            _buildDetailLine(
              context,
              label: 'Work',
              value: 'AMRAP ${protocol.amrap}',
            ),
            _buildDetailLine(
              context,
              label: 'Recovery',
              value: 'Recover in remaining time',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionDetails(
    BuildContext context,
    Prescription prescription,
  ) {
    if (prescription is Gear) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _prescriptionTypeLabel(prescription),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          _buildDetailLine(
            context,
            label: 'Work',
            value: prescription.work,
          ),
          _buildDetailLine(
            context,
            label: 'Rest',
            value: prescription.rest,
          ),
          _buildDetailLine(
            context,
            label: 'Intervals',
            value: prescription.intervals.toString(),
          ),
        ],
      );
    }

    if (prescription.stimulus == TrainingStimulus.power) {
      final continuousProtocol =
          prescription.protocolForModality(
        Modality.bikeErg,
      );

      final skiRowProtocol =
          prescription.protocolForModality(
        Modality.row,
      );

      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Power',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          if (continuousProtocol != null)
            _buildPowerProtocol(
              context,
              title: 'Continuous Machines',
              protocol: continuousProtocol,
            ),
          if (skiRowProtocol != null)
            _buildPowerProtocol(
              context,
              title: 'Ski / Row',
              protocol: skiRowProtocol,
            ),
        ],
      );
    }

    if (prescription.durationRange != null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _prescriptionTypeLabel(prescription),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          Text(
            prescription.durationRange!,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 12),
          const Text('Continuous effort'),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _prescriptionTypeLabel(prescription),
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Text(
          prescription.prescriptionDisplayForModality(
            widget.modality,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentPrescription =
        AppState.instance.prescriptions.firstWhere(
      (item) => item.id == widget.prescription.id,
    );

    final target = currentPrescription.targetForModality(
      widget.modality,
    );

    final gear = currentPrescription is Gear
        ? currentPrescription
        : null;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          '${widget.modality.displayName} '
          '${currentPrescription.name}',
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
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            '${widget.modality.displayName} '
            '${currentPrescription.name}',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 24),
          _buildPrescriptionDetails(
            context,
            currentPrescription,
          ),
          const SizedBox(height: 30),
          Text(
            '${widget.modality.displayName} Target',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          Text(
            target?.displayTarget ?? 'No target',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          if (target != null) ...[
            const SizedBox(height: 4),
            Text(target.metric.unitLabel),
          ],
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TargetManagerScreen(
                    prescription: currentPrescription,
                    modality: widget.modality,
                  ),
                ),
              );

              if (mounted) {
                setState(() {});
              }
            },
            child: Text(
              target?.hasTarget == true
                  ? 'Edit Target'
                  : 'Create Target',
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => TargetHistoryScreen(
                    prescription: currentPrescription,
                    modality: widget.modality,
                  ),
                ),
              );
            },
            child: const Text('View Target History'),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => LogWorkoutScreen(
                    prescription: currentPrescription,
                    modality: widget.modality,
                  ),
                ),
              );
            },
            child: const Text('Log Workout'),
          ),
          const SizedBox(height: 10),
          OutlinedButton(
            onPressed: () {
              if (gear != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GearHistoryScreen(
                      gear: gear,
                      modality: widget.modality,
                    ),
                  ),
                );

                return;
              }

              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => HistoryScreen(
                    prescription: currentPrescription,
                    modality: widget.modality,
                  ),
                ),
              );
            },
            child: const Text('View Workout History'),
          ),
        ],
      ),
    );
  }
}