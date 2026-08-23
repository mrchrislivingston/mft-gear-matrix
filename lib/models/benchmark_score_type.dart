enum BenchmarkScoreType {
  time,
  roundsReps,
  calories,
  averageWatts,
  load,
  reps,
  distance;

  String get storageKey {
    return name;
  }

  String get displayName {
    switch (this) {
      case BenchmarkScoreType.time:
        return 'Time';
      case BenchmarkScoreType.roundsReps:
        return 'Rounds + Reps';
      case BenchmarkScoreType.calories:
        return 'Calories';
      case BenchmarkScoreType.averageWatts:
        return 'Average Watts';
      case BenchmarkScoreType.load:
        return 'Load';
      case BenchmarkScoreType.reps:
        return 'Reps';
      case BenchmarkScoreType.distance:
        return 'Distance';
    }
  }
}
