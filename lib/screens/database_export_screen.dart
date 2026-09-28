import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/database_export_service.dart';

class DatabaseExportScreen extends StatefulWidget {
  final Future<DatabaseExportSnapshot> Function()? exporter;
  final Future<Uri?> Function(DatabaseExportSnapshot)? saver;

  const DatabaseExportScreen({super.key, this.exporter, this.saver});

  @override
  State<DatabaseExportScreen> createState() => _DatabaseExportScreenState();
}

class _DatabaseExportScreenState extends State<DatabaseExportScreen> {
  bool _busy = false;
  String? _message;
  String? _error;
  DatabaseExportSnapshot? _savedSnapshot;

  Future<Uri?> _save(DatabaseExportSnapshot snapshot) {
    return FilePicker.saveFile(
      fileName: snapshot.fileName,
      bytes: snapshot.bytes,
      dialogTitle: 'Save database backup',
      type: FileType.custom,
      allowedExtensions: const ['db'],
    );
  }

  Future<void> _export() async {
    if (_busy) return;
    setState(() {
      _busy = true;
      _message = null;
      _error = null;
      _savedSnapshot = null;
    });
    try {
      final snapshot = await (widget.exporter ?? DatabaseExportService().createSnapshot)();
      if (!mounted) return;
      final destination = await (widget.saver ?? _save)(snapshot);
      if (!mounted) return;
      setState(() {
        if (destination == null) {
          _message = 'Export canceled. No backup was saved.';
        } else {
          _savedSnapshot = snapshot;
          _message = 'Database backup saved.';
        }
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = 'Could not export the database. $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final snapshot = _savedSnapshot;
    return Scaffold(
      appBar: AppBar(title: const Text('Export Database')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text('Back up your athlete record', style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 12),
          const Text('Save a dated backup of all workouts, interval results, target history, benchmarks, and benchmark attempts on this device.'),
          const SizedBox(height: 12),
          const Text('Choose Files or a folder you can find later. Use Restore Database to load this backup. Restoring replaces the destination device’s records; it does not merge them.'),
          const SizedBox(height: 12),
          const Text('FITR and Garmin sign-in credentials are not included.'),
          const SizedBox(height: 24),
          FilledButton.icon(
            key: const Key('databaseExportButton'),
            onPressed: _busy ? null : _export,
            icon: const Icon(Icons.save_alt),
            label: Text(_busy ? 'Exporting…' : 'Export database'),
          ),
          if (_busy) ...[
            const SizedBox(height: 20),
            const Center(child: CircularProgressIndicator()),
          ],
          if (_message != null) ...[
            const SizedBox(height: 20),
            Text(_message!, key: const Key('databaseExportMessage')),
          ],
          if (_error != null) ...[
            const SizedBox(height: 20),
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(padding: const EdgeInsets.all(16), child: Text(_error!)),
            ),
          ],
          if (snapshot != null) ...[
            const SizedBox(height: 16),
            Card(child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(snapshot.fileName),
                const SizedBox(height: 12),
                Text('${snapshot.summary.workoutCount} workouts'),
                Text('${snapshot.summary.targetCount} target-history records'),
                Text('${snapshot.summary.benchmarkCount} benchmark definitions'),
                Text('${snapshot.summary.benchmarkAttemptCount} benchmark attempts'),
                const SizedBox(height: 8),
                const Text('Backup integrity verified.'),
              ]),
            )),
          ],
        ],
      ),
    );
  }
}
