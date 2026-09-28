import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:sqflite/sqflite.dart';

import 'database_service.dart';
import 'working_max_service.dart';
import 'fitr_credentials_store.dart';
import 'fitr_mobile_client.dart';
import 'fitr_workout_classifier.dart';

String dailyDate(DateTime date) => date.toIso8601String().substring(0, 10);

String sectionCategory(String title) {
  final text = title.trim().toLowerCase().replaceAll(RegExp(r'\s*/\s*'), '/');
  if (RegExp(r'^mobility(?:/stability)?$').hasMatch(text)) return 'Mobility/Stability';
  if (RegExp(r'^skills?(?:/reps)?$').hasMatch(text)) return 'Skill';
  final match = RegExp(r'^(lift\s+[12]|accessory(?:\s+[12])?|conditioning\s+[123])(?:\s*\([^)]*\))?$').firstMatch(text);
  if (match == null) return title.trim();
  final name = match.group(1)!.replaceAll(RegExp(r'\s+'), ' ');
  return '${name[0].toUpperCase()}${name.substring(1)}';
}

/// Only classify a complete, recognizable directive. Uncertain wording stays
/// unassigned, with the original instructions still visible to the athlete.
Map<String, String> dailyPriorities(String instructions, List<String> titles) {
  final result = {for (final title in titles) title: 'unassigned'};
  final directive = RegExp(r'^\s*Perform\s+([^.!\n]+)[.!]?', caseSensitive: false, multiLine: true).firstMatch(instructions);
  if (directive == null) return result;
  final tokens = directive.group(1)!.split(RegExp(r',|\band\b', caseSensitive: false))
      .map((s) => s.trim()).where((s) => s.isNotEmpty).toList();
  final categories = titles.map(sectionCategory).toSet();
  final required = tokens.map(sectionCategory).toSet();
  if (required.isEmpty || !required.every(categories.contains)) return result;
  final optionalDirective = RegExp(r'add\s+\d+\s*[-–]\s*\d+\s+of\s+the\s+following', caseSensitive: false).hasMatch(instructions);
  for (final title in titles) {
    result[title] = required.contains(sectionCategory(title)) ? 'required'
        : optionalDirective && RegExp(r'^(Lift [12]|Accessory(?: [12])?|Conditioning [123]|Skill|Mobility/Stability)$').hasMatch(sectionCategory(title))
          ? 'optional' : 'unassigned';
  }
  return result;
}

class DailyPiece {
  final String id, title, description, priority, result, notes;
  final bool completed, active;
  final Map<String, dynamic> metadata;
  final String scoreEntry, calculations;
  final String? prescriptionSnapshot;
  const DailyPiece({required this.id, required this.title, required this.description,
    required this.priority, this.result = '', this.notes = '', this.completed = false,
    this.active = true, this.metadata = const {}, this.scoreEntry = '',
    this.calculations = '', this.prescriptionSnapshot});
  factory DailyPiece.fromRow(Map<String, Object?> row, {String calculations = ''}) => DailyPiece(
    id: row['id'] as String, title: row['title'] as String,
    description: row['description'] as String, priority: row['priority'] as String,
    result: row['result'] as String, notes: row['notes'] as String,
    completed: row['completed'] == 1, active: row['active'] == 1,
    metadata: Map<String, dynamic>.from(jsonDecode(row['source_json'] as String? ?? '{}') as Map),
    scoreEntry: row['score_entry_json'] as String? ?? '',
    prescriptionSnapshot: row['prescription_snapshot'] as String?, calculations: calculations);
}

class DailyPlan {
  final String id, date, planTitle, instructions, fetchedAt;
  final List<DailyPiece> pieces;
  const DailyPlan({required this.id, required this.date, required this.planTitle,
    required this.instructions, required this.fetchedAt, required this.pieces});
}

