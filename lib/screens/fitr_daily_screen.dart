import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/working_max_service.dart';
import '../services/fitr_score_entry.dart';
import 'working_max_screen.dart';

import '../services/fitr_daily_service.dart';

class FitrDailyScreen extends StatefulWidget {
  final FitrDailyService? service;
  final DateTime? initialDate;
  const FitrDailyScreen({super.key, this.service, this.initialDate});
  @override
  State<FitrDailyScreen> createState() => _FitrDailyScreenState();
}

class _FitrDailyScreenState extends State<FitrDailyScreen> {
  late final FitrDailyService _service;
  late DateTime _monday;
  late DateTime _selected;
  List<DailyPlan> _days = [];
  bool _busy = true;
  bool _dayOnly = false;
  String? _error;
  String? _message;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? FitrDailyService();
    final now = widget.initialDate ?? DateTime.now();
    _selected = DateTime(now.year, now.month, now.day);
    _monday = _selected.subtract(Duration(days: _selected.weekday - 1));
    _load();
  }

  Future<void> _load() async {
    try {
      final days = await _service.loadWeek(_monday);
      if (mounted) setState(() => _days = days);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not read saved programming. Try reopening this screen.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _moveWeek(int offset) async {
    if (_busy) return;
    setState(() {
      _monday = _monday.add(Duration(days: offset * 7));
      _selected = _monday;
      _days = [];
      _busy = true;
      _error = null;
      _message = null;
    });
    await _load();
  }

  Future<void> _refresh() async {
    if (_busy) return;
    setState(() { _busy = true; _error = null; _message = null; });
    try {
      final count = await _service.refresh(_monday);
      final days = await _service.loadWeek(_monday);
      if (mounted) setState(() {
        _days = days;
        _message = count == 0 ? 'No published days returned. Previously saved programming was kept.'
            : 'Updated $count days from FITR. Your results and notes were kept.';
      });
    } catch (error) {
      if (mounted) setState(() => _error = 'Could not refresh FITR. Saved programming is still available. $error');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _edit(DailyPiece piece) async {
    final saved = await showDialog<bool>(context: context, barrierDismissible: false,
      builder: (_) => _EntryDialog(piece: piece, service: _service));
    if (saved == true && mounted) {
      setState(() => _busy = true);
      await _load();
    }
  }

  String _label(DateTime date) {
    const names = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${names[date.weekday - 1]} ${date.month}/${date.day}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Training Week')),
      body: Column(children: [
        Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 0), child: Wrap(
          spacing: 8, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            IconButton(tooltip: 'Previous week', onPressed: _busy ? null : () => _moveWeek(-1), icon: const Icon(Icons.chevron_left)),
            Text('Week of ${dailyDate(_monday)}'),
            IconButton(tooltip: 'Next week', onPressed: _busy ? null : () => _moveWeek(1), icon: const Icon(Icons.chevron_right)),
            FilledButton.icon(onPressed: _busy ? null : _refresh, icon: const Icon(Icons.refresh), label: const Text('Refresh from FITR')),
            if (MediaQuery.sizeOf(context).width >= 1000)
              TextButton.icon(onPressed: () => setState(() => _dayOnly = !_dayOnly),
                icon: Icon(_dayOnly ? Icons.table_chart : Icons.view_day), label: Text(_dayOnly ? 'Week grid' : 'Day view')),
          ],
        )),
        const Padding(padding: EdgeInsets.all(12), child: Text('Green: required • Gray: optional • Checkmark: completed\nResults and notes save on this device. They are not posted to FITR.', textAlign: TextAlign.center)),
        if (_busy) const LinearProgressIndicator(),
        if (_error != null) Padding(padding: const EdgeInsets.all(12), child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error))),
        if (_message != null) Padding(padding: const EdgeInsets.all(8), child: Text(_message!)),
        Expanded(child: LayoutBuilder(builder: (context, constraints) {
          if (!_dayOnly && constraints.maxWidth >= 1000) return _weekGrid();
          return _dayView();
        })),
      ]),
    );
  }

  Widget _instructions(DailyPlan day) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(day.planTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    SelectableText(day.instructions.isEmpty ? 'No coach instructions supplied. Priorities are unassigned.' : day.instructions),
    const SizedBox(height: 8),
    Text('Last fetched: ${day.fetchedAt.replaceFirst('T', ' ').split('.').first}', style: Theme.of(context).textTheme.bodySmall),
  ]);

  Widget _dayView() {
    final days = _days.where((d) => d.date == dailyDate(_selected)).toList();
    return Column(children: [
      SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [
        for (var i = 0; i < 7; i++) Padding(padding: const EdgeInsets.all(4), child: ChoiceChip(
          label: Text(_label(_monday.add(Duration(days: i)))),
          selected: dailyDate(_selected) == dailyDate(_monday.add(Duration(days: i))),
          onSelected: _busy ? null : (_) => setState(() => _selected = _monday.add(Duration(days: i))),
        )),
      ])),
      Expanded(child: ListView(padding: const EdgeInsets.all(12), children: [
        if (days.isEmpty && !_busy) const Padding(padding: EdgeInsets.all(24), child: Text('No saved programming for this day. Refresh from FITR to fetch this week.')),
        for (final day in days) ...[
          Card(child: Padding(padding: const EdgeInsets.all(16), child: _instructions(day))),
          for (final piece in day.pieces) _pieceCard(piece),
        ],
      ])),
    ]);
  }

  Widget _weekGrid() {
    if (_days.isEmpty) return const Center(child: Text('No saved programming for this week. Refresh from FITR to get started.'));
    const ordered = ['Mobility/Stability', 'Lift 1', 'Accessory', 'Accessory 1', 'Lift 2', 'Accessory 2', 'Conditioning 1', 'Conditioning 2', 'Conditioning 3', 'Skill'];
    final found = _days.expand((d) => d.pieces).map((p) => sectionCategory(p.title)).toSet();
    final columns = [...ordered.where(found.contains), ...found.where((c) => !ordered.contains(c))];
    return SingleChildScrollView(child: SingleChildScrollView(scrollDirection: Axis.horizontal,
      child: Table(defaultColumnWidth: const FixedColumnWidth(290),
        columnWidths: const {0: FixedColumnWidth(250)},
        border: TableBorder.all(color: Theme.of(context).dividerColor),
        defaultVerticalAlignment: TableCellVerticalAlignment.top,
        children: [
          TableRow(decoration: BoxDecoration(color: Theme.of(context).colorScheme.surfaceContainerHighest), children: [
            for (final title in ['Day / coach instructions', ...columns]) Padding(padding: const EdgeInsets.all(16), child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
          ]),
          for (final day in _days) TableRow(children: [
            Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(_label(DateTime.parse(day.date)), style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 12), _instructions(day),
            ])),
            for (final category in columns) Column(children: [
              for (final piece in day.pieces.where((p) => sectionCategory(p.title) == category)) _pieceCard(piece),
            ]),
          ]),
        ],
      ),
    ));
  }

  String _structuredSummary(String entry) {
    final saved = jsonDecode(entry) as Map;
    final spec = FitrScoreSpec(Map<String, dynamic>.from(saved['spec'] as Map));
    return spec.summarize((saved['values'] as List).map((v) => v.toString()).toList());
  }

  Widget _prescription(DailyPiece piece) {
    final benchmarks = piece.metadata['benchmarks'];
    final description = readablePrescription(piece.description, piece.calculations,
      fitrBenchmarks: benchmarks is List ? benchmarks : const []);
    final links = <String>[];
    final text = description.replaceAllMapped(
      RegExp(r'Warm[ \t]*Up Protocol:[ \t]*(https?://\S+)', caseSensitive: false),
      (match) { links.add(match[1]!); return ''; },
    ).replaceAll(RegExp(r'\n{3,}'), '\n\n').trim();
    final spans = <TextSpan>[];
    final weights = RegExp(r'→ [0-9.]+ lb');
    var start = 0;
    for (final match in weights.allMatches(text)) {
      spans.add(TextSpan(text: text.substring(start, match.start)));
      spans.add(TextSpan(text: match[0], style: const TextStyle(fontWeight: FontWeight.bold)));
      start = match.end;
    }
    spans.add(TextSpan(text: text.substring(start)));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      SelectableText.rich(TextSpan(children: spans)),
      for (final link in links) TextButton.icon(
        icon: const Icon(Icons.link, size: 18), label: const Text('Warm-up link'),
        onPressed: () => showDialog<void>(context: context, builder: (dialogContext) => AlertDialog(
          title: const Text('Warm-up protocol'), content: SelectableText(link),
          actions: [TextButton(onPressed: () async {
            await Clipboard.setData(ClipboardData(text: link));
            if (dialogContext.mounted) Navigator.pop(dialogContext);
          }, child: const Text('Copy link')),
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('Close'))],
        )),
      ),
    ]);
  }

  Widget _pieceCard(DailyPiece piece) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final color = piece.priority == 'required' ? (dark ? const Color(0xff234a32) : const Color(0xffdeedda))
        : piece.priority == 'optional' ? (dark ? const Color(0xff363636) : const Color(0xffe8e8e8))
        : Theme.of(context).colorScheme.surface;
    final label = piece.priority == 'required' ? 'Required' : piece.priority == 'optional' ? 'Optional' : 'Priority unassigned';
    return Card(color: color, child: Padding(padding: const EdgeInsets.all(14), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [Expanded(child: Text(piece.title, style: const TextStyle(fontWeight: FontWeight.bold))),
        if (piece.completed) const Icon(Icons.check_circle, semanticLabel: 'Completed')]),
      Text(label, style: Theme.of(context).textTheme.labelMedium),
      if (!piece.active) const Padding(padding: EdgeInsets.only(top: 8), child: Text('Removed from current programming • saved entry retained')),
      const SizedBox(height: 12),
      _prescription(piece),
      if (piece.calculations.isNotEmpty) ...[
        const Divider(),
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: Text(piece.prescriptionSnapshot == null ? 'Working max details' : 'Weights used for this entry', style: Theme.of(context).textTheme.bodySmall),
          children: [Align(alignment: Alignment.centerLeft, child: SelectableText(piece.calculations)),
            if (piece.prescriptionSnapshot == null) const Align(alignment: Alignment.centerLeft, child: Text('Calculated weight; adjust your loaded weight as needed.')),
        TextButton(onPressed: _busy ? null : () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => const WorkingMaxScreen()));
          if (mounted) { setState(() => _busy = true); await _load(); }
        }, child: const Text('Working 1RMs')),
          ],
        ),
      ],
      const Divider(height: 24),
      if (piece.scoreEntry.isNotEmpty) Text(_structuredSummary(piece.scoreEntry)),
      if (piece.result.isNotEmpty) Text('Result: ${piece.result}'),
      if (piece.notes.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text('Notes: ${piece.notes}')),
      Align(alignment: Alignment.centerLeft, child: TextButton.icon(
        onPressed: _busy ? null : () => _edit(piece), icon: const Icon(Icons.edit_note), label: const Text('Results / notes'))),
    ])));
  }
}

