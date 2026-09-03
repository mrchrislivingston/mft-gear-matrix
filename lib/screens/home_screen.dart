import 'package:flutter/material.dart';

import 'benchmark_screen.dart';
import 'history_screen.dart';
import 'import_history_screen.dart';
import 'matrix_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Chris Livingston')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Base Phase', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 30),
            _HomeButton(
              label: 'Matrix',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MatrixScreen()),
                );
              },
            ),
            const SizedBox(height: 10),
            _HomeButton(
              label: 'Benchmarks',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const BenchmarkScreen()),
                );
              },
            ),
            const SizedBox(height: 10),
            _HomeButton(label: 'Weightlifting', onTap: () {}),
            const SizedBox(height: 10),
            _HomeButton(
              label: 'History',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HistoryScreen()),
                );
              },
            ),
            const SizedBox(height: 10),
            _HomeButton(
              label: 'Import Misfit History',
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => const ImportHistoryScreen(),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _HomeButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _HomeButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(onPressed: onTap, child: Text(label)),
    );
  }
}
