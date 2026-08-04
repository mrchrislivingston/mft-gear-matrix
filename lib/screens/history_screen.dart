import 'package:flutter/material.dart';

import '../models/gear.dart';
import '../models/modality.dart';
import '../services/app_state.dart';
import 'history_gear_grid_screen.dart';
import 'workout_summary_screen.dart';

class HistoryScreen extends StatelessWidget {
  final Prescription? prescription;
  final Modality? modality;

  const HistoryScreen({
    super.key,
    this.prescription,
    this.modality,
  });

  void _openModality(
    BuildContext context,
    Modality selectedModality,
  ) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => HistoryGearGridScreen(
          modality: selectedModality,
        ),
      ),
    );
  }

  int _workoutCount(Modality selectedModality) {
    return AppState.instance.logs
        .where(
          (log) => log.modality == selectedModality,
        )
        .length;
  }

  Widget _buildModalityTile(
    BuildContext context,
    Modality selectedModality,
  ) {
    final workoutCount = _workoutCount(selectedModality);

    return ListTile(
      title: Text(selectedModality.displayName),
      subtitle: Text(
        workoutCount == 1
            ? '1 workout'
            : '$workoutCount workouts',
      ),
      trailing: const Icon(Icons.chevron_right),
      onTap: () {
        _openModality(
          context,
          selectedModality,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedPrescription = prescription;
    final selectedModality = modality;

    if (selectedPrescription != null &&
        selectedModality != null) {
      final logs = AppState.instance.logs
          .where(
            (log) =>
                log.prescriptionId ==
                    selectedPrescription.id &&
                log.modality == selectedModality,
          )
          .toList()
        ..sort(
          (a, b) => b.date.compareTo(a.date),
        );

      return Scaffold(
        appBar: AppBar(
          title: Text(
            '${selectedModality.displayName} '
            '${selectedPrescription.name} History',
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
        body: logs.isEmpty
            ? const Center(
                child: Text('No workouts logged yet.'),
              )
            : ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: logs.length,
                separatorBuilder: (_, _) =>
                    const SizedBox(height: 8),
                itemBuilder: (context, index) {
                  final log = logs[index];

                  return Card(
                    child: ListTile(
                      title: Text(
                        '${log.date.month}/'
                        '${log.date.day}/'
                        '${log.date.year}',
                      ),
                      subtitle: log.notes.isEmpty
                          ? null
                          : Text(
                              log.notes,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                      trailing:
                          const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                WorkoutSummaryScreen(
                              log: log,
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('History'),
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
          _buildModalityTile(
            context,
            Modality.run,
          ),
          const Divider(),
          _buildModalityTile(
            context,
            Modality.echo,
          ),
          const Divider(),
          _buildModalityTile(
            context,
            Modality.bikeErg,
          ),
          const Divider(),
          _buildModalityTile(
            context,
            Modality.row,
          ),
          const Divider(),
          _buildModalityTile(
            context,
            Modality.ski,
          ),
        ],
      ),
    );
  }
}