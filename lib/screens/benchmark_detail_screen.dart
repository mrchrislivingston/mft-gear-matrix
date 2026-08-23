import 'package:flutter/material.dart';

import '../models/benchmark.dart';
import '../models/benchmark_attempt.dart';
import '../services/database_service.dart';

import 'benchmark_attempt_detail_screen.dart';

class BenchmarkDetailScreen extends StatelessWidget {
  final Benchmark benchmark;

  const BenchmarkDetailScreen({super.key, required this.benchmark});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(benchmark.name)),
      body: FutureBuilder<List<BenchmarkAttempt>>(
        future: DatabaseService.instance.getBenchmarkAttempts(
          benchmarkId: benchmark.id,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Unable to load benchmark history.'));
          }

          final attempts = snapshot.data ?? [];

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                benchmark.scoreType.displayName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 20),
              Text(
                benchmark.description.trim(),
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 32),
              Text('History', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 12),
              if (attempts.isEmpty)
                const Text('No attempts recorded.')
              else
                ...attempts.map(
                  (attempt) => Card(
                    child: ListTile(
                      title: Text(attempt.score),
                      subtitle: Text(_attemptSubtitle(attempt)),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BenchmarkAttemptDetailScreen(
                              benchmark: benchmark,
                              attempt: attempt,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  String _attemptSubtitle(BenchmarkAttempt attempt) {
    final date =
        '${attempt.date.month}/${attempt.date.day}/${attempt.date.year}';

    if (attempt.programDay.isEmpty) {
      return date;
    }

    return '$date • ${attempt.programDay}';
  }
}
