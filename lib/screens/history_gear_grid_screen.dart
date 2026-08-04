import 'package:flutter/material.dart';

import '../models/modality.dart';
import '../models/training_stimulus.dart';
import '../services/app_state.dart';
import '../widgets/gear_card.dart';
import 'gear_history_screen.dart';
import 'history_screen.dart';

class HistoryGearGridScreen extends StatelessWidget {
  final Modality modality;

  const HistoryGearGridScreen({
    super.key,
    required this.modality,
  });

  int _gearWorkoutCount(int gearNumber) {
    return AppState.instance.logs
        .where(
          (log) =>
              log.modality == modality &&
              log.gearNumber == gearNumber,
        )
        .length;
  }

  DateTime? _latestGearWorkoutDate(int gearNumber) {
    final matchingLogs = AppState.instance.logs
        .where(
          (log) =>
              log.modality == modality &&
              log.gearNumber == gearNumber,
        )
        .toList();

    if (matchingLogs.isEmpty) {
      return null;
    }

    matchingLogs.sort(
      (a, b) => b.date.compareTo(a.date),
    );

    return matchingLogs.first.date;
  }

  int _prescriptionWorkoutCount(
    String prescriptionId,
  ) {
    return AppState.instance.logs
        .where(
          (log) =>
              log.modality == modality &&
              log.prescriptionId == prescriptionId,
        )
        .length;
  }

  String _workoutCountText(int count) {
    return count == 1 ? '1 workout' : '$count workouts';
  }

  String _latestWorkoutText(DateTime? date) {
    if (date == null) {
      return 'No workouts yet';
    }

    return 'Last: ${date.month}/${date.day}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final gears = AppState.instance.gears;

    final powerPrescriptions = AppState.instance.prescriptions
        .where(
          (prescription) =>
              prescription.stimulus ==
              TrainingStimulus.power,
        )
        .toList();

    final aerobicPrescriptions = AppState.instance.prescriptions
        .where(
          (prescription) =>
              prescription.stimulus ==
              TrainingStimulus.belowThreshold,
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text('${modality.displayName} History'),
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
            'Gears',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),

          for (int index = 0;
              index < gears.length;
              index++) ...[
            GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => GearHistoryScreen(
                      gear: gears[index],
                      modality: modality,
                    ),
                  ),
                );
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GearCard(
                    gear: gears[index],
                  ),
                  const SizedBox(height: 4),
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      _workoutCountText(
                        _gearWorkoutCount(
                          gears[index].number,
                        ),
                      ),
                      style:
                          Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      _latestWorkoutText(
                        _latestGearWorkoutDate(
                          gears[index].number,
                        ),
                      ),
                      style:
                          Theme.of(context).textTheme.bodySmall,
                    ),
                  ),
                ],
              ),
            ),
            if (index < gears.length - 1)
              const SizedBox(height: 10),
          ],

          const SizedBox(height: 30),

          Text(
            'Power',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),

          for (int index = 0;
              index < powerPrescriptions.length;
              index++) ...[
            Card(
              child: ListTile(
                title: Text(
                  powerPrescriptions[index].name,
                ),
                subtitle: Text(
                  '${powerPrescriptions[index].prescriptionDisplayForModality(modality)}\n'
                  '${_workoutCountText(
                    _prescriptionWorkoutCount(
                      powerPrescriptions[index].id,
                    ),
                  )}',
                ),
                isThreeLine: true,
                trailing:
                    const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HistoryScreen(
                        prescription:
                            powerPrescriptions[index],
                        modality: modality,
                      ),
                    ),
                  );
                },
              ),
            ),
            if (index < powerPrescriptions.length - 1)
              const SizedBox(height: 10),
          ],

          const SizedBox(height: 30),

          Text(
            'Aerobic',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 12),

          for (int index = 0;
              index < aerobicPrescriptions.length;
              index++) ...[
            Card(
              child: ListTile(
                title: Text(
                  aerobicPrescriptions[index].name,
                ),
                subtitle: Text(
                  '${aerobicPrescriptions[index].prescriptionDisplayForModality(modality)}\n'
                  '${_workoutCountText(
                    _prescriptionWorkoutCount(
                      aerobicPrescriptions[index].id,
                    ),
                  )}',
                ),
                isThreeLine: true,
                trailing:
                    const Icon(Icons.chevron_right),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => HistoryScreen(
                        prescription:
                            aerobicPrescriptions[index],
                        modality: modality,
                      ),
                    ),
                  );
                },
              ),
            ),
            if (index <
                aerobicPrescriptions.length - 1)
              const SizedBox(height: 10),
          ],
        ],
      ),
    );
  }
}