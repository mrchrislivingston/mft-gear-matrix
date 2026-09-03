import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/gear_target.dart';
import '../models/log_entry.dart';
import '../models/metric.dart';
import '../models/modality.dart';
import '../models/target_history.dart';
import '../models/workout_metric.dart';
import '../models/benchmark.dart';
import '../models/benchmark_attempt.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  static const String _databaseName = 'mft_gear_matrix.db';
  static const int _databaseVersion = 4;

  Database? _database;

  Future<Database> get database async {
    final existingDatabase = _database;

    if (existingDatabase != null) {
      return existingDatabase;
    }

    final openedDatabase = await _openDatabase();
    _database = openedDatabase;

    return openedDatabase;
  }

  Future<Database> _openDatabase() async {
    final databaseDirectory = await getDatabasesPath();

    final databasePath = join(databaseDirectory, _databaseName);

    return openDatabase(
      databasePath,
      version: _databaseVersion,
      onConfigure: (database) async {
        await database.execute('PRAGMA foreign_keys = ON');
      },
      onCreate: (database, version) async {
        await _createTables(database);
      },
      onUpgrade: (database, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await database.execute('''
            ALTER TABLE workouts
            ADD COLUMN work_duration TEXT NOT NULL DEFAULT ''
          ''');

          await database.execute('''
            ALTER TABLE workouts
            ADD COLUMN interval_count INTEGER NOT NULL DEFAULT 0
          ''');
        }

        if (oldVersion < 3) {
          await database.execute('''
            ALTER TABLE workouts
            ADD COLUMN source_workbook TEXT NOT NULL DEFAULT ''
          ''');

          await database.execute('''
            ALTER TABLE workouts
            ADD COLUMN program_day TEXT NOT NULL DEFAULT ''
          ''');
        }

        if (oldVersion < 4) {
          await _createBenchmarkTables(database);
        }
      },
    );
  }

  Future<void> _createTables(Database database) async {
    await database.execute('''
      CREATE TABLE workouts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        prescription_id TEXT NOT NULL,
        modality TEXT NOT NULL,
        workout_date TEXT NOT NULL,
        source_workbook TEXT NOT NULL DEFAULT '',
        program_day TEXT NOT NULL DEFAULT '',
        duration TEXT NOT NULL DEFAULT '',
        work_duration TEXT NOT NULL DEFAULT '',
        interval_count INTEGER NOT NULL DEFAULT 0,
        scoring_metric TEXT,
        notes TEXT NOT NULL DEFAULT ''
      )
    ''');

    await database.execute('''
      CREATE TABLE workout_intervals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        workout_id INTEGER NOT NULL,
        interval_number INTEGER NOT NULL,
        FOREIGN KEY (workout_id)
          REFERENCES workouts (id)
          ON DELETE CASCADE
      )
    ''');

    await database.execute('''
      CREATE TABLE interval_metrics (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        interval_id INTEGER NOT NULL,
        metric TEXT NOT NULL,
        value TEXT NOT NULL,
        FOREIGN KEY (interval_id)
          REFERENCES workout_intervals (id)
          ON DELETE CASCADE
      )
    ''');

    await database.execute('''
      CREATE TABLE target_history (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        prescription_id TEXT NOT NULL,
        modality TEXT NOT NULL,
        metric TEXT NOT NULL,
        low_target TEXT NOT NULL,
        high_target TEXT NOT NULL,
        effective_date TEXT NOT NULL
      )
    ''');

    await database.execute('''
      CREATE INDEX index_workouts_prescription
      ON workouts (prescription_id)
    ''');

    await database.execute('''
      CREATE INDEX index_workouts_date
      ON workouts (workout_date)
    ''');

    await database.execute('''
      CREATE INDEX index_intervals_workout
      ON workout_intervals (workout_id)
    ''');

    await database.execute('''
      CREATE INDEX index_metrics_interval
      ON interval_metrics (interval_id)
    ''');

    await database.execute('''
      CREATE INDEX index_target_history_lookup
      ON target_history (
        prescription_id,
        modality,
        metric,
        effective_date
      )
    ''');

    await _createBenchmarkTables(database);
  }

  Future<void> _createBenchmarkTables(Database database) async {
    await database.execute('''
      CREATE TABLE benchmarks (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        description TEXT NOT NULL DEFAULT '',
        score_type TEXT NOT NULL
      )
    ''');

    await database.execute('''
      CREATE TABLE benchmark_attempts (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        benchmark_id TEXT NOT NULL,
        attempt_date TEXT NOT NULL,
        score TEXT NOT NULL,
        source_workbook TEXT NOT NULL DEFAULT '',
        program_day TEXT NOT NULL DEFAULT '',
        details TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        FOREIGN KEY (benchmark_id)
          REFERENCES benchmarks (id)
          ON DELETE CASCADE
      )
    ''');

    await database.execute('''
      CREATE INDEX index_benchmark_attempts_lookup
      ON benchmark_attempts (
        benchmark_id,
        attempt_date
      )
    ''');
  }

  Future<int> insertWorkout(LogEntry workout) async {
    final db = await database;

    return db.transaction((transaction) {
      return _insertWorkout(transaction, workout);
    });
  }

  Future<int> insertWorkoutsAtomically(List<LogEntry> workouts) async {
    final db = await database;

    return db.transaction((transaction) async {
      var imported = 0;

      for (final workout in workouts) {
        final duplicate = await _workoutExists(
          transaction,
          prescriptionId: workout.prescriptionId,
          modality: workout.modality.name,
          date: workout.date.toIso8601String().substring(0, 10),
          workDuration: workout.workDuration,
          intervalCount: workout.intervalCount,
          sourceWorkbook: workout.sourceWorkbook,
          programDay: workout.programDay,
        );

        if (duplicate) {
          continue;
        }

        await _insertWorkout(transaction, workout);
        imported++;
      }

      return imported;
    });
  }

  Future<int> _insertWorkout(
    DatabaseExecutor executor,
    LogEntry workout,
  ) async {
    final workoutId = await executor.insert('workouts', {
      'prescription_id': workout.prescriptionId,
      'modality': workout.modality.name,
      'workout_date': workout.date.toIso8601String(),
      'source_workbook': workout.sourceWorkbook,
      'program_day': workout.programDay,
      'duration': workout.duration,
      'work_duration': workout.workDuration,
      'interval_count': workout.intervalCount,
      'scoring_metric': workout.scoringMetric?.storageKey,
      'notes': workout.notes,
    });

    for (final interval in workout.intervals) {
      final intervalId = await executor.insert('workout_intervals', {
        'workout_id': workoutId,
        'interval_number': interval.intervalNumber,
      });

      for (final metricEntry in interval.values.entries) {
        await executor.insert('interval_metrics', {
          'interval_id': intervalId,
          'metric': metricEntry.key.storageKey,
          'value': metricEntry.value,
        });
      }
    }

    return workoutId;
  }

  Future<bool> workoutExists({
    required String prescriptionId,
    required String modality,
    required String date,
    required String workDuration,
    required int intervalCount,
    required String sourceWorkbook,
    required String programDay,
  }) async {
    final db = await database;

    return _workoutExists(
      db,
      prescriptionId: prescriptionId,
      modality: modality,
      date: date,
      workDuration: workDuration,
      intervalCount: intervalCount,
      sourceWorkbook: sourceWorkbook,
      programDay: programDay,
    );
  }

  Future<bool> _workoutExists(
    DatabaseExecutor executor, {
    required String prescriptionId,
    required String modality,
    required String date,
    required String workDuration,
    required int intervalCount,
    required String sourceWorkbook,
    required String programDay,
  }) async {
    final rows = await executor.query(
      'workouts',
      columns: ['id'],
      where: '''
        prescription_id = ?
        AND modality = ?
        AND substr(workout_date, 1, 10) = ?
        AND work_duration = ?
        AND interval_count = ?
        AND source_workbook = ?
        AND program_day = ?
      ''',
      whereArgs: [
        prescriptionId,
        modality,
        date,
        workDuration,
        intervalCount,
        sourceWorkbook,
        programDay,
      ],
      limit: 1,
    );

    return rows.isNotEmpty;
  }

  Future<void> deleteWorkout(int workoutId) async {
    final db = await database;

    await db.delete('workouts', where: 'id = ?', whereArgs: [workoutId]);
  }

  Future<List<LogEntry>> getWorkouts() async {
    final db = await database;

    final workoutRows = await db.query(
      'workouts',
      orderBy: 'workout_date DESC, id DESC',
    );

    final workouts = <LogEntry>[];

    for (final workoutRow in workoutRows) {
      final workoutId = workoutRow['id'] as int;

      final intervalRows = await db.query(
        'workout_intervals',
        where: 'workout_id = ?',
        whereArgs: [workoutId],
        orderBy: 'interval_number ASC, id ASC',
      );

      final intervals = <IntervalResult>[];

      for (final intervalRow in intervalRows) {
        final intervalId = intervalRow['id'] as int;

        final metricRows = await db.query(
          'interval_metrics',
          where: 'interval_id = ?',
          whereArgs: [intervalId],
          orderBy: 'id ASC',
        );

        final values = <WorkoutMetric, String>{};

        for (final metricRow in metricRows) {
          final savedMetric = metricRow['metric'] as String;

          final metric = WorkoutMetric.values.firstWhere(
            (item) => item.storageKey == savedMetric,
          );

          values[metric] = metricRow['value'] as String;
        }

        intervals.add(
          IntervalResult(
            intervalNumber: intervalRow['interval_number'] as int,
            values: values,
          ),
        );
      }

      final savedScoringMetric = workoutRow['scoring_metric'] as String?;

      WorkoutMetric? scoringMetric;

      if (savedScoringMetric != null) {
        scoringMetric = WorkoutMetric.values.firstWhere(
          (item) => item.storageKey == savedScoringMetric,
        );
      }

      workouts.add(
        LogEntry.forPrescription(
          prescriptionId: workoutRow['prescription_id'] as String,
          modality: Modality.values.byName(workoutRow['modality'] as String),
          date: DateTime.parse(workoutRow['workout_date'] as String),
          sourceWorkbook: (workoutRow['source_workbook'] as String?) ?? '',
          programDay: (workoutRow['program_day'] as String?) ?? '',
          duration: (workoutRow['duration'] as String?) ?? '',
          workDuration: (workoutRow['work_duration'] as String?) ?? '',
          intervalCount:
              (workoutRow['interval_count'] as int?) ?? intervals.length,
          scoringMetric: scoringMetric,
          notes: (workoutRow['notes'] as String?) ?? '',
          intervals: intervals,
        ),
      );
    }

    return workouts;
  }

  Future<void> upsertBenchmark(Benchmark benchmark) async {
    final db = await database;

    final values = {
      'id': benchmark.id,
      'name': benchmark.name,
      'description': benchmark.description,
      'score_type': benchmark.scoreType.storageKey,
    };

    await db.insert(
      'benchmarks',
      values,
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    await db.update(
      'benchmarks',
      values,
      where: 'id = ?',
      whereArgs: [benchmark.id],
    );
  }

  Future<List<Benchmark>> getBenchmarks() async {
    final db = await database;

    final rows = await db.query('benchmarks', orderBy: 'name ASC');

    return rows.map((row) => Benchmark.fromDatabaseMap(row)).toList();
  }

  Future<int> insertBenchmarkAttempt(BenchmarkAttempt attempt) async {
    final db = await database;

    return db.insert('benchmark_attempts', {
      'benchmark_id': attempt.benchmarkId,
      'attempt_date': attempt.date.toIso8601String(),
      'score': attempt.score,
      'source_workbook': attempt.sourceWorkbook,
      'program_day': attempt.programDay,
      'details': attempt.details,
      'notes': attempt.notes,
    });
  }

  Future<bool> insertBenchmarkAttemptIfAbsent(BenchmarkAttempt attempt) async {
    final db = await database;

    final existingRows = await db.query(
      'benchmark_attempts',
      columns: ['id'],
      where: '''
        benchmark_id = ?
        AND attempt_date = ?
        AND source_workbook = ?
        AND program_day = ?
      ''',
      whereArgs: [
        attempt.benchmarkId,
        attempt.date.toIso8601String(),
        attempt.sourceWorkbook,
        attempt.programDay,
      ],
      limit: 1,
    );

    if (existingRows.isNotEmpty) {
      return false;
    }

    await insertBenchmarkAttempt(attempt);
    return true;
  }

  Future<List<BenchmarkAttempt>> getBenchmarkAttempts({
    String? benchmarkId,
  }) async {
    final db = await database;

    final rows = await db.query(
      'benchmark_attempts',
      where: benchmarkId == null ? null : 'benchmark_id = ?',
      whereArgs: benchmarkId == null ? null : [benchmarkId],
      orderBy: 'attempt_date DESC, id DESC',
    );

    return rows.map((row) => BenchmarkAttempt.fromDatabaseMap(row)).toList();
  }

  Future<int> insertTargetHistory({
    required String prescriptionId,
    required Modality modality,
    required Metric metric,
    required TargetHistory target,
  }) async {
    final db = await database;

    return db.insert('target_history', {
      'prescription_id': prescriptionId,
      'modality': modality.name,
      'metric': metric.name,
      'low_target': target.lowTarget,
      'high_target': target.highTarget,
      'effective_date': target.effectiveDate.toIso8601String(),
    });
  }

  Future<bool> insertTargetHistoryIfAbsent({
    required String prescriptionId,
    required Modality modality,
    required Metric metric,
    required TargetHistory target,
  }) async {
    final db = await database;

    final effectiveDate = target.effectiveDate.toIso8601String();

    final existingRows = await db.query(
      'target_history',
      columns: ['id'],
      where: '''
        prescription_id = ?
        AND modality = ?
        AND metric = ?
        AND low_target = ?
        AND high_target = ?
        AND effective_date = ?
      ''',
      whereArgs: [
        prescriptionId,
        modality.name,
        metric.name,
        target.lowTarget,
        target.highTarget,
        effectiveDate,
      ],
      limit: 1,
    );

    if (existingRows.isNotEmpty) {
      return false;
    }

    await db.insert('target_history', {
      'prescription_id': prescriptionId,
      'modality': modality.name,
      'metric': metric.name,
      'low_target': target.lowTarget,
      'high_target': target.highTarget,
      'effective_date': effectiveDate,
    });

    return true;
  }

  Future<List<TargetHistory>> getTargetHistory({
    required String prescriptionId,
    required Modality modality,
    required Metric metric,
  }) async {
    final db = await database;

    final rows = await db.query(
      'target_history',
      where: '''
        prescription_id = ?
        AND modality = ?
        AND metric = ?
      ''',
      whereArgs: [prescriptionId, modality.name, metric.name],
      orderBy: 'effective_date ASC, id ASC',
    );

    return rows.map((row) {
      return TargetHistory(
        lowTarget: row['low_target'] as String,
        highTarget: row['high_target'] as String,
        effectiveDate: DateTime.parse(row['effective_date'] as String),
      );
    }).toList();
  }

  Future<List<GearTarget>> getTargetsForPrescription(
    String prescriptionId,
  ) async {
    final db = await database;

    final rows = await db.query(
      'target_history',
      where: 'prescription_id = ?',
      whereArgs: [prescriptionId],
      orderBy: '''
        modality ASC,
        metric ASC,
        effective_date ASC,
        id ASC
      ''',
    );

    final targetsByKey = <String, GearTarget>{};

    for (final row in rows) {
      final modality = Modality.values.byName(row['modality'] as String);

      final metric = Metric.values.byName(row['metric'] as String);

      final key = '${modality.name}:${metric.name}';

      final historyItem = TargetHistory(
        lowTarget: row['low_target'] as String,
        highTarget: row['high_target'] as String,
        effectiveDate: DateTime.parse(row['effective_date'] as String),
      );

      final existingTarget = targetsByKey[key];

      if (existingTarget == null) {
        targetsByKey[key] = GearTarget(
          modality: modality,
          metric: metric,
          history: [historyItem],
        );
      } else {
        targetsByKey[key] = existingTarget.copyWith(
          history: [...existingTarget.history, historyItem],
        );
      }
    }

    return targetsByKey.values.toList();
  }

  Future<List<String>> getTableNames() async {
    final db = await database;

    final results = await db.rawQuery('''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
        AND name NOT LIKE 'sqlite_%'
      ORDER BY name
    ''');

    return results.map((row) => row['name'] as String).toList();
  }

  Future<void> close() async {
    final database = _database;

    if (database == null) {
      return;
    }

    await database.close();
    _database = null;
  }
}
