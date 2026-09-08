import 'package:flutter/material.dart';
import '../models/benchmark.dart';
import '../models/benchmark_attempt.dart';
import '../services/benchmark_analysis_service.dart';
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
            return const Center(
              child: Text('Unable to load benchmark history.'),
            );
          }

          final attempts = snapshot.data ?? [];
          final analysis = const BenchmarkAnalysisService().analyze(
            scoreType: benchmark.scoreType,
            attempts: attempts,
          );

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Text(
                benchmark.scoreType.displayName,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              if (benchmark.description.trim().isNotEmpty) ...[
                const SizedBox(height: 20),
                Text(
                  benchmark.description.trim(),
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
              ],
              if (analysis.hasAttempts) ...[
                const SizedBox(height: 24),
                _AnalysisCard(analysis: analysis),
              ],
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

class _AnalysisCard extends StatelessWidget {
  final BenchmarkAnalysis analysis;

  const _AnalysisCard({required this.analysis});

  @override
  Widget build(BuildContext context) {
    final latest = analysis.latest!;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Performance', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 14),
            _AnalysisRow(
              label: 'Latest',
              value: '${latest.score} • ${_formatDate(latest.date)}',
            ),
            if (analysis.best != null)
              _AnalysisRow(
                label: 'Personal best',
                value:
                    '${analysis.best!.score} • '
                    '${_formatDate(analysis.best!.date)}',
              ),
            if (analysis.previous != null)
              _AnalysisRow(
                label: 'Previous',
                value:
                    '${analysis.previous!.score} • '
                    '${_formatDate(analysis.previous!.date)}',
              ),
            _AnalysisRow(
              label: 'Trend',
              value: analysis.trendLabel,
              valueColor: _trendColor(context, analysis.trend),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  static Color? _trendColor(BuildContext context, BenchmarkTrend trend) {
    return switch (trend) {
      BenchmarkTrend.improved => Colors.green,
      BenchmarkTrend.declined => Theme.of(context).colorScheme.error,
      BenchmarkTrend.tied || BenchmarkTrend.unavailable => null,
    };
  }
}

class _AnalysisRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _AnalysisRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(label, style: Theme.of(context).textTheme.titleSmall),
          ),
          Expanded(
            child: Text(value, style: TextStyle(color: valueColor)),
          ),
        ],
      ),
    );
  }
}
