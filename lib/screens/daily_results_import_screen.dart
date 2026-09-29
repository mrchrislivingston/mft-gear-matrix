import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../services/daily_results_import_service.dart';

class DailyResultsImportScreen extends StatefulWidget {
  const DailyResultsImportScreen({super.key});
  @override
  State<DailyResultsImportScreen> createState() => _DailyResultsImportScreenState();
}

class _DailyResultsImportScreenState extends State<DailyResultsImportScreen> {
  final _service = DailyResultsImportService();
  DailyResultsImportPlan? _plan;
  String? _fileName, _message, _error;
  bool _busy = false;
  Future<void> _choose() async {
    setState(() { _busy = true; _error = null; _message = null; _plan = null; });
    try {
      final file = await FilePicker.pickFile(type: FileType.custom, allowedExtensions: const ['db']);
      if (file == null) return;
      final plan = await _service.inspect(Uint8List.fromList(await file.readAsBytes()));
      if (mounted) setState(() { _plan = plan; _fileName = file.name; });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
  Future<void> _import() async {
    final plan = _plan;
    if (plan == null) return;
    setState(() { _busy = true; _error = null; });
    try {
      final backup = await _service.apply(plan);
      if (mounted) setState(() {
        _plan = null;
        _message = backup == null ? 'These results are already on this device.'
          : 'Results imported. Open Training Week to see them.\n\nBackup saved: $backup';
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Import results')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Choose a database exported from your other device. This imports Training Week scores, notes, completion, and saved prescription weights. Other data stays on this device.'),
      const SizedBox(height: 12),
      const Text('Matching programming must already be loaded. Different saved results are flagged for review; they are never overwritten.'),
      const SizedBox(height: 16),
      FilledButton.icon(onPressed: _busy ? null : _choose, icon: const Icon(Icons.file_open), label: const Text('Choose export')),
      if (_busy) const LinearProgressIndicator(),
      if (_plan != null) ...[
        const SizedBox(height: 16), Text(_fileName ?? ''),
        Text('${_plan!.additions.length} new entries • ${_plan!.unchanged} already imported'),
        for (final label in _plan!.additions) ListTile(leading: const Icon(Icons.add), title: Text(label)),
        for (final conflict in _plan!.conflicts) ListTile(leading: const Icon(Icons.warning_amber), title: Text(conflict)),
        FilledButton(onPressed: _busy || _plan!.conflicts.isNotEmpty || _plan!.additions.isEmpty ? null : _import,
          child: Text('Import ${_plan!.additions.length} entries')),
      ],
      if (_message != null) Padding(padding: const EdgeInsets.only(top: 16), child: SelectableText(_message!)),
      if (_error != null) Padding(padding: const EdgeInsets.only(top: 16), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
    ]),
  );
}
