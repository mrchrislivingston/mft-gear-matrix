import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mft_gear_matrix/services/fitr_daily_schema.dart';
void main() {
  setUpAll(sqfliteFfiInit);
  test('version 6 daily entries survive scoring upgrade with all text intact', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    try {
      await db.execute("CREATE TABLE fitr_pieces (id TEXT PRIMARY KEY, result TEXT, notes TEXT, completed INTEGER)");
      await db.insert('fitr_pieces', {'id':'one','result':'225 lb','notes':'Solid','completed':1});
      await upgradeDailyScoring(db);
      final row = (await db.query('fitr_pieces')).single;
      expect(row['result'],'225 lb');
      expect(row['notes'],'Solid');
      expect(row['completed'],1);
      expect(row['source_json'],'{}');
      expect(row['score_entry_json'],'');
      expect(row['prescription_snapshot'],isNull);
      await db.insert('working_max_history', {'lift_id':'bench_press_1rm','pounds':200,'effective_date':'2026-09-28'});
      expect(await db.query('working_max_history'),hasLength(1));
    } finally { await db.close(); }
  });
}
