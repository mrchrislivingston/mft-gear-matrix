import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:mft_gear_matrix/services/database_restore_service.dart';

Future<Database> createDatabase(
  DatabaseFactory factory,
  String databasePath, {
  required int workouts,
}) async {
  final database = await factory.openDatabase(
    databasePath,
    options: OpenDatabaseOptions(
      version: DatabaseRestoreService.supportedSchemaVersion,
      singleInstance: false,
      onCreate: (database, version) async {
        for (final table in DatabaseRestoreService.requiredTables) {
          await database.execute('''
            CREATE TABLE $table (
              id INTEGER PRIMARY KEY AUTOINCREMENT
            )
          ''');
        }
      },
    ),
  );

  for (var index = 0; index < workouts; index++) {
    await database.rawInsert('INSERT INTO workouts DEFAULT VALUES');
  }

  return database;
}

void main() {
  late Directory directory;
  late DatabaseFactory factory;
  Database? activeDatabase;

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    directory = await Directory.systemTemp.createTemp('mft_restore_test_');
    factory = databaseFactoryFfi;
  });

  tearDown(() async {
    await activeDatabase?.close();
    activeDatabase = null;

    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  });

  DatabaseRestoreService serviceFor(String destinationPath) {
    return DatabaseRestoreService(
      factory: factory,
      databasePathLoader: () async => destinationPath,
      closeActiveDatabase: () async {
        await activeDatabase?.close();
        activeDatabase = null;
      },
      openActiveDatabase: () async {
        activeDatabase ??= await factory.openDatabase(
          destinationPath,
          options: OpenDatabaseOptions(
            version: DatabaseRestoreService.supportedSchemaVersion,
            singleInstance: false,
          ),
        );

        return activeDatabase!;
      },
    );
  }

  test('validates and restores a complete version 5 database', () async {
    final sourcePath = '${directory.path}/source.db';
    final destinationPath = '${directory.path}/destination.db';

    final source = await createDatabase(factory, sourcePath, workouts: 3);
    await source.close();

    activeDatabase = await createDatabase(
      factory,
      destinationPath,
      workouts: 1,
    );

    final bytes = Uint8List.fromList(await File(sourcePath).readAsBytes());
    final service = serviceFor(destinationPath);

    final preview = await service.validateBytes(bytes);

    expect(preview.schemaVersion, 5);
    expect(preview.workoutCount, 3);
    expect(preview.tables, containsAll(DatabaseRestoreService.requiredTables));

    final result = await service.restoreBytes(bytes);

    expect(result.snapshot.workoutCount, 3);
    expect(await File(result.backupPath).exists(), isTrue);

    final rows = await activeDatabase!.rawQuery(
      'SELECT COUNT(*) FROM workouts',
    );
    expect(Sqflite.firstIntValue(rows), 3);
  });

  test('rejects non-SQLite bytes without replacing current data', () async {
    final destinationPath = '${directory.path}/destination.db';

    activeDatabase = await createDatabase(
      factory,
      destinationPath,
      workouts: 1,
    );

    final service = serviceFor(destinationPath);

    await expectLater(
      service.restoreBytes(Uint8List.fromList([1, 2, 3, 4])),
      throwsA(
        isA<DatabaseRestoreException>().having(
          (error) => error.message,
          'message',
          contains('not a readable MFT Gear Matrix database'),
        ),
      ),
    );

    final rows = await activeDatabase!.rawQuery(
      'SELECT COUNT(*) FROM workouts',
    );
    expect(Sqflite.firstIntValue(rows), 1);
  });

  test('rejects a database missing required tables', () async {
    final sourcePath = '${directory.path}/incomplete.db';
    final destinationPath = '${directory.path}/destination.db';

    final incomplete = await factory.openDatabase(
      sourcePath,
      options: OpenDatabaseOptions(
        version: DatabaseRestoreService.supportedSchemaVersion,
        singleInstance: false,
        onCreate: (database, version) async {
          await database.execute(
            'CREATE TABLE workouts (id INTEGER PRIMARY KEY)',
          );
        },
      ),
    );
    await incomplete.close();

    activeDatabase = await createDatabase(
      factory,
      destinationPath,
      workouts: 1,
    );

    final bytes = Uint8List.fromList(await File(sourcePath).readAsBytes());
    final service = serviceFor(destinationPath);

    await expectLater(
      service.restoreBytes(bytes),
      throwsA(
        isA<DatabaseRestoreException>().having(
          (error) => error.message,
          'message',
          contains('missing required tables'),
        ),
      ),
    );

    final rows = await activeDatabase!.rawQuery(
      'SELECT COUNT(*) FROM workouts',
    );
    expect(Sqflite.firstIntValue(rows), 1);
  });

  test('restores the previous database when reopening fails', () async {
    final sourcePath = '${directory.path}/source.db';
    final destinationPath = '${directory.path}/destination.db';

    final source = await createDatabase(factory, sourcePath, workouts: 3);
    await source.close();

    activeDatabase = await createDatabase(
      factory,
      destinationPath,
      workouts: 1,
    );

    var failRestoredDatabaseOnce = true;

    final service = DatabaseRestoreService(
      factory: factory,
      databasePathLoader: () async => destinationPath,
      closeActiveDatabase: () async {
        await activeDatabase?.close();
        activeDatabase = null;
      },
      openActiveDatabase: () async {
        final database = await factory.openDatabase(
          destinationPath,
          options: OpenDatabaseOptions(
            version: DatabaseRestoreService.supportedSchemaVersion,
            singleInstance: false,
          ),
        );

        final rows = await database.rawQuery('SELECT COUNT(*) FROM workouts');
        final workoutCount = Sqflite.firstIntValue(rows) ?? 0;

        if (workoutCount == 3 && failRestoredDatabaseOnce) {
          failRestoredDatabaseOnce = false;
          await database.close();
          throw StateError('Simulated reopen failure');
        }

        activeDatabase = database;
        return database;
      },
    );

    final bytes = Uint8List.fromList(await File(sourcePath).readAsBytes());

    await expectLater(
      service.restoreBytes(bytes),
      throwsA(
        isA<DatabaseRestoreException>().having(
          (error) => error.message,
          'message',
          contains('previous database was restored'),
        ),
      ),
    );

    final rows = await activeDatabase!.rawQuery(
      'SELECT COUNT(*) FROM workouts',
    );
    expect(Sqflite.firstIntValue(rows), 1);
  });
}
