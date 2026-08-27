import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../data/default_benchmarks.dart';
import '../data/default_matrix.dart';
import '../models/benchmark.dart';
import '../models/gear.dart';
import '../models/gear_target.dart';
import '../models/log_entry.dart';
import '../models/modality.dart';
import '../models/target_history.dart';
import 'database_service.dart';

class AppState {
  AppState._();

  static final AppState instance = AppState._();

  static const String _logsKey = 'workout_logs';
  static const String _targetsKey = 'matrix_targets';

  /// Separate storage for non-Gear prescription targets.
  ///
  /// Keeping this separate preserves compatibility with existing Gear saves.
  static const String _prescriptionTargetsKey = 'prescription_targets';

  final List<LogEntry> logs = [];

  final List<Benchmark> benchmarks = buildDefaultBenchmarks();
  final List<Gear> gears = buildDefaultMatrix();

  final List<Prescription> nonGearPrescriptions = buildDefaultPrescriptions()
      .where((prescription) => prescription is! Gear)
      .toList();

  /// Returns the complete matrix in its defined default order.
  ///
  /// G1–G8 come from the persisted Gear list.
  /// P1–P4 and Z1–Z2 come from the persisted non-Gear list.
  List<Prescription> get prescriptions {
    final defaults = buildDefaultPrescriptions();

    return defaults.map((defaultPrescription) {
      if (defaultPrescription is Gear) {
        final index = gears.indexWhere(
          (gear) => gear.number == defaultPrescription.number,
        );

        if (index == -1) {
          return defaultPrescription;
        }

        return gears[index];
      }

      final index = nonGearPrescriptions.indexWhere(
        (prescription) => prescription.id == defaultPrescription.id,
      );

      if (index == -1) {
        return defaultPrescription;
      }

      return nonGearPrescriptions[index];
    }).toList();
  }

  Future<void> loadLogs() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final rawLogs = prefs.getStringList(_logsKey) ?? [];

      debugPrint(
        'Workout read source: shared_preferences '
        '(${rawLogs.length} workouts)',
      );

