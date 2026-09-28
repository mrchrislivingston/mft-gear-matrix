import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mft_gear_matrix/services/fitr_daily_schema.dart';
import 'package:mft_gear_matrix/services/fitr_daily_service.dart';
import 'package:mft_gear_matrix/services/fitr_mobile_client.dart';
import 'package:mft_gear_matrix/services/database_export_service.dart';
import 'package:mft_gear_matrix/services/database_restore_service.dart';

const instruction = 'Perform mobility/Stability, Lift 1, Conditioning 3, and Skill.\n\nBased on your weaknesses, remaining time and energy, add 0-2 of the following.';
final monday = DateTime(2026, 9, 21);
FitrWeekSnapshot snapshot(List<Map<String, dynamic>> pieces) => FitrWeekSnapshot(
  monday: monday, sunday: DateTime(2026, 9, 27), days: [FitrWeekDay(
    date: '2026-09-21', scheduleId: '42', planTitle: 'Misfit', calendarDay: {},
    detail: {'day': {'sections': [{'title': 'Instructions', 'description': instruction}, ...pieces]}},
  )]);

void main() {
  test('matches coach priorities and longer headings without confusing numbers', () {
    final result = dailyPriorities(instruction, ['Mobility/Stability', 'Lift 1', 'Lift 2', 'Accessory', 'Conditioning 2 (Intervals)', 'Conditioning 3 (Bitch Work)', 'Skill/REPs']);
    expect(result['Mobility/Stability'], 'required');
    expect(result['Lift 1'], 'required');
    expect(result['Conditioning 3 (Bitch Work)'], 'required');
    expect(result['Skill/REPs'], 'required');
    expect(result['Conditioning 2 (Intervals)'], 'optional');
    expect(result['Lift 2'], 'optional');
    expect(result['Accessory'], 'optional');
  });
  test('unknown directives never silently mark pieces optional', () {
    expect(dailyPriorities('Perform Lift 1 or Lift 2.', ['Lift 1', 'Lift 2']).values, everyElement('unassigned'));
    expect(dailyPriorities('Perform Lift 1 and Conditioning 4. Add 0-2 of the following.', ['Lift 1', 'Lift 2']).values, everyElement('unassigned'));
    expect(dailyPriorities('Perform Lift 1.', ['Lift 1', 'Lift 2'])['Lift 2'], 'unassigned');
  });

  group('saved programming', () {
    late Database db;
    late Directory directory;
    late FitrDailyService service;
    setUpAll(sqfliteFfiInit);
    setUp(() async {
      directory = await Directory.systemTemp.createTemp('mft_daily_test_');
      db = await databaseFactoryFfi.openDatabase('${directory.path}/daily.db');
      await createDailyTables(db);
      await db.execute('CREATE TABLE benchmark_attempts (id INTEGER PRIMARY KEY, benchmark_id TEXT, score TEXT, attempt_date TEXT)');
      service = FitrDailyService(databaseLoader: () async => db);
    });
    tearDown(() async { await db.close(); await directory.delete(recursive: true); });

    test('refresh survives reordering, preserves entries, and retains removed pieces', () async {
      await service.importSnapshot(snapshot([
        {'id': 1, 'title': 'Lift 1', 'description': 'Original'},
        {'title': 'Skill/REPs', 'description': 'TTB'},
      ]));
      var day = (await service.loadWeek(monday)).single;
      final liftId = day.pieces.first.id;
      final skillId = day.pieces.last.id;
      await service.saveEntry(liftId, result: '225 lb', notes: 'Felt good', completed: true);
      await service.saveEntry(skillId, result: '7 x 12', notes: '', completed: true);
      await service.importSnapshot(snapshot([
        {'title': 'Skill/REPs', 'description': 'Updated TTB'},
        {'id': 1, 'title': 'Lift 1', 'description': 'Updated'},
      ]));
      day = (await service.loadWeek(monday)).single;
      expect(day.pieces.first.id, skillId);
      expect(day.pieces.last.result, '225 lb');
      expect(day.pieces.last.description, 'Updated');
      expect(day.pieces.last.notes, 'Felt good');
      expect(day.pieces.last.completed, isTrue);
      await service.importSnapshot(snapshot([{'title': 'Skill/REPs', 'description': 'TTB'}]));
      day = (await service.loadWeek(monday)).single;
      expect(day.pieces, hasLength(2));
      expect(day.pieces.last.active, isFalse);
      expect(day.pieces.last.result, '225 lb');
    });

    test('invalid response changes nothing and duplicate imports do not duplicate rows', () async {
      final valid = snapshot([{'title': 'Lift 1', 'description': 'Original'}]);
      await service.importSnapshot(valid);
      await service.importSnapshot(valid);
      expect((await service.loadWeek(monday)).single.pieces, hasLength(1));
      final bad = FitrWeekSnapshot(monday: monday, sunday: valid.sunday, days: [
        ...valid.days, const FitrWeekDay(date: '2026-09-22', scheduleId: '43', planTitle: 'Misfit', calendarDay: {}, detail: {}),
      ]);
      await expectLater(service.importSnapshot(bad), throwsFormatException);
      expect(await service.loadWeek(monday), hasLength(1));
    });

    test('structured entries and percentage snapshot survive refresh and max changes', () async {
      await db.insert('benchmark_attempts', {'id':1,'benchmark_id':'bench_press_1rm','score':'200','attempt_date':'2026-08-01'});
      final data = snapshot([{'id':9,'title':'Lift 2','description':'Bench @75%1RM_BPRESS',
        'score_score':{'id':4,'measure':'reps','count_sub_value':null}, 'benchmarks':[]}]);
      await service.importSnapshot(data);
      var piece = (await service.loadWeek(monday)).single.pieces.single;
      expect(piece.calculations, contains('150 lb'));
      await service.saveStructuredEntry(piece, result:'AMRAP', notes:'Good', completed:true,
        scoreEntry:'{"spec":{"measure":"reps"},"values":["12"],"unit":"reps"}');
      await db.insert('working_max_history', {'lift_id':'bench_press_1rm','pounds':180,'effective_date':'2026-09-01'});
      await service.importSnapshot(data);
      piece = (await service.loadWeek(monday)).single.pieces.single;
      expect(piece.calculations, contains('150 lb'));
      expect(piece.scoreEntry, contains('12'));
      expect(piece.prescriptionSnapshot, isNotNull);
    });

    test('version 7 export contains programming and athlete entries', () async {
      await db.setVersion(7);
      for (final table in DatabaseRestoreService.requiredTables) {
        await db.execute('CREATE TABLE IF NOT EXISTS $table (id INTEGER PRIMARY KEY)');
      }
      await service.importSnapshot(snapshot([{'id': 1, 'title': 'Lift 1', 'description': 'Clean and jerk'}]));
      final piece = (await service.loadWeek(monday)).single.pieces.single;
      await service.saveEntry(piece.id, result: '225', notes: 'Test', completed: true);
      final validator = DatabaseRestoreService(factory: databaseFactoryFfi,
        databasePathLoader: () async => '${directory.path}/validation.db');
      final exported = await DatabaseExportService(databaseLoader: () async => db,
        validator: validator.validateBytes).createSnapshot();
      expect(exported.summary.schemaVersion, 7);
      expect(exported.summary.programmingDayCount, 1);
      expect(exported.summary.dailyEntryCount, 1);
      final copyPath = '${directory.path}/copy.db';
      await File(copyPath).writeAsBytes(exported.bytes);
      final copy = await databaseFactoryFfi.openDatabase(copyPath);
      try {
        final copied = FitrDailyService(databaseLoader: () async => copy);
        final saved = (await copied.loadWeek(monday)).single.pieces.single;
        expect(saved.result, '225');
        expect(saved.notes, 'Test');
        expect(saved.completed, isTrue);
      } finally { await copy.close(); }
    });
  });
}
