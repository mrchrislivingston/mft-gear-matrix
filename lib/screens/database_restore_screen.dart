import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../services/app_state.dart';
import '../services/database_restore_service.dart';

class SelectedDatabaseFile {
  final String name;
  final Uint8List bytes;

  const SelectedDatabaseFile({required this.name, required this.bytes});
}

typedef DatabaseFilePicker = Future<SelectedDatabaseFile?> Function();
typedef DatabaseValidator =
    Future<DatabaseSnapshotSummary> Function(Uint8List bytes);
typedef DatabaseRestorer =
    Future<DatabaseRestoreResult> Function(Uint8List bytes);

class DatabaseRestoreScreen extends StatefulWidget {
  final DatabaseFilePicker? filePicker;
  final DatabaseValidator? validator;
  final DatabaseRestorer? restorer;
  final Future<void> Function()? reloadAppState;

  const DatabaseRestoreScreen({
    super.key,
    this.filePicker,
    this.validator,
    this.restorer,
    this.reloadAppState,
  });

  @override
  State<DatabaseRestoreScreen> createState() {
    return _DatabaseRestoreScreenState();
  }
}

class _DatabaseRestoreScreenState extends State<DatabaseRestoreScreen> {
  late final DatabaseFilePicker _filePicker;
  late final DatabaseValidator _validator;
  late final DatabaseRestorer _restorer;
  late final Future<void> Function() _reloadAppState;

  SelectedDatabaseFile? _selectedFile;
  DatabaseSnapshotSummary? _summary;
  String? _errorMessage;
  String? _successMessage;
  bool _acknowledged = false;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();

    DatabaseRestoreService? restoreService;

    DatabaseRestoreService defaultRestoreService() {
      return restoreService ??= DatabaseRestoreService();
    }

    _filePicker = widget.filePicker ?? _pickDatabase;
    _validator =
        widget.validator ??
        (bytes) => defaultRestoreService().validateBytes(bytes);
    _restorer =
        widget.restorer ??
        (bytes) => defaultRestoreService().restoreBytes(bytes);
    _reloadAppState = widget.reloadAppState ?? AppState.instance.loadLogs;
  }

  Future<SelectedDatabaseFile?> _pickDatabase() async {
    final file = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: const ['db'],
    );

    if (file == null) {
      return null;
    }

    return SelectedDatabaseFile(
      name: file.name,
      bytes: Uint8List.fromList(await file.readAsBytes()),
    );
  }

  Future<void> _selectAndValidate() async {
    setState(() {
      _isBusy = true;
      _selectedFile = null;
      _summary = null;
      _errorMessage = null;
      _successMessage = null;
      _acknowledged = false;
    });

    try {
      final selectedFile = await _filePicker();

      if (selectedFile == null) {
        return;
      }

      final summary = await _validator(selectedFile.bytes);

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedFile = selectedFile;
        _summary = summary;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  Future<void> _confirmRestore() async {
    final selectedFile = _selectedFile;

    if (selectedFile == null || _summary == null || !_acknowledged) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Replace this phone’s database?'),
          content: Text(
            'This will replace the local MFT Gear Matrix database with '
            '${selectedFile.name}. The current phone database will be backed '
            'up automatically.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              key: const Key('databaseRestoreDialogConfirm'),
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Restore database'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isBusy = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final result = await _restorer(selectedFile.bytes);
      await _reloadAppState();

      if (!mounted) {
        return;
      }

      setState(() {
        _summary = result.snapshot;
        _successMessage =
            'Database restored successfully. The previous phone database '
            'was backed up automatically.';
        _acknowledged = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _errorMessage = error.toString();
      });
    } finally {
      if (mounted) {
        setState(() {
          _isBusy = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final summary = _summary;

    return Scaffold(
      appBar: AppBar(title: const Text('Restore Database')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Text(
            'Restore athlete record',
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose an MFT Gear Matrix database backup. The file will be '
            'validated before the phone’s local database can be replaced.',
          ),
          const SizedBox(height: 16),
          Card(
            color: Theme.of(context).colorScheme.errorContainer,
            child: const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Restore replaces the workouts, targets, benchmarks, and '
                'benchmark attempts currently stored on this phone.',
              ),
            ),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            key: const Key('databaseSelectButton'),
            onPressed: _isBusy ? null : _selectAndValidate,
            icon: const Icon(Icons.folder_open),
            label: const Text('Select database backup'),
          ),
          if (_isBusy) ...[
            const SizedBox(height: 20),
            const Center(child: CircularProgressIndicator()),
          ],
          if (_errorMessage != null) ...[
            const SizedBox(height: 16),
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_errorMessage!),
              ),
            ),
          ],
          if (summary != null && _selectedFile != null) ...[
            const SizedBox(height: 20),
            Text(
              'Validated backup',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _selectedFile!.name,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    Text('Schema version ${summary.schemaVersion}'),
                    Text('${summary.workoutCount} workouts'),
                    Text('${summary.targetCount} target-history records'),
                    Text('${summary.benchmarkCount} benchmark definitions'),
                    Text('${summary.benchmarkAttemptCount} benchmark attempts'),
                    const SizedBox(height: 8),
                    const Text('Integrity check: OK'),
                  ],
                ),
              ),
            ),
            CheckboxListTile(
              key: const Key('databaseRestoreAcknowledgement'),
              contentPadding: EdgeInsets.zero,
              value: _acknowledged,
              onChanged: _isBusy
                  ? null
                  : (value) {
                      setState(() {
                        _acknowledged = value ?? false;
                      });
                    },
              title: const Text(
                'I understand this will replace the database currently '
                'stored on this phone.',
              ),
              controlAffinity: ListTileControlAffinity.leading,
            ),
            const SizedBox(height: 8),
            FilledButton.icon(
              key: const Key('databaseRestoreButton'),
              onPressed: _acknowledged && !_isBusy ? _confirmRestore : null,
              icon: const Icon(Icons.restore),
              label: const Text('Restore database'),
            ),
          ],
          if (_successMessage != null) ...[
            const SizedBox(height: 20),
            Card(
              color: Theme.of(context).colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_successMessage!),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
