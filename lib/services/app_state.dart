import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../data/default_matrix.dart';
import '../models/gear.dart';
import '../models/gear_target.dart';
import '../models/log_entry.dart';
import '../models/modality.dart';
import '../models/target_history.dart';

class AppState {
  AppState._();

  static final AppState instance = AppState._();

  static const String _logsKey = 'workout_logs';
  static const String _targetsKey = 'matrix_targets';

  final List<LogEntry> logs = [];
  final List<Gear> gears = buildDefaultMatrix();

  Future<void> loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final rawLogs = prefs.getStringList(_logsKey) ?? [];

    print('Loaded raw logs found: ${rawLogs.length}');

    logs
      ..clear()
      ..addAll(
        rawLogs.map((rawLog) {
          final json = jsonDecode(rawLog) as Map<String, dynamic>;
          return LogEntry.fromJson(json);
        }),
      );

    await loadGears();
  }

  Future<void> loadGears() async {
    final prefs = await SharedPreferences.getInstance();
    final rawGears = prefs.getStringList(_targetsKey);

    if (rawGears == null || rawGears.isEmpty) {
      gears
        ..clear()
        ..addAll(buildDefaultMatrix());
      return;
    }

    gears
      ..clear()
      ..addAll(
        rawGears.map((rawGear) {
          final json = jsonDecode(rawGear) as Map<String, dynamic>;
          return Gear.fromJson(json);
        }),
      );
  }

  Future<void> addLog(LogEntry log) async {
    logs.add(log);
    await _saveLogs();
  }

  Future<void> updateTarget({
    required int gearNumber,
    required Modality modality,
    required String lowTarget,
    required String highTarget,
  }) async {
    final gearIndex = gears.indexWhere(
      (gear) => gear.number == gearNumber,
    );

    if (gearIndex == -1) {
      return;
    }

    final gear = gears[gearIndex];
    final existingTarget = gear.targetForModality(modality);

    final newHistoryItem = TargetHistory(
      lowTarget: lowTarget,
      highTarget: highTarget,
      effectiveDate: DateTime.now(),
    );

    late final GearTarget updatedTarget;
    late final List<GearTarget> updatedTargets;

    if (existingTarget == null) {
      updatedTarget = GearTarget(
        modality: modality,
        metric: modality.defaultMetric,
        history: [
          newHistoryItem,
        ],
      );

      updatedTargets = [
        ...gear.targets,
        updatedTarget,
      ];
    } else {
      updatedTarget = existingTarget.copyWith(
        history: [
          ...existingTarget.history,
          newHistoryItem,
        ],
      );

      updatedTargets = gear.targets.map((target) {
        if (target.modality == existingTarget.modality &&
            target.metric == existingTarget.metric) {
          return updatedTarget;
        }

        return target;
      }).toList();
    }

    gears[gearIndex] = gear.copyWith(
      targets: updatedTargets,
    );

    await _saveGears();
  }

  Future<void> updateRunPaceTarget({
    required int gearNumber,
    required String lowTarget,
    required String highTarget,
  }) {
    return updateTarget(
      gearNumber: gearNumber,
      modality: Modality.run,
      lowTarget: lowTarget,
      highTarget: highTarget,
    );
  }

  Future<void> _saveLogs() async {
    final prefs = await SharedPreferences.getInstance();

    final rawLogs = logs.map((log) {
      return jsonEncode(log.toJson());
    }).toList();

    print('Saving ${logs.length} logs');

    await prefs.setStringList(_logsKey, rawLogs);

    final savedLogs = prefs.getStringList(_logsKey) ?? [];

    print('Saved logs found: ${savedLogs.length}');
  }

  Future<void> _saveGears() async {
    final prefs = await SharedPreferences.getInstance();

    final rawGears = gears.map((gear) {
      return jsonEncode(gear.toJson());
    }).toList();

    await prefs.setStringList(_targetsKey, rawGears);
  }
}