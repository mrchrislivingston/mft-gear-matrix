enum BenchmarkCategory {
  powerOutput,
  machineBenchmark,
  weightlifting,
  namedMetcon,
  skillChipper;

  String get storageKey => name;

  String get displayName {
    return switch (this) {
      BenchmarkCategory.powerOutput => 'Power Output',
      BenchmarkCategory.machineBenchmark => 'Machine Benchmarks',
      BenchmarkCategory.weightlifting => 'Weightlifting 1RM',
      BenchmarkCategory.namedMetcon => 'Named Metcons',
      BenchmarkCategory.skillChipper => 'Skill Chippers',
    };
  }
}
