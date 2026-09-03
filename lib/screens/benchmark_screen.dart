import 'package:flutter/material.dart';

import '../services/app_state.dart';
import '../services/database_service.dart';
import 'benchmark_detail_screen.dart';

typedef BenchmarkAttemptCountsLoader = Future<Map<String, int>> Function();

class BenchmarkScreen extends StatefulWidget {
  final BenchmarkAttemptCountsLoader? attemptCountsLoader;

  const BenchmarkScreen({super.key, this.attemptCountsLoader});

  @override
  State<BenchmarkScreen> createState() => _BenchmarkScreenState();
}

class _BenchmarkScreenState extends State<BenchmarkScreen> {
  late Future<Map<String, int>> _attemptCountsFuture;

  @override
  void initState() {
    super.initState();
    _loadAttemptCounts();
  }

  void _loadAttemptCounts() {
    _attemptCountsFuture =
        widget.attemptCountsLoader?.call() ??
        DatabaseService.instance.getBenchmarkAttemptCounts();
  }

  String _subtitle({required String scoreType, required int attemptCount}) {
    final attemptLabel = attemptCount == 1 ? 'attempt' : 'attempts';

    return '$scoreType • $attemptCount $attemptLabel';
  }

  @override
  Widget build(BuildContext context) {
    final benchmarks = AppState.instance.benchmarks;

    return Scaffold(
      appBar: AppBar(title: const Text('Benchmarks')),
      body: FutureBuilder<Map<String, int>>(
        future: _attemptCountsFuture,
        builder: (context, snapshot) {
          final attemptCounts = snapshot.data ?? const <String, int>{};
          final showCounts = snapshot.hasData;

          return ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: benchmarks.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, index) {
              final benchmark = benchmarks[index];
              final attemptCount = attemptCounts[benchmark.id] ?? 0;

              return Card(
                child: ListTile(
                  title: Text(benchmark.name),
                  subtitle: Text(
                    showCounts
                        ? _subtitle(
                            scoreType: benchmark.scoreType.displayName,
                            attemptCount: attemptCount,
                          )
                        : benchmark.scoreType.displayName,
                  ),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            BenchmarkDetailScreen(benchmark: benchmark),
                      ),
                    );

                    if (!context.mounted) {
                      return;
                    }

                    setState(_loadAttemptCounts);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
