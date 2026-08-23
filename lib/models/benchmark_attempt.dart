class BenchmarkAttempt {
  final String benchmarkId;
  final DateTime date;

  /// Primary benchmark score stored in a normalized display-friendly form.
  ///
  /// Examples:
  /// - "32:29"
  /// - "5+74"
  /// - "316"
  /// - "183"
  final String score;

  /// Historical source workbook.
  ///
  /// Empty for attempts logged directly in the app.
  final String sourceWorkbook;

  /// Historical program-position identifier such as W6D2.
  ///
  /// Empty for attempts logged directly in the app.
  final String programDay;

  /// Optional supporting result details.
  ///
  /// Examples:
  /// - per-round calories/RPM/watts for Cube Tests
  /// - average pace and calories/hour for M.A.T.T.
  /// - partial failed round details for Mount Doom
  final String details;

  final String notes;

  const BenchmarkAttempt({
    required this.benchmarkId,
    required this.date,
    required this.score,
    this.sourceWorkbook = '',
    this.programDay = '',
    this.details = '',
    this.notes = '',
  });

  Map<String, dynamic> toJson() {
    return {
      'benchmarkId': benchmarkId,
      'date': date.toIso8601String(),
      'score': score,
      'sourceWorkbook': sourceWorkbook,
      'programDay': programDay,
      'details': details,
      'notes': notes,
    };
  }

  factory BenchmarkAttempt.fromDatabaseMap(Map<String, Object?> row) {
    return BenchmarkAttempt(
      benchmarkId: row['benchmark_id'] as String,
      date: DateTime.parse(row['attempt_date'] as String),
      score: row['score'] as String,
      sourceWorkbook: (row['source_workbook'] as String?) ?? '',
      programDay: (row['program_day'] as String?) ?? '',
      details: (row['details'] as String?) ?? '',
      notes: (row['notes'] as String?) ?? '',
    );
  }

  factory BenchmarkAttempt.fromJson(Map<String, dynamic> json) {
    return BenchmarkAttempt(
      benchmarkId: json['benchmarkId'] as String,
      date: DateTime.parse(json['date'] as String),
      score: json['score'] as String,
      sourceWorkbook: (json['sourceWorkbook'] as String?) ?? '',
      programDay: (json['programDay'] as String?) ?? '',
      details: (json['details'] as String?) ?? '',
      notes: (json['notes'] as String?) ?? '',
    );
  }
}
