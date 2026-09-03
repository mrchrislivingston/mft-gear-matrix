import 'package:flutter/material.dart';

import '../services/app_state.dart';
import '../services/misfit_candidate_reader.dart';
import '../services/misfit_duplicate_check_service.dart';
import '../services/misfit_log_entry_builder.dart';
import '../services/misfit_normalization_preview_service.dart';
import '../services/misfit_workout_parser.dart';

class ImportCandidateReviewScreen extends StatefulWidget {
  final MisfitCandidateSummary summary;
  final String sourceWorkbook;
  final MisfitDuplicateCheckService? duplicateCheckService;

  const ImportCandidateReviewScreen({
    required this.summary,
    this.sourceWorkbook = '',
    this.duplicateCheckService,
    super.key,
  });

  @override
  State<ImportCandidateReviewScreen> createState() {
    return _ImportCandidateReviewScreenState();
  }
}

class _ImportCandidateReviewScreenState
    extends State<ImportCandidateReviewScreen> {
  static const MisfitNormalizationPreviewService _normalizationService =
      MisfitNormalizationPreviewService();
  static const MisfitLogEntryBuilder _logEntryBuilder = MisfitLogEntryBuilder();

  MisfitImportStatus? _filter = MisfitImportStatus.ready;
  bool _showParsingFailures = false;
  late final MisfitNormalizationSummary _normalizationSummary;
  late final MisfitDuplicateCheckService _duplicateCheckService;
  final Set<MisfitWorkoutCandidate> _includedCandidates =
      <MisfitWorkoutCandidate>{};
  MisfitDuplicateSummary? _duplicateSummary;
  bool _isCheckingDuplicates = false;
  bool _isImporting = false;
  String? _duplicateCheckError;
  String? _importError;

  @override
  void initState() {
    super.initState();
    _normalizationSummary = _normalizationService.normalizeReady(
      widget.summary,
    );
    _duplicateCheckService =
        widget.duplicateCheckService ?? MisfitDuplicateCheckService();

    for (final attempt in _normalizationSummary.attempts) {
      if (attempt.succeeded) {
        _includedCandidates.add(attempt.candidate);
      }
    }

    if (widget.sourceWorkbook.isNotEmpty) {
      _isCheckingDuplicates = true;
      _checkDuplicates();
    }
  }

  Future<void> _checkDuplicates() async {
    try {
      final summary = await _duplicateCheckService.check(
        normalizationSummary: _normalizationSummary,
        sourceWorkbook: widget.sourceWorkbook,
      );

      if (!mounted) {
        return;
      }

      setState(() {
        _duplicateSummary = summary;
        _includedCandidates.removeAll(summary.duplicateCandidates);
        _isCheckingDuplicates = false;
      });
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _duplicateCheckError = error.toString();
        _isCheckingDuplicates = false;
      });
    }
  }

  Future<void> _confirmAndImport() async {
    final logs = _logEntryBuilder.buildSelected(
      normalizationSummary: _normalizationSummary,
      includedCandidates: _includedCandidates,
      sourceWorkbook: widget.sourceWorkbook,
    );

    if (logs.isEmpty) {
      return;
    }

    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Import ${logs.length} workouts?'),
          content: const Text(
            'These workouts will be added to your local History. '
            'The database will recheck for duplicates inside one '
            'transaction before saving anything.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Import workouts'),
            ),
          ],
        );
      },
    );

    if (approved != true || !mounted) {
      return;
    }

    setState(() {
      _isImporting = true;
      _importError = null;
    });

    try {
      final imported = await AppState.instance.importLogsAtomically(logs);

      if (!mounted) {
        return;
      }

      setState(() {
        _isImporting = false;
        _isCheckingDuplicates = true;
      });

      await _checkDuplicates();

      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$imported ${imported == 1 ? 'workout' : 'workouts'} imported.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }

      setState(() {
        _isImporting = false;
        _importError = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final canImport =
        widget.sourceWorkbook.isNotEmpty &&
        _duplicateSummary != null &&
        !_isCheckingDuplicates &&
        !_isImporting &&
        _duplicateCheckError == null &&
        _includedCandidates.isNotEmpty;

    final candidates = widget.summary.candidates.where((candidate) {
      if (_showParsingFailures) {
        return _normalizationSummary.attemptFor(candidate)?.error != null;
      }

      return _filter == null || candidate.importStatus == _filter;
    }).toList();

    return Scaffold(
      appBar: AppBar(title: const Text('Review Parsed Workouts')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Row(
              children: [
                _filterChip(
                  label: 'All (${widget.summary.total})',
                  status: null,
                ),
                _filterChip(
                  label: 'Ready (${widget.summary.ready})',
                  status: MisfitImportStatus.ready,
                ),
                _filterChip(
                  label: 'Needs review (${widget.summary.review})',
                  status: MisfitImportStatus.review,
                ),
                _filterChip(
                  label: 'Deferred (${widget.summary.deferred})',
                  status: MisfitImportStatus.tbdLater,
                ),
                _filterChip(
                  label: 'Skipped (${widget.summary.skipped})',
                  status: MisfitImportStatus.skip,
                ),
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(
                      'Parse failed (${_normalizationSummary.failed})',
                    ),
                    selected: _showParsingFailures,
                    onSelected: (_) {
                      setState(() {
                        _showParsingFailures = true;
                        _filter = MisfitImportStatus.ready;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _NormalizationSummaryCard(summary: _normalizationSummary),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected for import: ${_includedCandidates.length}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  if (_isCheckingDuplicates)
                    const Text('Checking existing workout history…')
                  else if (_duplicateSummary case final duplicateSummary?)
                    Text(
                      'New: ${duplicateSummary.newWorkouts} • '
                      'Already imported: ${duplicateSummary.duplicates}',
                    ),
                  if (_duplicateCheckError case final error?)
                    Text(
                      'Duplicate check failed: $error',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  if (_importError case final error?)
                    Text(
                      'Import failed: $error',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                ],
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: candidates.isEmpty
                ? const Center(child: Text('No workouts in this category.'))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: candidates.length,
                    itemBuilder: (context, index) {
                      final candidate = candidates[index];

                      final attempt = _normalizationSummary.attemptFor(
                        candidate,
                      );
                      final isDuplicate =
                          _duplicateSummary?.isDuplicate(candidate) ?? false;

                      return _CandidateCard(
                        candidate: candidate,
                        normalizationAttempt: attempt,
                        isIncluded: _includedCandidates.contains(candidate),
                        isDuplicate: isDuplicate,
                        onIncludedChanged:
                            attempt?.succeeded == true &&
                                !isDuplicate &&
                                !_isCheckingDuplicates
                            ? (included) {
                                setState(() {
                                  if (included) {
                                    _includedCandidates.add(candidate);
                                  } else {
                                    _includedCandidates.remove(candidate);
                                  }
                                });
                              }
                            : null,
                      );
                    },
                  ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: canImport ? _confirmAndImport : null,
                  icon: _isImporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.save_alt),
                  label: Text(
                    _isImporting
                        ? 'Importing…'
                        : 'Import ${_includedCandidates.length} workouts',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip({
    required String label,
    required MisfitImportStatus? status,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: !_showParsingFailures && _filter == status,
        onSelected: (_) {
          setState(() {
            _showParsingFailures = false;
            _filter = status;
          });
        },
      ),
    );
  }
}

class _NormalizationSummaryCard extends StatelessWidget {
  final MisfitNormalizationSummary summary;

  const _NormalizationSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final hasFailures = summary.failed > 0;
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      color: hasFailures
          ? colorScheme.errorContainer
          : colorScheme.primaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(
              hasFailures
                  ? Icons.warning_amber_rounded
                  : Icons.check_circle_outline,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Result parsing: ${summary.successful} of '
                '${summary.attempts.length} ready workouts parsed'
                '${hasFailures ? ' • ${summary.failed} failed' : ''}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  final MisfitWorkoutCandidate candidate;
  final MisfitNormalizationAttempt? normalizationAttempt;
  final bool isIncluded;
  final bool isDuplicate;
  final ValueChanged<bool>? onIncludedChanged;

  const _CandidateCard({
    required this.candidate,
    required this.normalizationAttempt,
    required this.isIncluded,
    required this.isDuplicate,
    required this.onIncludedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final prescription = candidate.prescription.isEmpty
        ? candidate.workoutType.name
        : candidate.prescription;
    final modality = candidate.modality.isEmpty
        ? 'Unknown modality'
        : candidate.modality;
    final workout = normalizationAttempt?.workout;
    final executionPlan = workout?.executionPlan ?? candidate.executionPlan;
    final dateLabel = candidate.date.isEmpty
        ? candidate.dateHeader
        : '${candidate.date} • ${candidate.programDay}';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: Tooltip(
          message: isDuplicate
              ? 'Already imported'
              : onIncludedChanged == null
              ? 'This workout cannot currently be imported'
              : isIncluded
              ? 'Included in import'
              : 'Skipped from import',
          child: Checkbox(
            value: isIncluded,
            onChanged: onIncludedChanged == null
                ? null
                : (value) {
                    onIncludedChanged!(value ?? false);
                  },
          ),
        ),
        title: Text('$prescription • $modality'),
        subtitle: Text(
          '$dateLabel\n'
          'Spreadsheet row ${candidate.sourceRow}, '
          'column ${candidate.sourceColumn}',
        ),
        trailing: isDuplicate
            ? const _DuplicateBadge()
            : normalizationAttempt?.error != null
            ? const _ParsingFailureBadge()
            : _StatusBadge(status: candidate.importStatus),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            candidate.statusReason,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          if (executionPlan != null) ...[
            const SizedBox(height: 12),
            Text(
              'Execution: ${executionPlan.intervalCount} intervals '
              '× ${executionPlan.workDuration}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
          if (normalizationAttempt?.error case final error?) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('Result parsing failed: $error'),
            ),
          ],
          if (workout != null) ...[
            const SizedBox(height: 16),
            Text(
              'Captured intervals: ${workout.intervals.length}',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 6),
            for (final interval in workout.intervals)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  '${interval.intervalNumber}. '
                  '${_formatValues(interval.values)}',
                ),
              ),
          ],
          const SizedBox(height: 16),
          const Text(
            'Programming',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          SelectableText(candidate.programmingText),
          const SizedBox(height: 16),
          const Text(
            'Recorded result',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          SelectableText(
            candidate.resultText.isEmpty
                ? 'No result recorded'
                : candidate.resultText,
          ),
        ],
      ),
    );
  }

  String _formatValues(Map<String, String> values) {
    if (values.isEmpty) {
      return 'Duration only';
    }

    return values.entries
        .map((entry) {
          return '${_metricLabel(entry.key)}: ${entry.value}';
        })
        .join(' • ');
  }

  String _metricLabel(String metric) {
    return switch (metric) {
      'primaryMetric' => 'Primary',
      'heartRate' => 'Heart rate',
      'caloriesPerHour' => 'Calories/hour',
      'distance' => 'Distance',
      'calories' => 'Calories',
      'watts' => 'Watts',
      'rpm' => 'RPM',
      _ => metric,
    };
  }
}

class _DuplicateBadge extends StatelessWidget {
  const _DuplicateBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.blueGrey.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Text(
        'Already imported',
        style: TextStyle(color: Colors.blueGrey, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _ParsingFailureBadge extends StatelessWidget {
  const _ParsingFailureBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        'Parse failed',
        style: TextStyle(
          color: Theme.of(context).colorScheme.error,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final MisfitImportStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      MisfitImportStatus.ready => ('Ready', Colors.green),
      MisfitImportStatus.review => ('Review', Colors.orange),
      MisfitImportStatus.tbdLater => ('Deferred', Colors.blueGrey),
      MisfitImportStatus.skip => ('Skipped', Colors.grey),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
    );
  }
}