      logs
        ..clear()
        ..addAll(
          rawLogs.map((rawLog) {
            final json = jsonDecode(rawLog) as Map<String, dynamic>;

            return LogEntry.fromJson(json);
          }),
        );
    } else {
      final sqliteWorkouts = await DatabaseService.instance.getWorkouts();

      logs
        ..clear()
        ..addAll(sqliteWorkouts);

      debugPrint(
        'Workout read source: SQLite '
        '(${logs.length} workouts)',
      );

      for (final benchmark in benchmarks) {
        await DatabaseService.instance.upsertBenchmark(benchmark);
      }
    }

    await loadGears();
    await loadNonGearPrescriptions();
  }

  Future<void> loadGears() async {
    final prefs = await SharedPreferences.getInstance();
    final rawGears = prefs.getStringList(_targetsKey);

    final defaultGears = buildDefaultMatrix();

    if (kIsWeb) {
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
        final savedIndex = savedGears.indexWhere(
          (gear) => gear.number == defaultGear.number,
        );

        if (savedIndex == -1) {
          return defaultGear;
        }

        final savedGear = savedGears[savedIndex];

        final mergedTargets = _mergeTargets(
          defaultTargets: defaultGear.targets,
          savedTargets: savedGear.targets,
        );

        return defaultGear.copyWith(targets: mergedTargets);
      }).toList();

      gears
        ..clear()
        ..addAll(mergedGears);

      debugPrint('Gear target read source: shared_preferences');

      return;
    }

    final migrationGears = <Gear>[];

    if (rawGears == null || rawGears.isEmpty) {
      migrationGears.addAll(defaultGears);
    } else {
      final savedGears = rawGears.map((rawGear) {
        final json = jsonDecode(rawGear) as Map<String, dynamic>;

        return Gear.fromJson(json);
      }).toList();

      migrationGears.addAll(
        defaultGears.map((defaultGear) {
          final savedIndex = savedGears.indexWhere(
            (gear) => gear.number == defaultGear.number,
          );

          if (savedIndex == -1) {
            return defaultGear;
          }

          final savedGear = savedGears[savedIndex];

          final mergedTargets = _mergeTargets(
            defaultTargets: defaultGear.targets,
            savedTargets: savedGear.targets,
          );

          return defaultGear.copyWith(targets: mergedTargets);
        }),
      );
    }

    await _migratePrescriptionTargetsToSqlite(migrationGears);

    final sqliteGears = <Gear>[];

    for (final defaultGear in defaultGears) {
      final savedTargets = await DatabaseService.instance
          .getTargetsForPrescription(defaultGear.id);

      final mergedTargets = _mergeTargets(
        defaultTargets: defaultGear.targets,
        savedTargets: savedTargets,
      );

      sqliteGears.add(defaultGear.copyWith(targets: mergedTargets));
    }

    gears
      ..clear()
      ..addAll(sqliteGears);

    debugPrint('Gear target read source: SQLite');
  }

  Future<void> loadNonGearPrescriptions() async {
    final prefs = await SharedPreferences.getInstance();

    final rawPrescriptions = prefs.getStringList(_prescriptionTargetsKey);

    final defaults = buildDefaultPrescriptions()
        .where((prescription) => prescription is! Gear)
        .toList();

    if (kIsWeb) {
      if (rawPrescriptions == null || rawPrescriptions.isEmpty) {
        nonGearPrescriptions
          ..clear()
          ..addAll(defaults);

        return;
      }

      final savedPrescriptions = rawPrescriptions.map((rawPrescription) {
        final json = jsonDecode(rawPrescription) as Map<String, dynamic>;

        return Prescription.fromJson(json);
      }).toList();

      final mergedPrescriptions = defaults.map((defaultPrescription) {
        final savedIndex = savedPrescriptions.indexWhere(
          (prescription) => prescription.id == defaultPrescription.id,
        );

        if (savedIndex == -1) {
          return defaultPrescription;
        }

        final savedPrescription = savedPrescriptions[savedIndex];

        final mergedTargets = _mergeTargets(
          defaultTargets: defaultPrescription.targets,
          savedTargets: savedPrescription.targets,
        );

        return defaultPrescription.copyWith(targets: mergedTargets);
      }).toList();

      nonGearPrescriptions
        ..clear()
        ..addAll(mergedPrescriptions);

      debugPrint('Non-Gear target read source: shared_preferences');

      return;
    }

    final migrationPrescriptions = <Prescription>[];

    if (rawPrescriptions == null || rawPrescriptions.isEmpty) {
      migrationPrescriptions.addAll(defaults);
    } else {
      final savedPrescriptions = rawPrescriptions.map((rawPrescription) {
        final json = jsonDecode(rawPrescription) as Map<String, dynamic>;

        return Prescription.fromJson(json);
      }).toList();

      migrationPrescriptions.addAll(
        defaults.map((defaultPrescription) {
          final savedIndex = savedPrescriptions.indexWhere(
            (prescription) => prescription.id == defaultPrescription.id,
          );

          if (savedIndex == -1) {
            return defaultPrescription;
          }

          final savedPrescription = savedPrescriptions[savedIndex];

          final mergedTargets = _mergeTargets(
            defaultTargets: defaultPrescription.targets,
            savedTargets: savedPrescription.targets,
          );

          return defaultPrescription.copyWith(targets: mergedTargets);
        }),
      );
    }

    await _migratePrescriptionTargetsToSqlite(migrationPrescriptions);

    final sqlitePrescriptions = <Prescription>[];

    for (final defaultPrescription in defaults) {
      final savedTargets = await DatabaseService.instance
          .getTargetsForPrescription(defaultPrescription.id);

      final mergedTargets = _mergeTargets(
        defaultTargets: defaultPrescription.targets,
        savedTargets: savedTargets,
      );

      sqlitePrescriptions.add(
        defaultPrescription.copyWith(targets: mergedTargets),
      );
    }

    nonGearPrescriptions
      ..clear()
      ..addAll(sqlitePrescriptions);

    debugPrint('Non-Gear target read source: SQLite');
  }

  Future<void> _migratePrescriptionTargetsToSqlite(
    Iterable<Prescription> prescriptions,
  ) async {
    if (kIsWeb) {
      return;
    }

    var insertedCount = 0;

    for (final prescription in prescriptions) {
      for (final target in prescription.targets) {
        for (final historyItem in target.history) {
          final inserted = await DatabaseService.instance
              .insertTargetHistoryIfAbsent(
                prescriptionId: prescription.id,
                modality: target.modality,
                metric: target.metric,
                target: historyItem,
              );

          if (inserted) {
            insertedCount++;
          }
        }
      }
    }

    debugPrint(
      'Target migration to SQLite: '
      '$insertedCount new history records',
    );
  }

  List<GearTarget> _mergeTargets({
    required List<GearTarget> defaultTargets,
    required List<GearTarget> savedTargets,
  }) {
    final mergedTargets = defaultTargets.map((defaultTarget) {
      final savedIndex = savedTargets.indexWhere(
        (savedTarget) =>
            savedTarget.modality == defaultTarget.modality &&
            savedTarget.metric == defaultTarget.metric,
      );

      if (savedIndex == -1) {
        return defaultTarget;
      }

      return savedTargets[savedIndex];
    }).toList();

    for (final savedTarget in savedTargets) {
      final alreadyIncluded = mergedTargets.any(
        (target) =>
            target.modality == savedTarget.modality &&
            target.metric == savedTarget.metric,
      );

      if (!alreadyIncluded) {
        mergedTargets.add(savedTarget);
      }
    }

    return mergedTargets;
  }

  Future<void> addLog(LogEntry log) async {
    logs.add(log);

    try {
      if (kIsWeb) {
        await _saveLogs();
      } else {
        await DatabaseService.instance.insertWorkout(log);
      }
    } catch (_) {
      logs.remove(log);

      if (kIsWeb) {
        await _saveLogs();
      }

      rethrow;
    }
  }

  /// Generic target update used by every prescription type.
  Future<void> updatePrescriptionTarget({
    required String prescriptionId,
    required Modality modality,
    required String lowTarget,
    required String highTarget,
  }) async {
    final gearIndex = gears.indexWhere((gear) => gear.id == prescriptionId);

    if (gearIndex != -1) {
      final gear = gears[gearIndex];

      final updatedTargets = await _buildUpdatedTargets(
        prescription: gear,
        modality: modality,
        lowTarget: lowTarget,
        highTarget: highTarget,
      );

      gears[gearIndex] = gear.copyWith(targets: updatedTargets);

      if (kIsWeb) {
        await _saveGears();
      }

      return;
    }

    final prescriptionIndex = nonGearPrescriptions.indexWhere(
      (prescription) => prescription.id == prescriptionId,
    );

    if (prescriptionIndex == -1) {
      return;
    }

    final prescription = nonGearPrescriptions[prescriptionIndex];

    final updatedTargets = await _buildUpdatedTargets(
      prescription: prescription,
      modality: modality,
      lowTarget: lowTarget,
      highTarget: highTarget,
    );

    nonGearPrescriptions[prescriptionIndex] = prescription.copyWith(
      targets: updatedTargets,
    );

    if (kIsWeb) {
      await _saveNonGearPrescriptions();
    }
  }

  Future<List<GearTarget>> _buildUpdatedTargets({
    required Prescription prescription,
    required Modality modality,
    required String lowTarget,
    required String highTarget,
  }) async {
    final existingTarget = prescription.targetForModality(modality);

    final metric = existingTarget?.metric ?? modality.defaultMetric;

    final newHistoryItem = TargetHistory(
      lowTarget: lowTarget,
      highTarget: highTarget,
      effectiveDate: DateTime.now(),
    );

    if (!kIsWeb) {
      await DatabaseService.instance.insertTargetHistory(
        prescriptionId: prescription.id,
        modality: modality,
        metric: metric,
        target: newHistoryItem,
      );
    }

    if (existingTarget == null) {
      final newTarget = GearTarget(
        modality: modality,
        metric: metric,
        history: [newHistoryItem],
      );

      return [...prescription.targets, newTarget];
    }

    final updatedTarget = existingTarget.copyWith(
      history: [...existingTarget.history, newHistoryItem],
    );

    return prescription.targets.map((target) {
      if (target.modality == existingTarget.modality &&
          target.metric == existingTarget.metric) {
        return updatedTarget;
      }

      return target;
    }).toList();
  }

  /// Compatibility method used by the existing Gear screens.
  ///
  /// This can be removed after all screens use prescription IDs.
  Future<void> updateTarget({
    required int gearNumber,
    required Modality modality,
    required String lowTarget,
    required String highTarget,
  }) {
    return updatePrescriptionTarget(
      prescriptionId: 'G$gearNumber',
      modality: modality,
      lowTarget: lowTarget,
      highTarget: highTarget,
    );
  }

  Future<void> updateRunPaceTarget({
    required int gearNumber,
    required String lowTarget,
    required String highTarget,
  }) {
    return updatePrescriptionTarget(
      prescriptionId: 'G$gearNumber',
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

    debugPrint('Saving ${logs.length} logs');

    await prefs.setStringList(_logsKey, rawLogs);

    final savedLogs = prefs.getStringList(_logsKey) ?? [];

    debugPrint('Saved logs found: ${savedLogs.length}');
  }

  Future<void> _saveGears() async {
    final prefs = await SharedPreferences.getInstance();

    final rawGears = gears.map((gear) {
      return jsonEncode(gear.toJson());
    }).toList();

    await prefs.setStringList(_targetsKey, rawGears);
  }

  Future<void> _saveNonGearPrescriptions() async {
    final prefs = await SharedPreferences.getInstance();

    final rawPrescriptions = nonGearPrescriptions.map((prescription) {
      return jsonEncode(prescription.toJson());
    }).toList();

    await prefs.setStringList(_prescriptionTargetsKey, rawPrescriptions);
  }
}
