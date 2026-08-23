import 'benchmark_score_type.dart';

class Benchmark {
  final String id;
  final String name;
  final String description;
  final BenchmarkScoreType scoreType;

  const Benchmark({
    required this.id,
    required this.name,
    required this.description,
    required this.scoreType,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'scoreType': scoreType.name,
    };
  }

  factory Benchmark.fromDatabaseMap(Map<String, Object?> row) {
    return Benchmark(
      id: row['id'] as String,
      name: row['name'] as String,
      description: (row['description'] as String?) ?? '',
      scoreType: BenchmarkScoreType.values.firstWhere(
        (item) => item.storageKey == row['score_type'],
      ),
    );
  }

  factory Benchmark.fromJson(Map<String, dynamic> json) {
    return Benchmark(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      scoreType: BenchmarkScoreType.values.byName(json['scoreType'] as String),
    );
  }
}
