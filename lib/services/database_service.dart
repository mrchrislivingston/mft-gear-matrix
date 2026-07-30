import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/log_entry.dart';
import '../models/metric.dart';
import '../models/modality.dart';
import '../models/target_history.dart';
import '../models/workout_metric.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  static const String _databaseName = 'mft_gear_matrix.db';
  static const int _databaseVersion = 1;

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

    final databasePath = join(
      databaseDirectory,
      _databaseName,
    );

    return openDatabase(
      databasePath,
      version: _databaseVersion,
      onConfigure: (database) async {
        await database.execute(
          'PRAGMA foreign_keys = ON',
        );
      },
      onCreate: (database, version) async {
        await _createTables(database);
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
        duration TEXT NOT NULL DEFAULT '',
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
  }

  Future<int> insertWorkout(LogEntry workout) async {
    final db = await database;

    return db.transaction((transaction) async {
      final workoutId = await transaction.insert(
        'workouts',
        {
          'prescription_id': workout.prescriptionId,
          'modality': workout.modality.name,
          'workout_date': workout.date.toIso8601String(),
          'duration': workout.duration,
          'scoring_metric': workout.scoringMetric?.storageKey,
          'notes': workout.notes,
        },
      );

      for (final interval in workout.intervals) {
        final intervalId = await transaction.insert(
          'workout_intervals',
          {
            'workout_id': workoutId,
            'interval_number': interval.intervalNumber,
          },
        );

        for (final metricEntry in interval.values.entries) {
          await transaction.insert(
            'interval_metrics',
            {
              'interval_id': intervalId,
              'metric': metricEntry.key.storageKey,
              'value': metricEntry.value,
            },
          );
        }
      }

      return workoutId;
    });
  }

  Future<void> deleteWorkout(int workoutId) async {
    final db = await database;

    await db.delete(
      'workouts',
      where: 'id = ?',
      whereArgs: [workoutId],
    );
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
            intervalNumber:
                intervalRow['interval_number'] as int,
            values: values,
          ),
        );
      }

      final savedScoringMetric =
          workoutRow['scoring_metric'] as String?;

      WorkoutMetric? scoringMetric;

      if (savedScoringMetric != null) {
        scoringMetric = WorkoutMetric.values.firstWhere(
          (item) => item.storageKey == savedScoringMetric,
        );
      }

      workouts.add(
        LogEntry.forPrescription(
          prescriptionId:
              workoutRow['prescription_id'] as String,
          modality: Modality.values.byName(
            workoutRow['modality'] as String,
          ),
          date: DateTime.parse(
            workoutRow['workout_date'] as String,
          ),
          duration:
              (workoutRow['duration'] as String?) ?? '',
          scoringMetric: scoringMetric,
          notes: (workoutRow['notes'] as String?) ?? '',
          intervals: intervals,
        ),
      );
    }

    return workouts;
  }

  Future<int> insertTargetHistory({
    required String prescriptionId,
    required Modality modality,
    required Metric metric,
    required TargetHistory target,
  }) async {
    final db = await database;

    return db.insert(
      'target_history',
      {
        'prescription_id': prescriptionId,
        'modality': modality.name,
        'metric': metric.name,
        'low_target': target.lowTarget,
        'high_target': target.highTarget,
        'effective_date':
            target.effectiveDate.toIso8601String(),
      },
    );
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
      whereArgs: [
        prescriptionId,
        modality.name,
        metric.name,
      ],
      orderBy: 'effective_date ASC, id ASC',
    );

    return rows.map((row) {
      return TargetHistory(
        lowTarget: row['low_target'] as String,
        highTarget: row['high_target'] as String,
        effectiveDate: DateTime.parse(
          row['effective_date'] as String,
        ),
      );
    }).toList();
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

    return results
        .map((row) => row['name'] as String)
        .toList();
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