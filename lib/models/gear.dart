class Gear {
  final int number;
  final String work;
  final String rest;
  final int intervals;
  final String? targetLowPace;
  final String? targetHighPace;

  const Gear({
    required this.number,
    required this.work,
    required this.rest,
    required this.intervals,
    this.targetLowPace,
    this.targetHighPace,
  });

  String get targetPaceDisplay {
    if (targetLowPace == null || targetHighPace == null) {
      return 'No target set';
    }

    return '$targetLowPace–$targetHighPace';
  }
}