import 'package:sqflite/sqflite.dart';

import '../data/assault_runner_targets.dart';

/// Inserts only missing modality/metric histories; never replaces user targets.
/// The transaction makes retries safe and keeps the eight entries together.
Future<int> importAssaultRunnerTargets(Database database) async {
  return database.transaction((transaction) async {
    var imported = 0;
    for (final prescriptionId in assaultRunnerBenchmarks.keys) {
      for (final target in assaultRunnerTargets(prescriptionId)) {
        final existing = await transaction.query(
          'target_history',
          columns: ['id'],
          where: 'prescription_id = ? AND modality = ? AND metric = ?',
          whereArgs: [prescriptionId, target.modality.name, target.metric.name],
          limit: 1,
        );
        if (existing.isNotEmpty) continue;
        final entry = target.currentTarget!;
        await transaction.insert('target_history', {
          'prescription_id': prescriptionId,
          'modality': target.modality.name,
          'metric': target.metric.name,
          'low_target': entry.lowTarget,
          'high_target': entry.highTarget,
          'effective_date': entry.effectiveDate.toIso8601String(),
        });
        imported++;
      }
    }
    return imported;
  });
}
