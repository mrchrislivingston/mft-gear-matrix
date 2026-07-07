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
}