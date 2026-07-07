import '../models/log_entry.dart';

class AppState {
  AppState._();

  static final AppState instance = AppState._();

  final List<LogEntry> logs = [];

  void addLog(LogEntry log) {
    logs.add(log);
  }
}