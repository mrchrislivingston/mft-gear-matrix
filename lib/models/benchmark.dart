import 'benchmark_category.dart';
import 'benchmark_score_type.dart';

class Benchmark {
  final String id;
  final String name;
  final String description;
  final BenchmarkScoreType scoreType;
  final BenchmarkCategory category;

  const Benchmark({
    required this.id,
    required this.name,
    required this.description,
    required this.scoreType,
    required this.category,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'scoreType': scoreType.name,
      'category': category.name,
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
      category: BenchmarkCategory.values.firstWhere(
        (item) => item.storageKey == row['category'],
        orElse: () => BenchmarkCategory.machineBenchmark,
      ),
    );
  }

  factory Benchmark.fromJson(Map<String, dynamic> json) {
    return Benchmark(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      scoreType: BenchmarkScoreType.values.byName(json['scoreType'] as String),
      category: BenchmarkCategory.values.byName(json['category'] as String),
    );
  }
}
