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

  /// Returns the complete matrix while preserving any saved Gear targets.
  ///
  /// Z1, Z2, and P1–P3 come from the default prescription list.
  /// G1–G8 come from the current persisted Gear list.
  List<Prescription> get prescriptions {
    final defaults = buildDefaultPrescriptions();

    return defaults.map((prescription) {
      if (prescription is! Gear) {
        return prescription;
      }

      return gears.firstWhere(
        (gear) => gear.number == prescription.number,
        orElse: () => prescription,
      );
    }).toList();
  }

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

    final defaultGears = buildDefaultMatrix();

    if (rawGears == null || rawGears.isEmpty) {
      gears
        ..clear()
        ..addAll(defaultGears);

      return;
    }

    final savedGears = rawGears.map((rawGear) {
      final json = jsonDecode(rawGear) as Map<String, dynamic>;
      return Gear.fromJson(json);
    }).toList();

    final mergedGears = defaultGears.map((defaultGear) {
      final savedGear = savedGears.cast<Gear?>().firstWhere(
            (gear) => gear?.number == defaultGear.number,
            orElse: () => null,
          );

      if (savedGear == null) {
        return defaultGear;
      }

      final mergedTargets = defaultGear.targets.map((defaultTarget) {
        final savedTarget = savedGear.targets.cast<GearTarget?>().firstWhere(
              (target) =>
                  target?.modality == defaultTarget.modality &&
                  target?.metric == defaultTarget.metric,
              orElse: () => null,
            );

        return savedTarget ?? defaultTarget;
      }).toList();

      for (final savedTarget in savedGear.targets) {
        final alreadyIncluded = mergedTargets.any(
          (target) =>
              target.modality == savedTarget.modality &&
              target.metric == savedTarget.metric,
        );

        if (!alreadyIncluded) {
          mergedTargets.add(savedTarget);
        }
      }

      return defaultGear.copyWith(
        targets: mergedTargets,
      );
    }).toList();

    gears
      ..clear()
      ..addAll(mergedGears);
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