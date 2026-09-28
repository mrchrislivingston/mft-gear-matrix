import 'dart:convert';
import 'package:flutter/material.dart';
import '../services/database_service.dart';
import '../services/working_max_service.dart';

class WorkingMaxScreen extends StatefulWidget {
  const WorkingMaxScreen({super.key});
  @override
  State<WorkingMaxScreen> createState() => _WorkingMaxScreenState();
}
class _WorkingMaxScreenState extends State<WorkingMaxScreen> {
  Map<String, WorkingMax?> _maxes = {};
  String? _error;
  bool _busy = true;
  @override
  void initState() { super.initState(); _load(); }
  Future<void> _load() async {
    try {
      final db = await DatabaseService.instance.database;
      final attempts = await db.query('benchmark_attempts', orderBy: 'attempt_date DESC, id DESC');
      final overrides = await WorkingMaxService().history();
      final pieces = await db.query('fitr_pieces', columns: ['source_json']);
      final benchmarks = <dynamic>[];
      for (final piece in pieces) {
        final metadata = jsonDecode(piece['source_json'] as String) as Map;
        if (metadata['benchmarks'] is List) benchmarks.addAll(metadata['benchmarks'] as List);
      }
      final values = {for (final id in workingLiftNames.keys) id: resolveWorkingMax(liftId: id,
        asOf: DateTime.now(), attempts: attempts, overrides: overrides, fitrBenchmarks: benchmarks)};
      if (mounted) setState(() { _maxes = values; _error = null; });
    } catch (_) { if (mounted) setState(() => _error = 'Could not load working maxes.'); }
    finally { if (mounted) setState(() => _busy = false); }
  }
  Future<void> _edit(String id) async {
    final saved = await showDialog<bool>(context: context, barrierDismissible: false,
      builder: (_) => _MaxDialog(lift: id, current: _maxes[id]));
    if (saved == true && mounted) { setState(() => _busy = true); await _load(); }
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Working 1RMs')),
    body: ListView(padding: const EdgeInsets.all(20), children: [
      const Text('Percentages use your most recent recorded 1RM within six months. Set a working max to override it. All weights below are in pounds.'),
      const SizedBox(height: 12),
      const Text('Overrides remain in effect until you change them or return to automatic selection. Saving a workout preserves the calculation used that day.'),
      if (_busy) const LinearProgressIndicator(),
      if (_error != null) Text(_error!),
      for (final entry in workingLiftNames.entries) Card(child: ListTile(
        title: Text(entry.value),
        subtitle: Text(_maxes[entry.key] == null ? 'No recent 1RM — set a working max' :
          '${weightText(_maxes[entry.key]!.pounds)} lb • ${_maxes[entry.key]!.source}\n${maxDate(_maxes[entry.key]!.date)}'),
        trailing: const Icon(Icons.edit), onTap: _busy ? null : () => _edit(entry.key),
      )),
    ]),
  );
}
class _MaxDialog extends StatefulWidget {
  final String lift;
  final WorkingMax? current;
  const _MaxDialog({required this.lift, this.current});
  @override
  State<_MaxDialog> createState() => _MaxDialogState();
}
class _MaxDialogState extends State<_MaxDialog> {
  late final TextEditingController _weight;
  DateTime _date = DateTime.now();
  String? _error;
  bool _busy = false;
  @override
  void initState() { super.initState(); _weight = TextEditingController(text: widget.current == null ? '' : weightText(widget.current!.pounds)); }
  @override
  void dispose() { _weight.dispose(); super.dispose(); }
  Future<void> _save(bool automatic) async {
    final pounds = double.tryParse(_weight.text);
    if (!automatic && (pounds == null || !pounds.isFinite || pounds <= 0)) {
      setState(() => _error = 'Enter a positive weight in pounds.'); return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      await WorkingMaxService().save(widget.lift, automatic ? null : pounds, _date);
      if (mounted) Navigator.pop(context, true);
    } catch (_) { if (mounted) setState(() { _busy = false; _error = 'Could not save. Please try again.'; }); }
  }
  @override
  Widget build(BuildContext context) => PopScope(canPop: !_busy, child: AlertDialog(
    title: Text(workingLiftNames[widget.lift]!),
    content: SizedBox(width: 400, child: Column(mainAxisSize: MainAxisSize.min, children: [
      TextField(controller: _weight, enabled: !_busy, keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: const InputDecoration(labelText: 'Working 1RM (lb)')),
      TextButton(onPressed: _busy ? null : () async {
        final chosen = await showDatePicker(context: context, initialDate: _date, firstDate: DateTime(2000), lastDate: DateTime.now());
        if (chosen != null && mounted) setState(() => _date = chosen);
      }, child: Text('Effective ${maxDate(_date)}')),
      if (_error != null) Text(_error!),
    ])),
    actions: [
      TextButton(onPressed: _busy ? null : () => Navigator.pop(context), child: const Text('Cancel')),
      TextButton(onPressed: _busy ? null : () => _save(true), child: const Text('Use recent 1RM')),
      FilledButton(onPressed: _busy ? null : () => _save(false), child: const Text('Save override')),
    ],
  ));
}
