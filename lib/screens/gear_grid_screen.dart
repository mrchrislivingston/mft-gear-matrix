import 'package:flutter/material.dart';

import '../models/gear.dart';
import '../models/modality.dart';
import '../services/app_state.dart';
import '../widgets/gear_card.dart';
import 'gear_detail_screen.dart';

class GearGridScreen extends StatelessWidget {
  final Modality modality;

  const GearGridScreen({
    super.key,
    required this.modality,
  });

  String get title {
    switch (modality) {
      case Modality.run:
        return 'Run';
      case Modality.row:
        return 'Row';
      case Modality.ski:
        return 'SkiErg';
      case Modality.bikeErg:
        return 'C2 Bike';
      case Modality.echo:
        return 'Echo Bike';
    }
  }

  void _openPrescription(
    BuildContext context,
    Prescription prescription,
  ) {
    // Existing detail and logging screens still require a Gear.
    if (prescription is! Gear) {
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GearDetailScreen(
          gear: prescription,
          modality: modality,
        ),
      ),
    );
  }

  Widget _buildPrescriptionCard(
    BuildContext context,
    Prescription prescription,
  ) {
    if (prescription is Gear) {
      return GestureDetector(
        onTap: () {
          _openPrescription(
            context,
            prescription,
          );
        },
        child: GearCard(
          gear: prescription,
        ),
      );
    }

    final description =
        prescription.prescriptionDisplayForModality(modality);

    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 6,
        ),
        title: Text(
          prescription.name,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            description,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prescriptions = AppState.instance.prescriptions;

    return Scaffold(
      appBar: AppBar(
        title: Text('$title Matrix'),
        actions: [
          IconButton(
            icon: const Icon(Icons.home),
            onPressed: () {
              Navigator.of(context).popUntil((route) => route.isFirst);
            },
          ),
        ],
      ),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: prescriptions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final prescription = prescriptions[index];

          return _buildPrescriptionCard(
            context,
            prescription,
          );
        },
      ),
    );
  }
}