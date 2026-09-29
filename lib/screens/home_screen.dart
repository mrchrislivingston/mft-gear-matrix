import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'benchmark_screen.dart';
import 'fitr_daily_screen.dart';
import 'working_max_screen.dart';
import 'database_restore_screen.dart';
import 'database_export_screen.dart';
import 'daily_results_import_screen.dart';
import 'fitr_mobile_preview_screen.dart';
import 'garmin_calendar_screen.dart';
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
        child: ListView(
          children: [
            const Text('Base Phase', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 30),
            if (!kIsWeb) ...[
              _HomeButton(label: 'Training Week', onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const FitrDailyScreen()))),
              const SizedBox(height: 10),
            ],
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
            _HomeButton(label: 'Working 1RMs', onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const WorkingMaxScreen()))),
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
            if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) ...[
              _HomeButton(
                label: 'FITR → Garmin Calendar',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const GarminCalendarScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
            if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) ...[
              _HomeButton(
                label: 'FITR → Garmin Calendar',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const FitrMobilePreviewScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
              _HomeButton(
                label: 'Restore Database',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const DatabaseRestoreScreen(),
                    ),
                  );
                },
              ),
              const SizedBox(height: 10),
            ],
            if (!kIsWeb) ...[
              _HomeButton(label: 'Import results', onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const DailyResultsImportScreen()))),
              const SizedBox(height: 10),
              _HomeButton(
                label: 'Export Database',
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DatabaseExportScreen()),
                ),
              ),
              const SizedBox(height: 10),
            ],
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
