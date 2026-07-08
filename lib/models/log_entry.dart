class IntervalResult {
  final int intervalNumber;
  final String distance;
  final String avgPace;
  final String avgHr;
  final String rpe;

  const IntervalResult({
    required this.intervalNumber,
    required this.distance,
    required this.avgPace,
    required this.avgHr,
    required this.rpe,
  });

  Map<String, dynamic> toJson() {
    return {
      'intervalNumber': intervalNumber,
      'distance': distance,
      'avgPace': avgPace,
      'avgHr': avgHr,
      'rpe': rpe,
    };
  }

  factory IntervalResult.fromJson(Map<String, dynamic> json) {
    return IntervalResult(
      intervalNumber: json['intervalNumber'] as int,
      distance: json['distance'] as String,
      avgPace: json['avgPace'] as String,
      avgHr: json['avgHr'] as String,
      rpe: json['rpe'] as String,
    );
  }
}

class LogEntry {
  final int gearNumber;
  final DateTime date;
  final String notes;
  final List<IntervalResult> intervals;

  const LogEntry({
    required this.gearNumber,
    required this.date,
    required this.notes,
    required this.intervals,
  });

  Map<String, dynamic> toJson() {
    return {
      'gearNumber': gearNumber,
      'date': date.toIso8601String(),
      'notes': notes,
      'intervals': intervals.map((interval) => interval.toJson()).toList(),
    };
  }

  factory LogEntry.fromJson(Map<String, dynamic> json) {
    return LogEntry(
      gearNumber: json['gearNumber'] as int,
      date: DateTime.parse(json['date'] as String),
      notes: json['notes'] as String,
      intervals: (json['intervals'] as List)
          .map((item) => IntervalResult.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}