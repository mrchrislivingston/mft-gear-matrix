import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:mft_gear_matrix/services/fitr_daily_schema.dart';
import 'package:mft_gear_matrix/services/fitr_daily_service.dart';
import 'package:mft_gear_matrix/services/daily_history_service.dart';

void main() {
  setUpAll(sqfliteFfiInit);
  late Database db;
  late FitrDailyService service;
  setUp(() async {
    db=await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('PRAGMA foreign_keys=ON');
    await createDailyTables(db);
    await db.execute('''CREATE TABLE workouts (id INTEGER PRIMARY KEY,
      prescription_id TEXT, modality TEXT, workout_date TEXT, source_workbook TEXT,
      program_day TEXT, duration TEXT, work_duration TEXT, interval_count INTEGER, notes TEXT)''');
    await db.execute('''CREATE TABLE workout_intervals (id INTEGER PRIMARY KEY,
      workout_id INTEGER REFERENCES workouts(id) ON DELETE CASCADE, interval_number INTEGER)''');
    await db.execute('''CREATE TABLE interval_metrics (id INTEGER PRIMARY KEY,
      interval_id INTEGER REFERENCES workout_intervals(id) ON DELETE CASCADE, metric TEXT, value TEXT)''');
    await db.execute('CREATE TABLE benchmarks (id TEXT PRIMARY KEY, name TEXT, score_type TEXT)');
    await db.execute('''CREATE TABLE benchmark_attempts (id INTEGER PRIMARY KEY,
      benchmark_id TEXT REFERENCES benchmarks(id), attempt_date TEXT, score TEXT,
      source_workbook TEXT, program_day TEXT, details TEXT, notes TEXT)''');
    await db.insert('fitr_days',{'id':'d','workout_date':'2026-09-28','plan_title':'Misfit','instructions':'','fetched_at':''});
    service=FitrDailyService(databaseLoader:() async=>db);
  });
  tearDown(() async=>db.close());
  Future<void> piece(String title,String description) async {
    await db.insert('fitr_pieces',{'id':'p','day_id':'d','position':0,'title':title,'description':description,'priority':'required'});
  }
  Future<void> save(String measure,List<String> values,{String result='',String notes=''}) async {
    final p=DailyPiece.fromRow((await db.query('fitr_pieces')).single);
    await service.saveStructuredEntry(p,result:result,notes:notes,completed:false,
      scoreEntry:values.isEmpty?'':jsonEncode({'spec':{'measure':measure,'count_sub_value':values.length},
        'unit':measure=='weight'?'lb':measure=='distance'?'m':measure,'values':values}));
  }
  Future<String> status() async=>(await db.query('daily_history_status')).single['message'] as String;
  const run='Build Run - 5th Gear\nAMRAP 3:30 x 3\nRun for Meters @ 5th Gear\nRest 2:30';
  test('save projects distances, preserves blanks, edits same workout and clearing removes only owned rows',() async {
    await piece('Conditioning 3',run);
    await save('distance',['800','','900']);
    final workout=(await db.query('workouts')).single;
    expect(workout['prescription_id'],'G5'); expect(workout['modality'],'run');
    expect(workout['interval_count'],3);
    expect((await db.query('workout_intervals')).map((r)=>r['interval_number']),[1,3]);
    final distances=await db.query('interval_metrics',where:'metric=?',whereArgs:['distance']);
    expect(double.parse(distances.first['value'] as String),closeTo(800/1609.344,0.00001));
    await save('distance',['810','','910']);
    expect((await db.query('workouts')).single['id'],workout['id']);
    await db.transaction((txn)=>DailyHistoryService.rebuild(txn));
    expect(await db.query('workouts'),hasLength(1));
    await save('distance',[]);
    expect(await db.query('workouts'),isEmpty); expect(await db.query('interval_metrics'),isEmpty);
  });
  test('mixed gears retain independent durations and scores',() async {
    await piece('Conditioning 3', '''Build Run - 5th / 6th Gear
AMRAP 3:30 x 3
Run for Meters @ 5th Gear
Rest 2:30
Rest 3:00 after the third round, Then
AMRAP 3:00 x 2
Run for Meters @ 6th Gear
Rest 3:00''');
    await save('distance',['800','810','820','750','760']);
    final rows=await db.query('workouts',orderBy:'prescription_id');
    expect(rows.map((r)=>r['prescription_id']),['G5','G6']);
    expect(rows.map((r)=>r['work_duration']),['3:30','3:00']);
    expect(rows.map((r)=>r['interval_count']),[3,2]);
  });
  test('single total is not distributed across rounds',() async {
    await piece('Conditioning 3',run); await save('distance',['2400']);
    expect(await db.query('workouts'),isEmpty); expect(await status(),contains('score count'));
  });
  test('AssaultRunner retains meters and never becomes outdoor run',() async {
    await piece('Conditioning 3',run.replaceAll('Run','AssaultRunner'));
    await save('distance',['800','810','820']);
    expect((await db.query('workouts')).single['modality'],'assaultRunner');
    expect((await db.query('interval_metrics',where:'metric=?',whereArgs:['distance'])).first['value'],'800');
  });
  test('same-day manual gear result is retained and flagged',() async {
    await piece('Conditioning 3',run);
    await db.insert('workouts',{'prescription_id':'G5','modality':'run','workout_date':'2026-09-28','notes':'manual'});
    await save('distance',['800','810','820']);
    expect((await db.query('workouts')).single['notes'],'manual');
    expect(await status(),contains('already exists'));
  });
  test('ordinary squat sets go to lift history without becoming a 1RM',() async {
    await db.insert('benchmarks',{'id':'back_squat_1rm','name':'Back Squat 1RM','score_type':'maxWeight'});
    await piece('Lift 1','Back Squat\n5x5 @ 75%');
    await save('weight',['230','230','230','230','230']);
    expect(await db.query('daily_lift_history'),hasLength(1));
    expect(await db.query('benchmark_attempts'),isEmpty);
    await save('weight',['235','235','235','235','235']);
    expect(await db.query('daily_lift_history'),hasLength(1));
    expect((await db.query('daily_lift_history')).single['score_entry_json'],contains('235'));
  });
  test('explicit 1RM updates one benchmark attempt and blocks a manual duplicate',() async {
    await db.insert('benchmarks',{'id':'back_squat_1rm','name':'Back Squat 1RM','score_type':'maxWeight'});
    await piece('Lift 1','Back Squat 1RM\nBuild to a 1RM');
    await save('weight',['310']);
    final attempt=(await db.query('benchmark_attempts')).single;
    await save('weight',['315']);
    expect((await db.query('benchmark_attempts')).single['id'],attempt['id']);
    expect((await db.query('benchmark_attempts')).single['score'],'315');
  });
  test('refresh cannot silently change the recorded exercise timing',() async {
    await piece('Conditioning 3',run); await save('distance',['800','810','820']);
    await db.update('fitr_pieces',{'description':run.replaceAll('3:30','4:30')});
    await db.transaction((txn)=>DailyHistoryService.rebuild(txn));
    expect((await db.query('workouts')).single['work_duration'],'3:30');
  });
  test('transaction failure rolls back both entry and history',() async {
    await piece('Conditioning 3',run);
    await db.execute("CREATE TRIGGER reject_metric BEFORE INSERT ON interval_metrics BEGIN SELECT RAISE(ABORT,'test failure'); END");
    await expectLater(save('distance',['800','810','820']),throwsA(anything));
    expect((await db.query('fitr_pieces')).single['score_entry_json'],'');
    expect(await db.query('workouts'),isEmpty);
  });
  const z2='Zone 2 - Row\n15:00 Zone 2 Warm Up\n45:00-90:00 Row @ Zone 2\n15:00 Zone 2 Cool Down';
  test('accessory stays a session log without benchmark or review flag',() async {
    await piece('Accessory','2-3 Sets\n8 Back Extensions');
    await save('weight',['25','65','','35','85','','45','115','','','',''],result:':45/:50/:55');
    expect(await status(),'Session log saved');
    expect(await db.query('daily_lift_history'),isEmpty);
    expect(await db.query('benchmark_attempts'),isEmpty);
  });
  test('Z2 uses actual duration and distance instead of prescribed range',() async {
    await piece('Conditioning 3',z2);
    await save('watts',['117'],result:'6250m in 30 min');
    final w=(await db.query('workouts')).single;
    expect(w['prescription_id'],'Z2'); expect(w['duration'],'30:00');
    final metrics={for(final r in await db.query('interval_metrics')) r['metric']:r['value']};
    expect(metrics['distance'],'6250');expect(metrics['watts'],'117');expect(metrics['primaryMetric'],'2:24');
    expect(await status(),contains('unspecified'));
    await db.transaction((txn)=>DailyHistoryService.rebuild(txn));
    expect((await db.query('workouts')).single['id'],w['id']);
  });
  test('Z2 requires actual duration and retains watt provenance and heart rate',() async {
    await piece('Conditioning 3',z2);await save('watts',['117']);
    expect(await db.query('workouts'),isEmpty);expect(await status(),contains('actual Z2 duration'));
    final p=DailyPiece.fromRow((await db.query('fitr_pieces')).single);
    await service.saveStructuredEntry(p,result:'',notes:'Easy',completed:false,scoreEntry:jsonEncode({
      'spec':{'measure':'watts'},'values':['117'],'unit':'watts',
      'actual':{'minutes':'30','meters':'6250','heart_rate':'125','modality':'Row','watts_source':'Estimated'},
    }));
    expect((await db.query('workouts')).single['notes'],contains('Watts source: Estimated'));
    expect((await db.query('interval_metrics',where:'metric=?',whereArgs:['heartRate'])).single['value'],'125');
    expect(await status(),contains('estimated'));
  });

}
