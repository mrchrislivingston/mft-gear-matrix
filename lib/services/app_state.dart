import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../models/log_entry.dart';

class AppState {
  AppState._();

  static final AppState instance = AppState._();

  static const String _logsKey = 'workout_logs';

  final List<LogEntry> logs = [];

  Future<void> loadLogs() async {
    final prefs = await SharedPreferences.getInstance();
    final rawLogs = prefs.getStringList(_logsKey) ?? [];
    print('Loaded raw logs found: ${rawLogs.length}');
    
    logs
      ..clear()
      ..addAll(
        rawLogs.map((rawLog) {
          final json = jsonDecode(rawLog) as Map<String, dynamic>;
          return LogEntry.fromJson(json);
        }),
      );
  }

  Future<void> addLog(LogEntry log) async {
    logs.add(log);
    await _saveLogs();
  }

  Future<void> _saveLogs() async {
    final prefs = await SharedPreferences.getInstance();

    final rawLogs = logs.map((log) {
      return jsonEncode(log.toJson());
    }).toList();

    print('Saving ${logs.length} logs');
    await prefs.setStringList(_logsKey, rawLogs);

    final savedLogs = prefs.getStringList(_logsKey) ?? [];
    print('Saved logs found: ${savedLogs.length}');
  }
}