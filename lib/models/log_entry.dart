class LogEntry {
  final int gearNumber;
  final DateTime date;
  final String actualWork;
  final String actualRest;
  final String notes;
  final bool success;

  const LogEntry({
    required this.gearNumber,
    required this.date,
    required this.actualWork,
    required this.actualRest,
    required this.notes,
    required this.success,
  });
}