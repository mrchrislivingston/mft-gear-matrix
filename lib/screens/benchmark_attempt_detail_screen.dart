import 'package:flutter/material.dart';

import '../models/benchmark.dart';
import '../models/benchmark_attempt.dart';

class BenchmarkAttemptDetailScreen extends StatelessWidget {
  final Benchmark benchmark;
  final BenchmarkAttempt attempt;

  const BenchmarkAttemptDetailScreen({
    super.key,
    required this.benchmark,
    required this.attempt,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(benchmark.name)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            attempt.score,
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: 8),
          Text(
            benchmark.scoreType.displayName,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 24),
          _DetailRow(label: 'Date', value: _formatDate(attempt.date)),
          if (attempt.programDay.isNotEmpty)
            _DetailRow(label: 'Program Day', value: attempt.programDay),
          if (attempt.details.isNotEmpty)
            _DetailSection(label: 'Details', value: attempt.details),
          if (attempt.notes.isNotEmpty)
            _DetailSection(label: 'Notes', value: attempt.notes),
          if (attempt.sourceWorkbook.isNotEmpty)
            _DetailSection(label: 'Source', value: attempt.sourceWorkbook),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: Theme.of(context).textTheme.titleSmall),
          ),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }
}

class _DetailSection extends StatelessWidget {
  final String label;
  final String value;

  const _DetailSection({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Text(value),
        ],
      ),
    );
  }
}
