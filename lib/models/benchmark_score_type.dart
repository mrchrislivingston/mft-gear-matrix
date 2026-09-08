enum BenchmarkScoreType {
  forTime,
  roundsReps,
  totalCalories,
  averageWatts,
  maxWeight,
  slowestIntervalTime,
  totalLoad,
  totalReps,
  totalDistance,
  lowestIntervalCalories,
  lowestIntervalWatts,
  lowestIntervalDistance,
  unconfigured;

  String get storageKey {
    return name;
  }

  String get displayName {
    switch (this) {
      case BenchmarkScoreType.forTime:
        return 'For Time';
      case BenchmarkScoreType.roundsReps:
        return 'Rounds + Reps';
      case BenchmarkScoreType.totalCalories:
        return 'Total Calories';
      case BenchmarkScoreType.averageWatts:
        return 'Average Watts';
      case BenchmarkScoreType.maxWeight:
        return 'Max Weight';
      case BenchmarkScoreType.slowestIntervalTime:
        return 'Slowest Interval Time';
      case BenchmarkScoreType.totalLoad:
        return 'Total Load';
      case BenchmarkScoreType.totalReps:
        return 'Total Reps';
      case BenchmarkScoreType.totalDistance:
        return 'Total Distance';
      case BenchmarkScoreType.lowestIntervalCalories:
        return 'Lowest Interval Calories';
      case BenchmarkScoreType.lowestIntervalWatts:
        return 'Lowest Interval Watts';
      case BenchmarkScoreType.lowestIntervalDistance:
        return 'Lowest Interval Distance';
      case BenchmarkScoreType.unconfigured:
        return 'Scoring details pending';
    }
  }
}
