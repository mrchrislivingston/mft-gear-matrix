import 'package:flutter/material.dart';

import '../models/metric.dart';
import '../models/modality.dart';
import '../services/app_state.dart';
import '../services/garmin_calendar_service.dart';

class GarminCalendarScreen extends StatefulWidget {
  final GarminCalendarService? service;

  const GarminCalendarScreen({super.key, this.service});

  @override
  State<GarminCalendarScreen> createState() {
    return _GarminCalendarScreenState();
  }
}

class _GarminCalendarScreenState extends State<GarminCalendarScreen> {
  late final GarminCalendarService _service;
  late DateTime _monday;
  final TextEditingController _ageController = TextEditingController(
    text: '50',
  );

  GarminCalendarPreview? _preview;
  Set<String> _selectedIds = {};
  bool _isLoading = false;
  bool _isCommitting = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _service = widget.service ?? GarminCalendarService.local();
    _monday = _nextMonday(DateTime.now());
  }

  @override
  void dispose() {
    _ageController.dispose();
    super.dispose();
  }

  DateTime _nextMonday(DateTime value) {
    final date = DateTime(value.year, value.month, value.day);
    var daysUntilMonday = (8 - date.weekday) % 7;

    if (daysUntilMonday == 0) {
      daysUntilMonday = 7;
    }

    return date.add(Duration(days: daysUntilMonday));
  }

  int? _age() {
    final age = int.tryParse(_ageController.text.trim());

    if (age == null || age < 1 || age > 120) {
      return null;
    }

    return age;
  }

  void _changeWeek(int days) {
    setState(() {
      _monday = _monday.add(Duration(days: days));
      _preview = null;
      _selectedIds = {};
      _errorMessage = null;
    });
  }

  Future<void> _chooseWeek() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _monday,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
      helpText: 'Choose any day in the FITR week',
    );

    if (selected == null || !mounted) {
      return;
    }

    final monday = selected.subtract(Duration(days: selected.weekday - 1));

    setState(() {
      _monday = DateTime(monday.year, monday.month, monday.day);
      _preview = null;
      _selectedIds = {};
      _errorMessage = null;
    });
  }

  Map<String, GarminRunPaceTarget> _runPaceTargets() {
    final targets = <String, GarminRunPaceTarget>{};

    for (final gear in AppState.instance.gears) {
      final current = gear.currentTarget(
        modality: Modality.run,
        metric: Metric.minPerMile,
      );

      if (current == null) {
        continue;
      }

      targets[gear.id] = GarminRunPaceTarget(
        low: current.lowTarget,
        high: current.highTarget,
      );
    }

    return targets;
  }

  Future<void> _loadPreview() async {
    final age = _age();

    if (age == null) {
      setState(() {
        _errorMessage = 'Enter an age between 1 and 120.';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _preview = null;
      _selectedIds = {};
    });

    try {
      final preview = await _service.preview(
        monday: _monday,
        age: age,
        runPaceTargets: _runPaceTargets(),
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _preview = preview;
        _selectedIds = preview.candidates
            .map((candidate) => candidate.id)
            .toSet();
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
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _commitSelected() async {
    final age = _age();

    if (age == null || _selectedIds.isEmpty) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Schedule on Garmin?'),
          content: Text(
            'This will create or reuse '
            '${_selectedIds.length} structured '
            'workout${_selectedIds.length == 1 ? '' : 's'} '
            'and place them on your Garmin training '
            'calendar.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Schedule'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) {
      return;
    }

    setState(() {
      _isCommitting = true;
      _errorMessage = null;
    });

    try {
      final result = await _service.commit(
        monday: _monday,
        age: age,
        selectedIds: _selectedIds,
        runPaceTargets: _runPaceTargets(),
      );

      if (!mounted) {
        return;
      }

      await showDialog<void>(
        context: context,
        builder: (dialogContext) {
          return AlertDialog(
            title: const Text('Garmin calendar updated'),
            content: Text(
              'Created: ${result.created}\n'
              'Scheduled: ${result.scheduled}\n'
              'Already existed: '
              '${result.alreadyExisting}\n'
              'Already scheduled: '
              '${result.alreadyScheduled}',
            ),
            actions: [
              FilledButton(
                onPressed: () {
                  Navigator.pop(dialogContext);
                },
                child: const Text('Done'),
              ),
            ],
          );
        },
      );
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
          _isCommitting = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final preview = _preview;
    final sunday = _monday.add(const Duration(days: 6));

    return Scaffold(
      appBar: AppBar(title: const Text('FITR → Garmin Calendar')),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                Text(
                  'Choose a FITR week, review the '
                  'structured workouts, then approve '
                  'what should be scheduled.',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 20),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            IconButton(
                              tooltip: 'Previous week',
                              onPressed: _isLoading
                                  ? null
                                  : () => _changeWeek(-7),
                              icon: const Icon(Icons.chevron_left),
                            ),
                            Expanded(
                              child: InkWell(
                                onTap: _isLoading ? null : _chooseWeek,
                                borderRadius: BorderRadius.circular(8),
                                child: Padding(
                                  padding: const EdgeInsets.all(12),
                                  child: Column(
                                    children: [
                                      const Text('FITR week'),
                                      const SizedBox(height: 4),
                                      Text(
                                        '${_formatDate(_monday)}'
                                        ' – '
                                        '${_formatDate(sunday)}',
                                        style: Theme.of(
                                          context,
                                        ).textTheme.titleMedium,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Next week',
                              onPressed: _isLoading
                                  ? null
                                  : () => _changeWeek(7),
                              icon: const Icon(Icons.chevron_right),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _ageController,
                          enabled: !_isLoading,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Age',
                            helperText: 'Used for Zone 2 heart-rate targets',
                            border: OutlineInputBorder(),
                          ),
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          child: FilledButton.icon(
                            onPressed: _isLoading || _isCommitting
                                ? null
                                : _loadPreview,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.download_outlined),
                            label: Text(
                              _isLoading
                                  ? 'Loading FITR…'
                                  : 'Preview FITR week',
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
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
                if (preview != null) ...[
                  const SizedBox(height: 20),
                  Text(
                    '${preview.candidates.length} '
                    'Garmin workout'
                    '${preview.candidates.length == 1 ? '' : 's'} '
                    'found',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 4),
                  Text('${_selectedIds.length} selected'),
                  const SizedBox(height: 12),
                  if (preview.candidates.isEmpty)
                    const Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Text(
                          'No supported Matrix workouts '
                          'were found for this week.',
                        ),
                      ),
                    ),
                  for (final candidate in preview.candidates)
                    _CandidateCard(
                      candidate: candidate,
                      selected: _selectedIds.contains(candidate.id),
                      enabled: !_isCommitting,
                      onChanged: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedIds.add(candidate.id);
                          } else {
                            _selectedIds.remove(candidate.id);
                          }
                        });
                      },
                    ),
                  if (preview.skipped.isNotEmpty) ...[
                    const SizedBox(height: 16),
                    Text(
                      'Not supported',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    for (final skipped in preview.skipped)
                      ListTile(
                        leading: const Icon(Icons.block_outlined),
                        title: Text(
                          '${skipped.date} • '
                          '${skipped.sourceTitle}',
                        ),
                        subtitle: Text(skipped.reason),
                      ),
                  ],
                ],
              ],
            ),
          ),
          if (preview != null)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed:
                        _selectedIds.isEmpty || _isCommitting || _isLoading
                        ? null
                        : _commitSelected,
                    icon: _isCommitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.calendar_month_outlined),
                    label: Text(
                      _isCommitting
                          ? 'Scheduling…'
                          : 'Schedule '
                                '${_selectedIds.length} '
                                'on Garmin',
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  String _formatDate(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}

class _CandidateCard extends StatelessWidget {
  final GarminCalendarCandidate candidate;
  final bool selected;
  final bool enabled;
  final ValueChanged<bool> onChanged;

  const _CandidateCard({
    required this.candidate,
    required this.selected,
    required this.enabled,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: CheckboxListTile(
        value: selected,
        onChanged: enabled ? (value) => onChanged(value ?? false) : null,
        controlAffinity: ListTileControlAffinity.leading,
        title: Text(candidate.workoutName),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            '${candidate.date} • '
            '${candidate.sourceTitle}\n'
            '${_structure(candidate)}',
          ),
        ),
        isThreeLine: true,
      ),
    );
  }

  String _structure(GarminCalendarCandidate candidate) {
    final data = candidate.classification;

    switch (candidate.type) {
      case 'Z2':
        return '${_time(data['warmup_seconds'])} warm-up • '
            '${_time(data['work_seconds'])} work • '
            '${_time(data['cooldown_seconds'])} cool-down';
      case 'GEAR':
        final paceLow = data['pace_low'];
        final paceHigh = data['pace_high'];
        final paceText = paceLow is String && paceHigh is String
            ? ' • Target $paceLow–$paceHigh min/mile'
            : '';

        return '${data['rounds']} × '
            '${_time(data['work_seconds'])} work • '
            '${_time(data['rest_seconds'])} rest'
            '$paceText';
      case 'POWER':
        return '${data['rounds']} × '
            '${_time(data['work_seconds'])} work • '
            '${_time(data['recovery_seconds'])} recovery';
      case 'MIXED_GEAR':
        return '${data['rounds']} × 4:00 work • '
            'Ski + C2 Bike progression';
      case 'MATT':
        return '10:00 / 20:00 / 10:00';
      default:
        return [
          candidate.prescription,
          candidate.modality,
        ].where((value) => value.isNotEmpty).join(' • ');
    }
  }

  String _time(dynamic rawSeconds) {
    final seconds = rawSeconds is int ? rawSeconds : 0;
    final minutes = seconds ~/ 60;
    final remainder = seconds % 60;
    return '$minutes:${remainder.toString().padLeft(2, '0')}';
  }
}
