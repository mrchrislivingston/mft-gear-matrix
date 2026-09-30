import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mft_gear_matrix/services/fitr_daily_schema.dart';
import 'package:mft_gear_matrix/services/daily_results_import_service.dart';

void main() {
  sqfliteFfiInit();
  late Directory directory;
  late Database local, source;
  late DailyResultsImportService service;
  Future<Database> make(String name) async {
    final db = await databaseFactoryFfi.openDatabase('${directory.path}/$name.db',
      options: OpenDatabaseOptions(version: 7, onCreate: (db, _) => createDailyTables(db)));
    await db.insert('fitr_days', {'id':'day', 'workout_date':'2026-09-28',
      'plan_title':'Misfit', 'instructions':'Perform Lift 1.', 'fetched_at':name});
    await db.insert('fitr_pieces', {'id':'piece', 'day_id':'day', 'position':0,
      'title':'Lift 1', 'description':'Back Squat', 'priority':'required'});
    return db;
  }
  setUp(() async {
    directory = await Directory.systemTemp.createTemp('mft_results_test_');
    local = await make('local'); source = await make('phone');
    service = DailyResultsImportService(databaseLoader: () async => local, factory: databaseFactoryFfi);
    await source.update('fitr_pieces', {'result':'230 lb', 'notes':'Good',
      'score_entry_json':'{"spec":{"measure":"weight"},"values":["230"],"unit":"lb"}',
      'prescription_snapshot':'75% × 305 lb = 228.75 lb'});
  });
  tearDown(() async { await source.close(); await local.close(); await directory.delete(recursive:true); });
  Future<DailyResultsImportPlan> inspect() async {
    final file = '${directory.path}/export_${DateTime.now().microsecondsSinceEpoch}.db';
    await source.execute('VACUUM INTO ?', [file]);
    return service.inspect(await File(file).readAsBytes());
  }
  test('imports entries, preserves programming, backs up, and repeat is a no-op', () async {
    final plan = await inspect();
    expect(plan.additions, ['2026-09-28 • Lift 1']); expect(plan.conflicts, isEmpty);
    final backup = await service.apply(plan);
    expect(await File(backup!).exists(), isTrue);
    expect((await local.query('fitr_pieces')).single['result'], '230 lb');
    expect((await local.query('fitr_pieces')).single['completed'], 0);
    expect((await local.query('daily_lift_history')).single['score_entry_json'], contains('230'));
    expect((await local.query('daily_history_status')).single['message'], 'Saved to lift history');
    expect((await local.query('fitr_days')).single['fetched_at'], 'local');
    final saved = await databaseFactoryFfi.openDatabase(backup,
      options: OpenDatabaseOptions(readOnly:true, singleInstance:false));
    expect((await saved.query('fitr_pieces')).single['result'], ''); await saved.close();
    expect((await inspect()).unchanged, 1);
    expect(await service.apply(plan), isNull);
  });
  test('conflicting local result blocks changes even after preview', () async {
    final plan = await inspect();
    await local.update('fitr_pieces', {'result':'235 lb'});
    expect((await inspect()).conflicts, hasLength(1));
    await expectLater(service.apply(plan), throwsStateError);
    expect((await local.query('fitr_pieces')).single['result'], '235 lb');
  });
  test('missing programming is flagged; empty source does not clear local results', () async {
    await local.delete('fitr_pieces');
    expect((await inspect()).conflicts, hasLength(1));
    await source.update('fitr_pieces', {'result':'','notes':'','score_entry_json':'','prescription_snapshot':null});
    expect((await inspect()).rows, isEmpty);
  });
}
