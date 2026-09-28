import 'dart:math' as math;
import 'package:sqflite/sqflite.dart';
import 'database_service.dart';

const fitrLiftIds = {
  '1RM_BACKSQ': 'back_squat_1rm', '1RM_CLEAN': 'squat_clean_1rm',
  '1RM_STPRESS': 'strict_press_1rm', '1RM_SNATCH': 'squat_snatch_1rm',
  '1RM_BPRESS': 'bench_press_1rm',
};
const workingLiftNames = {
  'back_squat_1rm': 'Back Squat', 'strict_press_1rm': 'Strict Press',
  'deadlift_1rm': 'Deadlift', 'bench_press_1rm': 'Bench Press',
  'squat_clean_1rm': 'Squat Clean', 'overhead_squat_1rm': 'Overhead Squat',
  'front_squat_1rm': 'Front Squat', 'power_snatch_1rm': 'Power Snatch',
  'power_clean_1rm': 'Power Clean', 'squat_snatch_1rm': 'Squat Snatch',
  'split_jerk_1rm': 'Split Jerk', 'push_jerk_1rm': 'Push Jerk',
  'clean_and_jerk_1rm': 'Clean and Jerk', 'push_press_1rm': 'Push Press',
};
String? fitrLiftId(String code, List<dynamic> benchmarks) {
  if (fitrLiftIds.containsKey(code)) return fitrLiftIds[code];
  for (final benchmark in benchmarks.whereType<Map>()) {
    if (benchmark['code'] != code) continue;
    final name = benchmark['name']?.toString().trim().toLowerCase()
        .replaceFirst(RegExp(r'^1rm\s+'), '');
    for (final entry in workingLiftNames.entries) {
      if (entry.value.toLowerCase() == name) return entry.key;
    }
  }
  return null;
}

String weightText(double n) => n.toStringAsFixed(2).replaceFirst(RegExp(r'\.?0+$'), '');
String maxDate(DateTime d) => d.toIso8601String().substring(0, 10);
DateTime sixMonthsBefore(DateTime date) {
  final first = DateTime(date.year, date.month - 6, 1);
  final lastDay = DateTime(first.year, first.month + 1, 0).day;
  return DateTime(first.year, first.month, math.min(date.day, lastDay));
}

class WorkingMax {
  final double pounds;
  final DateTime date;
  final String source;
  const WorkingMax(this.pounds, this.date, this.source);
}

double? parseLiftPounds(String text) {
  final match = RegExp(r'^\s*(\d+(?:\.\d+)?)\s*(lb[s]?|kg)?\s*$', caseSensitive: false).firstMatch(text);
  if (match == null) return null;
  final value = double.parse(match.group(1)!);
  if (value <= 0 || !value.isFinite) return null;
  return match.group(2)?.toLowerCase() == 'kg' ? value * 2.20462262185 : value;
}

WorkingMax? resolveWorkingMax({required String liftId, required DateTime asOf,
  required List<Map<String, Object?>> attempts, required List<Map<String, Object?>> overrides,
  List<dynamic> fitrBenchmarks = const []}) {
  final date = DateTime(asOf.year, asOf.month, asOf.day);
  final manual = overrides.where((r) => r['lift_id'] == liftId &&
    !(DateTime.tryParse(r['effective_date'].toString()) ?? DateTime(9999)).isAfter(date)).toList()
    ..sort((a,b) { final c = b['effective_date'].toString().compareTo(a['effective_date'].toString());
      return c != 0 ? c : (b['id'] as int).compareTo(a['id'] as int); });
  if (manual.isNotEmpty && manual.first['pounds'] is num) {
    return WorkingMax((manual.first['pounds'] as num).toDouble(), DateTime.parse(manual.first['effective_date'] as String), 'Manual working max');
  }
  final candidates = <WorkingMax>[];
  void add(double? pounds, String? rawDate, String source) {
    final parsed = DateTime.tryParse(rawDate ?? '');
    if (pounds == null || parsed == null || pounds <= 0 || !pounds.isFinite) return;
    final tested = DateTime(parsed.year, parsed.month, parsed.day);
    if (!tested.isAfter(date) && !tested.isBefore(sixMonthsBefore(date))) candidates.add(WorkingMax(pounds, tested, source));
  }
  for (final row in attempts.where((a) => a['benchmark_id'] == liftId)) {
    add(parseLiftPounds(row['score'].toString()), row['attempt_date']?.toString(), 'Recent local 1RM');
  }
  for (final b in fitrBenchmarks.whereType<Map>()) {
    if (fitrLiftId(b['code']?.toString() ?? '', fitrBenchmarks) != liftId) continue;
    final v = b['last_value'];
    if (v is! Map || v['value'] is! num) continue;
    final value = (v['value'] as num).toDouble();
    final unit = v['units'] ?? b['units'];
    final pounds = switch (unit) {
      'gram' => value / 453.59237,
      'kg' || 'kilogram' => value * 2.20462262185,
      'lb' || 'lbs' || 'pound' => value,
      _ => null,
    };
    // FITR stores whole grams, which can introduce tiny conversion errors.
    add(pounds == null ? null : (pounds * 100).round() / 100, v['date']?.toString(), 'Recent FITR 1RM');
  }
  candidates.sort((a,b) { final dateOrder = b.date.compareTo(a.date);
    return dateOrder != 0 ? dateOrder : (a.source == 'Recent local 1RM' ? -1 : b.source == 'Recent local 1RM' ? 1 : 0);
  });
  return candidates.isEmpty ? null : candidates.first;
}

