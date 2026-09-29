import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';

const _entryFields = ['result', 'notes', 'completed', 'score_entry_json', 'prescription_snapshot'];
bool _hasEntry(Map<String, Object?> row) => row['completed'] == 1 ||
    ['result', 'notes', 'score_entry_json'].any((key) => (row[key] as String? ?? '').isNotEmpty);
Map<String, Object?> _entry(Map<String, Object?> row) => {for (final key in _entryFields) key: row[key]};
bool _sameEntry(Map<String, Object?> a, Map<String, Object?> b) =>
    _entryFields.every((key) => a[key] == b[key]);

class DailyResultsImportPlan {
  final List<Map<String, Object?>> rows;
  final List<String> additions, conflicts;
  final int unchanged;
  const DailyResultsImportPlan(this.rows, this.additions, this.conflicts, this.unchanged);
}

class DailyResultsImportService {
  final Future<Database> Function() databaseLoader;
  final DatabaseFactory factory;
  DailyResultsImportService({Future<Database> Function()? databaseLoader, DatabaseFactory? factory})
      : databaseLoader = databaseLoader ?? (() => DatabaseService.instance.database),
        factory = factory ?? databaseFactory;

  Future<DailyResultsImportPlan> inspect(Uint8List bytes) async {
    final directory = await Directory.systemTemp.createTemp('mft_results_');
    Database? source;
    try {
      final file = File('${directory.path}/source.db');
      await file.writeAsBytes(bytes, flush: true);
      source = await factory.openDatabase(file.path,
        options: OpenDatabaseOptions(readOnly: true, singleInstance: false));
      if ((await source.rawQuery('PRAGMA integrity_check')).single.values.single != 'ok' ||
          (await source.rawQuery('PRAGMA user_version')).single.values.single != 7) {
        throw StateError('Choose a valid MFT database export from the current app.');
      }
      final rows = (await source.rawQuery('''SELECT p.*, d.workout_date
        FROM fitr_pieces p JOIN fitr_days d ON d.id = p.day_id'''))
          .where(_hasEntry).map((r) => Map<String, Object?>.from(r)).toList();
      for (final row in rows) {
        final score = row['score_entry_json'] as String;
        if (score.isNotEmpty) {
          final entry = jsonDecode(score);
          if (entry is! Map || entry['spec'] is! Map || entry['values'] is! List) {
            throw StateError('An imported score entry is invalid. Nothing was imported.');
          }
        }
      }
      return _plan(await databaseLoader(), rows);
    } finally {
      await source?.close();
      await directory.delete(recursive: true);
    }
  }

  Future<DailyResultsImportPlan> _plan(DatabaseExecutor db, List<Map<String, Object?>> rows) async {
    final additions = <String>[], conflicts = <String>[];
    var unchanged = 0;
    for (final row in rows) {
      final label = '${row['workout_date']} • ${row['title']}';
      final local = await db.query('fitr_pieces', where: 'id = ?', whereArgs: [row['id']]);
      if (local.isEmpty || local.single['day_id'] != row['day_id']) {
        conflicts.add('$label: programming is missing; refresh that FITR week first.');
      } else if (_sameEntry(local.single, row)) {
        unchanged++;
      } else if (_hasEntry(local.single)) {
        conflicts.add('$label: different saved results exist on this device.');
      } else {
        additions.add(label);
      }
    }
    return DailyResultsImportPlan(rows, additions, conflicts, unchanged);
  }

  Future<String?> apply(DailyResultsImportPlan plan) async {
    final db = await databaseLoader();
    final latest = await _plan(db, plan.rows);
    if (latest.conflicts.isNotEmpty) throw StateError(latest.conflicts.join('\n'));
    if (latest.additions.isEmpty) return null;
    final backup = '${db.path}.before_results_${DateTime.now().microsecondsSinceEpoch}.db';
    await db.execute('VACUUM INTO ?', [backup]);
    await db.transaction((txn) async {
      // Recheck inside the transaction in case a local result changed since preview.
      final current = await _plan(txn, plan.rows);
      if (current.conflicts.isNotEmpty) throw StateError(current.conflicts.join('\n'));
      for (final row in plan.rows) {
        final local = (await txn.query('fitr_pieces', where: 'id = ?', whereArgs: [row['id']])).single;
        if (_sameEntry(local, row)) continue;
        await txn.update('fitr_pieces', _entry(row), where: 'id = ?', whereArgs: [row['id']]);
      }
    });
    return backup;
  }
}
