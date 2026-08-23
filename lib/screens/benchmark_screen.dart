import 'package:flutter/material.dart';

import '../services/app_state.dart';

import 'benchmark_detail_screen.dart';

class BenchmarkScreen extends StatelessWidget {
  const BenchmarkScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final benchmarks = AppState.instance.benchmarks;

    return Scaffold(
      appBar: AppBar(title: const Text('Benchmarks')),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: benchmarks.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final benchmark = benchmarks[index];

          return Card(
            child: ListTile(
              title: Text(benchmark.name),
              subtitle: Text(benchmark.scoreType.displayName),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BenchmarkDetailScreen(benchmark: benchmark),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
