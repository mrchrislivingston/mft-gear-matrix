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
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GearDetailScreen(
          prescription: prescription,
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
        prescription.prescriptionDisplayForModality(
      modality,
    );

    return Card(
      child: ListTile(
        onTap: () {
          _openPrescription(
            context,
            prescription,
          );
        },
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

  Widget _buildSection(
    BuildContext context, {
    required String title,
    required List<Prescription> prescriptions,
  }) {
    if (prescriptions.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 10),
        ...prescriptions.map(
          (prescription) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: _buildPrescriptionCard(
              context,
              prescription,
            ),
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final prescriptions = AppState.instance.prescriptions;

    final gears = prescriptions
        .whereType<Gear>()
        .cast<Prescription>()
        .toList();

    final powerPrescriptions = prescriptions
        .where(
          (prescription) =>
              prescription.id.startsWith('P'),
        )
        .toList();

    final aerobicPrescriptions = prescriptions
        .where(
          (prescription) =>
              prescription.id.startsWith('Z'),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('$title Matrix'),
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
          _buildSection(
            context,
            title: 'Gears',
            prescriptions: gears,
          ),
          _buildSection(
            context,
            title: 'Power',
            prescriptions: powerPrescriptions,
          ),
          _buildSection(
            context,
            title: 'Aerobic',
            prescriptions: aerobicPrescriptions,
          ),
        ],
      ),
    );
  }
}