class FitrDailyService {
  final Future<Database> Function() databaseLoader;
  final Future<FitrWeekSnapshot> Function(DateTime)? weekLoader;
  FitrDailyService({Future<Database> Function()? databaseLoader, this.weekLoader})
      : databaseLoader = databaseLoader ?? (() => DatabaseService.instance.database);

  Future<FitrWeekSnapshot> fetchWeek(DateTime monday) async {
    if (weekLoader != null) return weekLoader!(monday);
    FitrCredentials? credentials;
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
      final home = Platform.environment['HOME'];
      if (home == null) throw const FitrMobileException('Home directory unavailable.');
      final file = File(Platform.environment['MFT_FITR_CREDENTIALS'] ??
          '$home/Development/garmin-test/fitr_credentials.txt');
      if (!await file.exists()) {
        throw const FitrMobileException('FITR credentials file not found. Use the same setup as FITR → Garmin Calendar.');
      }
      final values = <String, String>{};
      for (final line in await file.readAsLines()) {
        if (line.trim().startsWith('#')) continue;
        final separator = line.indexOf('=');
        if (separator > 0) values[line.substring(0, separator).trim()] = line.substring(separator + 1).trim();
      }
      credentials = FitrCredentials(token: values['TOKEN'] ?? '', cookie: values['COOKIE'] ?? '',
        athleteId: int.tryParse(values['ATHLETE_ID'] ?? '') ?? 0);
    } else {
      credentials = await FitrCredentialsStore.secure().load();
    }
    if (credentials == null) throw const FitrMobileException('Set up FITR credentials in FITR → Garmin Calendar first.');
    final client = http.Client();
    try {
      return await FitrMobileClient(credentials: credentials, httpClient: client).fetchWeek(monday);
    } finally { client.close(); }
  }

  Future<int> refresh(DateTime monday) async {
    final snapshot = await fetchWeek(monday);
    await importSnapshot(snapshot);
    return snapshot.days.length;
  }

  Future<void> importSnapshot(FitrWeekSnapshot snapshot) async {
    // Validate the whole response before changing any saved programming.
    final prepared = <({FitrWeekDay day, List<Map<String, dynamic>> sections})>[];
    for (final day in snapshot.days) {
      final detail = day.detail['day'];
      if (detail is! Map || detail['sections'] is! List) {
        throw const FormatException('FITR returned a day without workout sections. Saved programming was kept.');
      }
      final sections = <Map<String, dynamic>>[];
      for (final section in detail['sections'] as List) {
        if (section is! Map) throw const FormatException('Invalid FITR section.');
        sections.add(Map<String, dynamic>.from(section));
      }
      prepared.add((day: day, sections: sections));
    }
    final db = await databaseLoader();
    await db.transaction((txn) async {
      for (final item in prepared) {
        final day = item.day;
        final id = '${day.scheduleId}:${day.date}';
        final instructions = item.sections.where((s) => fitrSectionTitle(s).toLowerCase() == 'instructions')
            .map(fitrSectionDescription).join('\n\n');
        final sections = item.sections.where((s) => fitrSectionTitle(s).toLowerCase() != 'instructions').toList();
        final priorities = dailyPriorities(instructions, sections.map(fitrSectionTitle).toList());
        final values = <String, Object?>{'id': id, 'workout_date': day.date,
          'plan_title': day.planTitle, 'instructions': instructions,
          'fetched_at': DateTime.now().toIso8601String()};
        await txn.insert('fitr_days', values, conflictAlgorithm: ConflictAlgorithm.ignore);
        await txn.update('fitr_days', values, where: 'id = ?', whereArgs: [id]);
        await txn.update('fitr_pieces', {'active': 0}, where: 'day_id = ?', whereArgs: [id]);
        final occurrences = <String, int>{};
        for (var i = 0; i < sections.length; i++) {
          final section = sections[i];
          final title = fitrSectionTitle(section);
          // Prefer the source section ID. Title fallback survives reordering;
          // duplicate titles use occurrence number rather than silently merging.
          final sourceId = section['id'];
          final base = sourceId != null ? 'source:$sourceId' : 'title:${title.trim().toLowerCase()}';
          final occurrence = occurrences.update(base, (v) => v + 1, ifAbsent: () => 0);
          final pieceId = jsonEncode([id, base, occurrence]);
          final piece = <String, Object?>{'id': pieceId, 'day_id': id, 'position': i,
            'title': title, 'description': fitrSectionDescription(section),
            'priority': priorities[title]!, 'active': 1,
            'source_json': jsonEncode({'section_id': section['id'], 'schedule_id': day.scheduleId,
              'score_score': section['score_score'], 'benchmarks': section['benchmarks'] ?? [],
              'kind': section['kind'], 'exercise_columns': section['exercise_columns']})};
          await txn.insert('fitr_pieces', piece, conflictAlgorithm: ConflictAlgorithm.ignore);
          // Never overwrite the athlete's result, notes, or completion on refresh.
          await txn.update('fitr_pieces', piece, where: 'id = ?', whereArgs: [pieceId]);
        }
      }
    });
  }

  Future<List<DailyPlan>> loadWeek(DateTime monday) async {
    final db = await databaseLoader();
    final rows = await db.query('fitr_days', where: 'workout_date >= ? AND workout_date <= ?',
      whereArgs: [dailyDate(monday), dailyDate(monday.add(const Duration(days: 6)))],
      orderBy: 'workout_date, plan_title, id');
    final attempts = await db.query('benchmark_attempts', orderBy: 'attempt_date DESC, id DESC');
    final overrides = await db.query('working_max_history');
    final days = <DailyPlan>[];
    for (final row in rows) {
      final pieces = await db.query('fitr_pieces', where: 'day_id = ? AND (active = 1 OR result != ? OR notes != ? OR completed = 1 OR score_entry_json != ?)',
        whereArgs: [row['id'], '', '', ''], orderBy: 'active DESC, position, id');
      days.add(DailyPlan(id: row['id'] as String, date: row['workout_date'] as String,
        planTitle: row['plan_title'] as String, instructions: row['instructions'] as String,
        fetchedAt: row['fetched_at'] as String, pieces: pieces.map((piece) {
          final metadata = Map<String, dynamic>.from(jsonDecode(piece['source_json'] as String? ?? '{}') as Map);
          final dayDate = DateTime.parse(row['workout_date'] as String);
          final now = DateTime.now();
          final calculations = piece['prescription_snapshot'] as String? ?? percentageCalculations(
            piece['description'] as String, asOf: dayDate.isAfter(now) ? now : dayDate,
            attempts: attempts, overrides: overrides,
            fitrBenchmarks: metadata['benchmarks'] is List ? metadata['benchmarks'] as List : const []);
          return DailyPiece.fromRow(piece, calculations: calculations);
        }).toList()));
    }
    return days;
  }


  Future<void> saveStructuredEntry(DailyPiece piece, {required String result,
    required String notes, required bool completed, required String scoreEntry}) async {
    final db = await databaseLoader();
    final hasEntry = result.trim().isNotEmpty || notes.trim().isNotEmpty || completed || scoreEntry.isNotEmpty;
    final count = await db.update('fitr_pieces', {
      'result': result, 'notes': notes, 'completed': completed ? 1 : 0,
      'score_entry_json': scoreEntry,
      'prescription_snapshot': piece.prescriptionSnapshot ?? (hasEntry ? piece.calculations : null),
    }, where: 'id = ?', whereArgs: [piece.id]);
    if (count != 1) throw StateError('This workout piece could not be found.');
  }

  Future<void> saveEntry(String id, {required String result, required String notes, required bool completed}) async {
    final db = await databaseLoader();
    final count = await db.update('fitr_pieces', {'result': result, 'notes': notes, 'completed': completed ? 1 : 0},
      where: 'id = ?', whereArgs: [id]);
    if (count != 1) throw StateError('This workout piece could not be found. Your entry was not saved.');
  }
}
