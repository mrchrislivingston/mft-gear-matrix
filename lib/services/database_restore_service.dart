import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart';

import 'database_service.dart';

class DatabaseSnapshotSummary {
  final int schemaVersion;
  final List<String> tables;
  final int workoutCount;
  final int targetCount;
  final int benchmarkCount;
  final int benchmarkAttemptCount;

  const DatabaseSnapshotSummary({
    required this.schemaVersion,
    required this.tables,
    required this.workoutCount,
    required this.targetCount,
    required this.benchmarkCount,
    required this.benchmarkAttemptCount,
  });
}

class DatabaseRestoreResult {
  final DatabaseSnapshotSummary snapshot;
  final String backupPath;

  const DatabaseRestoreResult({
    required this.snapshot,
    required this.backupPath,
  });
}

class DatabaseRestoreException implements Exception {
  final String message;

  const DatabaseRestoreException(this.message);

  @override
  String toString() => message;
}

class DatabaseRestoreService {
  static const int supportedSchemaVersion = 5;

  static const Set<String> requiredTables = {
    'workouts',
    'workout_intervals',
    'interval_metrics',
    'target_history',
    'benchmarks',
    'benchmark_attempts',
  };

  final DatabaseFactory _factory;
  final Future<String> Function() _databasePathLoader;
  final Future<void> Function() _closeActiveDatabase;
  final Future<Database> Function() _openActiveDatabase;

  DatabaseRestoreService({
    DatabaseFactory? factory,
    Future<String> Function()? databasePathLoader,
    Future<void> Function()? closeActiveDatabase,
    Future<Database> Function()? openActiveDatabase,
  }) : _factory = factory ?? databaseFactory,
       _databasePathLoader =
           databasePathLoader ?? (() => DatabaseService.instance.databasePath),
       _closeActiveDatabase =
           closeActiveDatabase ?? DatabaseService.instance.close,
       _openActiveDatabase =
           openActiveDatabase ?? (() => DatabaseService.instance.database);

  Future<DatabaseSnapshotSummary> validateBytes(Uint8List bytes) async {
    if (bytes.isEmpty) {
      throw const DatabaseRestoreException('The selected database is empty.');
    }

    final destinationPath = await _databasePathLoader();
    final stagedPath = _temporaryPath(destinationPath, 'validation');
    final stagedFile = File(stagedPath);

    try {
      await stagedFile.parent.create(recursive: true);
      await stagedFile.writeAsBytes(bytes, flush: true);
      return await _validatePath(stagedPath);
    } finally {
      if (await stagedFile.exists()) {
        await stagedFile.delete();
      }
    }
  }

  Future<DatabaseRestoreResult> restoreBytes(Uint8List bytes) async {
    if (bytes.isEmpty) {
      throw const DatabaseRestoreException('The selected database is empty.');
    }

    final destinationPath = await _databasePathLoader();
    final stagedPath = _temporaryPath(destinationPath, 'restore');
    final backupPath = _backupPath(destinationPath);
    final stagedFile = File(stagedPath);
    final destinationFile = File(destinationPath);
    final backupFile = File(backupPath);

    await stagedFile.parent.create(recursive: true);
    await stagedFile.writeAsBytes(bytes, flush: true);

    try {
      await _validatePath(stagedPath);

      final activeDatabase = await _openActiveDatabase();
      await _checkpointIfNeeded(activeDatabase);
      await _closeActiveDatabase();

      if (!await destinationFile.exists()) {
        throw const DatabaseRestoreException(
          'The current app database could not be located.',
        );
      }

      await _deleteSidecars(destinationPath);
      await destinationFile.rename(backupPath);

      var stagedInstalled = false;

      try {
        await stagedFile.rename(destinationPath);
        stagedInstalled = true;

        final restoredDatabase = await _openActiveDatabase();
        final restoredSummary = await _validateDatabase(restoredDatabase);

        return DatabaseRestoreResult(
          snapshot: restoredSummary,
          backupPath: backupPath,
        );
      } catch (error) {
        await _closeActiveDatabase();

        try {
          if (stagedInstalled && await destinationFile.exists()) {
            await destinationFile.delete();
          }

          await _deleteSidecars(destinationPath);

          if (await backupFile.exists()) {
            await backupFile.rename(destinationPath);
          }

          await _openActiveDatabase();
        } catch (rollbackError) {
          throw DatabaseRestoreException(
            'Database restore failed and automatic recovery also failed. '
            'The recovery copy is at $backupPath. '
            'Restore error: $error. Recovery error: $rollbackError',
          );
        }

        throw const DatabaseRestoreException(
          'Database restore failed. The previous database was restored.',
        );
      }
    } on DatabaseRestoreException {
      rethrow;
    } catch (error) {
      throw DatabaseRestoreException('Database restore failed: $error');
    } finally {
      if (await stagedFile.exists()) {
        await stagedFile.delete();
      }
    }
  }

