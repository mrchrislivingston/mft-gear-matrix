import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

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

  Future<void> close() async {
    final database = _database;

    if (database == null) {
      return;
    }

    await database.close();
    _database = null;
  }
}