String percentageCalculations(String description, {required DateTime asOf,
  required List<Map<String, Object?>> attempts, required List<Map<String, Object?>> overrides,
  List<dynamic> fitrBenchmarks = const []}) {
  final lines = <String>[];
  final seen = <String>{};
  for (final token in RegExp(r'@(\d+(?:\.\d+)?)%([A-Za-z0-9_]+)').allMatches(description)) {
    if (!seen.add(token.group(0)!)) continue;
    final code = token.group(2)!;
    final lift = fitrLiftId(code, fitrBenchmarks);
    if (lift == null) { lines.add('$code: percentage reference not mapped yet.'); continue; }
    final max = resolveWorkingMax(liftId: lift, asOf: asOf, attempts: attempts,
      overrides: overrides, fitrBenchmarks: fitrBenchmarks);
    final name = workingLiftNames[lift]!;
    if (max == null) { lines.add('$name: set a working 1RM; no recorded max within six months.'); continue; }
    final percent = double.parse(token.group(1)!);
    final weight = max.pounds * percent / 100;
    lines.add('$name: ${weightText(percent)}% × ${weightText(max.pounds)} lb = ${weightText(weight)} lb\n'
      '${max.source} • ${maxDate(max.date)}');
  }
  return lines.join('\n\n');
}

// Render from the calculation snapshot so logged sessions keep their original weights.
String readablePrescription(String description, String calculations,
    {List<dynamic> fitrBenchmarks = const []}) {
  final tokenPattern = RegExp(r'@(\d+(?:\.\d+)?)%([A-Za-z0-9_]+)');
  var text = description;
  // FITR often supplies both a plain percentage and its machine reference.
  text = text.replaceAllMapped(
    RegExp(r'@(\d+(?:\.\d+)?)%[ \t]+@(\d+(?:\.\d+)?)%([A-Za-z0-9_]+)'),
    (m) => double.parse(m[1]!) == double.parse(m[2]!)
        ? '@${m[2]}%${m[3]}' : m[0]!,
  );
  return text.replaceAllMapped(tokenPattern, (token) {
    final percent = weightText(double.parse(token[1]!));
    final lift = fitrLiftId(token[2]!, fitrBenchmarks);
    final name = workingLiftNames[lift];
    if (name == null) return '@$percent% (unmapped 1RM)';
    final calculation = RegExp(
      '${RegExp.escape(name)}: ${RegExp.escape(percent)}% × [0-9.]+ lb = ([0-9.]+) lb',
    ).firstMatch(calculations);
    return calculation == null ? '@$percent% (set working 1RM)' : '@$percent% → ${calculation[1]} lb';
  });
}

class WorkingMaxService {
  final Future<Database> Function() databaseLoader;
  WorkingMaxService({Future<Database> Function()? databaseLoader})
    : databaseLoader = databaseLoader ?? (() => DatabaseService.instance.database);
  Future<List<Map<String, Object?>>> history() async => (await databaseLoader()).query('working_max_history', orderBy: 'effective_date DESC, id DESC');
  Future<void> save(String lift, double? pounds, DateTime effectiveDate) async {
    if (!workingLiftNames.containsKey(lift) || (pounds != null && (!pounds.isFinite || pounds <= 0))) throw ArgumentError('Enter a positive working max.');
    await (await databaseLoader()).insert('working_max_history', {
      'lift_id': lift, 'pounds': pounds, 'effective_date': maxDate(effectiveDate),
    });
  }
}