class _EntryDialog extends StatefulWidget {
  final DailyPiece piece;
  final FitrDailyService service;
  const _EntryDialog({required this.piece, required this.service});
  @override
  State<_EntryDialog> createState() => _EntryDialogState();
}

class _EntryDialogState extends State<_EntryDialog> {
  late final TextEditingController _result;
  late final TextEditingController _notes;
  late bool _completed;
  bool _saving = false;
  FitrScoreSpec? _scoreSpec;
  final List<TextEditingController> _scores = [];
  bool _changedSpec = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _result = TextEditingController(text: widget.piece.result);
    _notes = TextEditingController(text: widget.piece.notes);
    _completed = widget.piece.completed;
    _scoreSpec = FitrScoreSpec.fromMetadata(widget.piece.metadata);
    if (widget.piece.scoreEntry.isNotEmpty) {
      final saved = jsonDecode(widget.piece.scoreEntry) as Map;
      final savedSpec = FitrScoreSpec(Map<String, dynamic>.from(saved['spec'] as Map));
      _changedSpec = _scoreSpec?.signature != savedSpec.signature;
      _scoreSpec = savedSpec;
      for (final value in saved['values'] as List) {
        _scores.add(TextEditingController(text: value.toString()));
      }
    }
    if (_scores.isEmpty && _scoreSpec?.supported == true) {
      for (var i=0; i<_scoreSpec!.count; i++) { _scores.add(TextEditingController()); }
    }
  }
  @override
  void dispose() { _result.dispose(); _notes.dispose(); for (final c in _scores) { c.dispose(); } super.dispose(); }
  Future<void> _save() async {
    final values = _scores.map((c) => c.text.trim()).toList();
    final spec = _scoreSpec;
    if (spec != null && spec.supported) {
      for (var i=0; i<values.length; i++) {
        final error = spec.validate(values[i]);
        if (error != null) { setState(() => _error = 'Entry ${i+1}: $error'); return; }
      }
    }
    final entered = values.any((v) => v.isNotEmpty);
    final scoreEntry = entered && spec != null ? jsonEncode({'spec': spec.raw, 'unit': spec.unit, 'values': values}) : '';
    setState(() { _saving = true; _error = null; });
    try {
      await widget.service.saveStructuredEntry(widget.piece, result: _result.text, notes: _notes.text,
        completed: _completed, scoreEntry: scoreEntry);
      if (mounted) Navigator.pop(context, true);
    } catch (_) {
      if (mounted) setState(() { _saving = false; _error = 'Could not save. Your text is still here; please try again.'; });
    }
  }
  @override
  Widget build(BuildContext context) => PopScope(canPop: !_saving, child: AlertDialog(
    title: Text(widget.piece.title),
    content: SizedBox(width: 480, child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
      if (_scoreSpec?.supported == true) ...[
        Text('FITR score: ${_scoreSpec!.measure} • ${_scoreSpec!.count} ${_scoreSpec!.count == 1 ? 'entry' : 'entries'} • ${_scoreSpec!.aggregation}'),
        if (_changedSpec) const Text('FITR scoring has changed. Showing the original format saved with this entry.'),
        const SizedBox(height: 12),
        for (var i=0; i<_scores.length; i++) Padding(padding: const EdgeInsets.only(bottom: 10), child: TextField(
          controller: _scores[i], enabled: !_saving,
          decoration: InputDecoration(labelText: 'Entry ${i+1} (${_scoreSpec!.unit})', border: const OutlineInputBorder()),
        )),
      ],
      TextField(controller: _result, enabled: !_saving, minLines: 2, maxLines: 5,
        decoration: InputDecoration(labelText: _scoreSpec?.supported == true ? 'Result details (optional)' : 'Result', hintText: 'Weights, reps, time, or interval results', border: const OutlineInputBorder())),
      const SizedBox(height: 16),
      TextField(controller: _notes, enabled: !_saving, minLines: 3, maxLines: 8,
        decoration: const InputDecoration(labelText: 'Notes', border: OutlineInputBorder())),
      CheckboxListTile(contentPadding: EdgeInsets.zero, title: const Text('Completed'), value: _completed,
        onChanged: _saving ? null : (value) => setState(() => _completed = value ?? false)),
      if (_error != null) Text(_error!),
    ]))),
    actions: [TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: const Text('Cancel')),
      FilledButton(onPressed: _saving ? null : _save, child: Text(_saving ? 'Saving…' : 'Save'))],
  ));
}
