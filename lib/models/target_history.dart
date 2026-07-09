class TargetHistory {
  final String lowTarget;
  final String highTarget;
  final DateTime effectiveDate;

  const TargetHistory({
    required this.lowTarget,
    required this.highTarget,
    required this.effectiveDate,
  });

  String get displayTarget => '$lowTarget–$highTarget';

  Map<String, dynamic> toJson() {
    return {
      'lowTarget': lowTarget,
      'highTarget': highTarget,
      'effectiveDate': effectiveDate.toIso8601String(),
    };
  }

  factory TargetHistory.fromJson(Map<String, dynamic> json) {
    return TargetHistory(
      lowTarget: json['lowTarget'],
      highTarget: json['highTarget'],
      effectiveDate: DateTime.parse(json['effectiveDate']),
    );
  }
}