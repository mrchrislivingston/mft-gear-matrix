import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mft_gear_matrix/services/assault_runner_target_import.dart';

void main() {
  late Database db;
  setUpAll(sqfliteFfiInit);
  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('''CREATE TABLE target_history (
      id INTEGER PRIMARY KEY, prescription_id TEXT, modality TEXT, metric TEXT,
      low_target TEXT, high_target TEXT, effective_date TEXT)''');
    await db.execute('CREATE TABLE workouts (id INTEGER PRIMARY KEY, modality TEXT)');
    await db.insert('workouts', {'id': 1, 'modality': 'run'});
  });
  tearDown(() async => db.close());

  test('imports exact eight targets and is idempotent', () async {
    expect(await importAssaultRunnerTargets(db), 8);
    expect(await importAssaultRunnerTargets(db), 0);
    final rows = await db.query('target_history', orderBy: 'prescription_id, metric');
    expect(rows.map((r) => [r['prescription_id'], r['metric'], r['low_target'], r['high_target']]).toList(), [
      ['G2', 'minPerMile', '8:05', '8:20'], ['G2', 'watts', '890', '915'],
      ['G3', 'minPerMile', '7:45', '8:00'], ['G3', 'watts', '925', '950'],
      ['G7', 'minPerMile', '6:05', '6:20'], ['G7', 'watts', '1130', '1175'],
      ['G8', 'minPerMile', '5:45', '6:00'], ['G8', 'watts', '1250', '1290'],
    ]);
    expect(rows.every((r) => r['modality'] == 'assaultRunner'), isTrue);
    expect(await db.query('workouts'), [{'id': 1, 'modality': 'run'}]);
  });

  test('preserves outdoor targets and newer athlete edits', () async {
    for (final modality in ['run', 'assaultRunner']) {
      await db.insert('target_history', {
        'prescription_id': 'G2', 'modality': modality, 'metric': 'minPerMile',
        'low_target': '7:50', 'high_target': '8:05', 'effective_date': '2026-10-01',
      });
    }
    expect(await importAssaultRunnerTargets(db), 7);
    final existing = await db.query('target_history', where: 'effective_date = ?', whereArgs: ['2026-10-01']);
    expect(existing, hasLength(2));
    expect(existing.every((r) => r['low_target'] == '7:50'), isTrue);
  });

  test('failed import rolls back every inserted target', () async {
    await db.execute("""CREATE TRIGGER reject_g7 BEFORE INSERT ON target_history
      WHEN NEW.prescription_id = 'G7' BEGIN SELECT RAISE(ABORT, 'test failure'); END""");
    await expectLater(importAssaultRunnerTargets(db), throwsA(isA<DatabaseException>()));
    expect(await db.query('target_history'), isEmpty);
    expect(await db.query('workouts'), hasLength(1));
  });
}
