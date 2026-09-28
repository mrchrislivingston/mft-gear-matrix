import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mft_gear_matrix/services/database_export_service.dart';
import 'package:mft_gear_matrix/services/database_restore_service.dart';

void main() {
  late Directory directory;
  late Database source;
  final factory = databaseFactoryFfi;
  setUpAll(sqfliteFfiInit);
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('mft_export_test_');
    source = await factory.openDatabase('${directory.path}/source.db', options: OpenDatabaseOptions(singleInstance: false));
    await source.rawQuery('PRAGMA journal_mode = WAL');
    await source.rawQuery('PRAGMA wal_autocheckpoint = 0');
    await source.setVersion(5);
    for (final table in DatabaseRestoreService.requiredTables) {
      await source.execute('CREATE TABLE $table (id INTEGER PRIMARY KEY, value TEXT NOT NULL)');
      await source.insert(table, {'id': 1, 'value': '$table original'});
    }
  });
  tearDown(() async {
    await source.close();
    await directory.delete(recursive: true);
  });

  DatabaseRestoreService validator() => DatabaseRestoreService(
    factory: factory,
    databasePathLoader: () async => '${directory.path}/validation.db',
  );

  test('exports committed WAL records and restores all six tables independently', () async {
    await source.insert('target_history', {'id': 2, 'value': 'assaultRunner G2 watts 890-915'});
    expect(await File('${source.path}-wal').length(), greaterThan(0));
    final service = DatabaseExportService(
      databaseLoader: () async => source,
      validator: validator().validateBytes,
      temporaryDirectory: () => Directory('${directory.path}/export').create(),
      clock: () => DateTime(2026, 9, 27, 22, 20),
    );
    final snapshot = await service.createSnapshot();
    expect(snapshot.fileName, 'MFT_Backup_2026-09-27_10-20-00_PM.db');
    expect(snapshot.summary.workoutCount, 1);
    expect(snapshot.summary.targetCount, 2);
    expect(snapshot.summary.benchmarkCount, 1);
    expect(snapshot.summary.benchmarkAttemptCount, 1);
    expect(await Directory('${directory.path}/export').exists(), isFalse);

    final targetPath = '${directory.path}/target.db';
    Database? target = await factory.openDatabase(targetPath, options: OpenDatabaseOptions(singleInstance: false));
    await target!.execute('CREATE TABLE previous_record (id INTEGER PRIMARY KEY)');
    final restore = DatabaseRestoreService(
      factory: factory,
      databasePathLoader: () async => targetPath,
      closeActiveDatabase: () async { await target?.close(); target = null; },
      openActiveDatabase: () async {
        target ??= await factory.openDatabase(targetPath, options: OpenDatabaseOptions(singleInstance: false));
        return target!;
      },
    );
    try {
      final result = await restore.restoreBytes(snapshot.bytes);
      expect(await File(result.backupPath).exists(), isTrue);
      for (final table in DatabaseRestoreService.requiredTables) {
        expect(await target!.query(table), await source.query(table));
      }
      // Writes after the snapshot stay local and do not change the backup.
      await source.insert('workouts', {'id': 2, 'value': 'new workout'});
      expect(await target!.query('workouts'), hasLength(1));
      expect(await source.query('workouts'), hasLength(2));
    } finally {
      await target?.close();
    }
  });

  test('validation failure cleans the snapshot and preserves the live DB', () async {
    final service = DatabaseExportService(
      databaseLoader: () async => source,
      validator: (_) async => throw StateError('invalid snapshot'),
      temporaryDirectory: () => Directory('${directory.path}/failed').create(),
    );
    await expectLater(service.createSnapshot(), throwsStateError);
    expect(await Directory('${directory.path}/failed').exists(), isFalse);
    expect(await source.query('workouts'), hasLength(1));
  });
}