  Future<DatabaseSnapshotSummary> _validatePath(String databasePath) async {
    Database? candidate;

    try {
      candidate = await _factory.openDatabase(
        databasePath,
        options: OpenDatabaseOptions(readOnly: true, singleInstance: false),
      );

      return await _validateDatabase(candidate);
    } on DatabaseRestoreException {
      rethrow;
    } catch (_) {
      throw const DatabaseRestoreException(
        'The selected file is not a readable MFT Gear Matrix database.',
      );
    } finally {
      await candidate?.close();
    }
  }

  Future<DatabaseSnapshotSummary> _validateDatabase(Database database) async {
    final integrityRows = await database.rawQuery('PRAGMA integrity_check');
    final integrityResult = integrityRows.first.values.first.toString();

    if (integrityResult.toLowerCase() != 'ok') {
      throw DatabaseRestoreException(
        'The selected database failed its integrity check: $integrityResult',
      );
    }

    final versionRows = await database.rawQuery('PRAGMA user_version');
    final schemaVersion = Sqflite.firstIntValue(versionRows) ?? 0;

    if (schemaVersion != supportedSchemaVersion) {
      throw DatabaseRestoreException(
        'Unsupported database schema version $schemaVersion. '
        'Expected version $supportedSchemaVersion.',
      );
    }

    final tableRows = await database.rawQuery('''
      SELECT name
      FROM sqlite_master
      WHERE type = 'table'
        AND name NOT LIKE 'sqlite_%'
      ORDER BY name
    ''');

    final tables = tableRows
        .map((row) => row['name'] as String)
        .toList(growable: false);

    final missingTables = requiredTables.difference(tables.toSet()).toList()
      ..sort();

    if (missingTables.isNotEmpty) {
      throw DatabaseRestoreException(
        'The selected database is missing required tables: '
        '${missingTables.join(', ')}.',
      );
    }

    return DatabaseSnapshotSummary(
      schemaVersion: schemaVersion,
      tables: tables,
      workoutCount: await _count(database, 'workouts'),
      targetCount: await _count(database, 'target_history'),
      benchmarkCount: await _count(database, 'benchmarks'),
      benchmarkAttemptCount: await _count(database, 'benchmark_attempts'),
    );
  }

  Future<int> _count(Database database, String table) async {
    final rows = await database.rawQuery('SELECT COUNT(*) FROM $table');
    return Sqflite.firstIntValue(rows) ?? 0;
  }

  Future<void> _checkpointIfNeeded(Database database) async {
    final rows = await database.rawQuery('PRAGMA journal_mode');
    final mode = rows.first.values.first.toString().toLowerCase();

    if (mode == 'wal') {
      await database.rawQuery('PRAGMA wal_checkpoint(TRUNCATE)');
    }
  }

  Future<void> _deleteSidecars(String databasePath) async {
    for (final suffix in const ['-wal', '-shm', '-journal']) {
      final file = File('$databasePath$suffix');

      if (await file.exists()) {
        await file.delete();
      }
    }
  }

  String _temporaryPath(String databasePath, String purpose) {
    final timestamp = DateTime.now().microsecondsSinceEpoch;
    return path.join(
      path.dirname(databasePath),
      '.mft_${purpose}_$timestamp.db',
    );
  }

  String _backupPath(String databasePath) {
    final timestamp = DateTime.now().toUtc().toIso8601String().replaceAll(
      ':',
      '-',
    );
    return path.join(
      path.dirname(databasePath),
      'mft_gear_matrix_before_restore_$timestamp.db',
    );
  }
}
