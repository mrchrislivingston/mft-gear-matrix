import 'package:flutter/material.dart';

import '../models/benchmark_attempt.dart';
import '../services/app_state.dart';
import '../services/misfit_benchmark_candidate_reader.dart';
import '../services/misfit_benchmark_duplicate_check_service.dart';
import '../services/misfit_benchmark_normalizer.dart';
import '../services/misfit_candidate_reader.dart';
import '../services/misfit_duplicate_check_service.dart';
import '../services/misfit_log_entry_builder.dart';
import '../services/misfit_normalization_preview_service.dart';
import '../services/misfit_workout_parser.dart';

enum _ReviewType { matrix, benchmarks }

enum _BenchmarkFilter {
  all,
  selected,
  needsReview,
  excluded,
  missing,
  parseFailed,
}

class ImportCandidateReviewScreen extends StatefulWidget {
  final MisfitCandidateSummary summary;
  final MisfitBenchmarkCandidateSummary? benchmarkSummary;
  final String sourceWorkbook;
  final MisfitDuplicateCheckService? duplicateCheckService;
  final MisfitBenchmarkDuplicateCheckService? benchmarkDuplicateCheckService;

  const ImportCandidateReviewScreen({
    required this.summary,
    this.benchmarkSummary,
    this.sourceWorkbook = '',
    this.duplicateCheckService,
    this.benchmarkDuplicateCheckService,
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
  static const MisfitBenchmarkNormalizer _benchmarkNormalizer =
      MisfitBenchmarkNormalizer();
  static const MisfitLogEntryBuilder _logEntryBuilder = MisfitLogEntryBuilder();

  _ReviewType _reviewType = _ReviewType.matrix;
  MisfitImportStatus? _matrixFilter = MisfitImportStatus.ready;
  bool _showMatrixParsingFailures = false;
  _BenchmarkFilter _benchmarkFilter = _BenchmarkFilter.selected;

  late final MisfitNormalizationSummary _normalizationSummary;
  late final MisfitBenchmarkNormalizationSummary?
  _benchmarkNormalizationSummary;
  late final MisfitDuplicateCheckService _duplicateCheckService;
  late final MisfitBenchmarkDuplicateCheckService
  _benchmarkDuplicateCheckService;

  final Set<MisfitWorkoutCandidate> _includedCandidates =
      <MisfitWorkoutCandidate>{};
  final Set<MisfitBenchmarkCandidate> _includedBenchmarkCandidates =
      <MisfitBenchmarkCandidate>{};

  MisfitDuplicateSummary? _duplicateSummary;
  MisfitBenchmarkDuplicateSummary? _benchmarkDuplicateSummary;
  bool _isCheckingDuplicates = false;
  bool _isImporting = false;
  String? _duplicateCheckError;
  String? _importError;

  @override
  void initState() {
    super.initState();

    _normalizationSummary = _normalizationService.normalizeImportable(
      widget.summary,
    );

    final benchmarkSummary = widget.benchmarkSummary;
    _benchmarkNormalizationSummary = benchmarkSummary == null
        ? null
        : _benchmarkNormalizer.normalizeAll(
            benchmarkSummary,
            sourceWorkbook: widget.sourceWorkbook,
          );

    _duplicateCheckService =
        widget.duplicateCheckService ?? MisfitDuplicateCheckService();
    _benchmarkDuplicateCheckService =
        widget.benchmarkDuplicateCheckService ??
        MisfitBenchmarkDuplicateCheckService();

    for (final attempt in _normalizationSummary.attempts) {
      if (attempt.succeeded &&
          attempt.candidate.importStatus == MisfitImportStatus.ready) {
        _includedCandidates.add(attempt.candidate);
      }
    }

    for (final attempt
        in _benchmarkNormalizationSummary?.attempts ??
            const <MisfitBenchmarkNormalizationAttempt>[]) {
      if (attempt.succeeded) {
        _includedBenchmarkCandidates.add(attempt.candidate);
      }
    }

    if (widget.summary.total == 0 && benchmarkSummary != null) {
      _reviewType = _ReviewType.benchmarks;
    }

    if (widget.sourceWorkbook.isNotEmpty) {
      _isCheckingDuplicates = true;
      _checkDuplicates();
    }
  }

  Future<void> _checkDuplicates() async {
    try {
      final workoutSummary = await _duplicateCheckService.check(
        normalizationSummary: _normalizationSummary,
        sourceWorkbook: widget.sourceWorkbook,
      );

      final benchmarkNormalizationSummary = _benchmarkNormalizationSummary;
      final benchmarkSummary = benchmarkNormalizationSummary == null
          ? null
          : await _benchmarkDuplicateCheckService.check(
              normalizationSummary: benchmarkNormalizationSummary,
              sourceWorkbook: widget.sourceWorkbook,
            );

      if (!mounted) {
        return;
      }

      setState(() {
        _duplicateSummary = workoutSummary;
        _benchmarkDuplicateSummary = benchmarkSummary;
        _includedCandidates.removeAll(workoutSummary.duplicateCandidates);

        if (benchmarkSummary != null) {
          _includedBenchmarkCandidates.removeAll(
            benchmarkSummary.duplicateCandidates,
          );
        }

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

  List<BenchmarkAttempt> _selectedBenchmarkAttempts() {
    final summary = _benchmarkNormalizationSummary;
    if (summary == null) {
      return const [];
    }

    return [
      for (final normalization in summary.attempts)
        if (_includedBenchmarkCandidates.contains(normalization.candidate) &&
            normalization.benchmarkAttempt != null)
          normalization.benchmarkAttempt!,
    ];
  }

  Future<void> _confirmAndImport() async {
    final workouts = _logEntryBuilder.buildSelected(
      normalizationSummary: _normalizationSummary,
      includedCandidates: _includedCandidates,
      sourceWorkbook: widget.sourceWorkbook,
    );
    final benchmarkAttempts = _selectedBenchmarkAttempts();
    final total = workouts.length + benchmarkAttempts.length;

    if (total == 0) {
      return;
    }

    final approved = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Import historical records?'),
          content: Text(
            '${workouts.length} ${_plural(workouts.length, 'workout')} '
            'and ${benchmarkAttempts.length} '
            '${_plural(benchmarkAttempts.length, 'benchmark attempt')} '
            'will be added.\n\n'
            'The database will recheck all duplicates and save both '
            'record types together in one transaction.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Import records'),
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
      final result = await AppState.instance.importHistoricalRecordsAtomically(
        workouts: workouts,
        benchmarkAttempts: benchmarkAttempts,
      );

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
            '${result.workoutsImported} '
            '${_plural(result.workoutsImported, 'workout')} and '
            '${result.benchmarkAttemptsImported} '
            '${_plural(result.benchmarkAttemptsImported, 'benchmark attempt')} imported.',
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
    final benchmarkSummary = widget.benchmarkSummary;
    final hasBenchmarks = benchmarkSummary != null;
    final selectedTotal =
        _includedCandidates.length + _includedBenchmarkCandidates.length;

    final duplicateChecksComplete =
        _duplicateSummary != null &&
        (!hasBenchmarks || _benchmarkDuplicateSummary != null);

    final canImport =
        widget.sourceWorkbook.isNotEmpty &&
        duplicateChecksComplete &&
        !_isCheckingDuplicates &&
        !_isImporting &&
        _duplicateCheckError == null &&
        selectedTotal > 0;

    final matrixCandidates = widget.summary.candidates.where((candidate) {
      if (_showMatrixParsingFailures) {
        return _normalizationSummary.attemptFor(candidate)?.error != null;
      }

      return _matrixFilter == null || candidate.importStatus == _matrixFilter;
    }).toList();

    final benchmarkCandidates = hasBenchmarks
        ? benchmarkSummary.candidates.where(_matchesBenchmarkFilter).toList()
        : const <MisfitBenchmarkCandidate>[];

    return Scaffold(
      appBar: AppBar(title: const Text('Review Historical Import')),
      body: Column(
        children: [
          if (hasBenchmarks)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: SegmentedButton<_ReviewType>(
                segments: [
                  ButtonSegment(
                    value: _ReviewType.matrix,
                    label: Text('Matrix (${widget.summary.total})'),
                    icon: const Icon(Icons.fitness_center),
                  ),
                  ButtonSegment(
                    value: _ReviewType.benchmarks,
                    label: Text('Benchmarks (${benchmarkSummary.total})'),
                    icon: const Icon(Icons.emoji_events_outlined),
                  ),
                ],
                selected: {_reviewType},
                onSelectionChanged: (selection) {
                  setState(() {
                    _reviewType = selection.single;
                  });
                },
              ),
            ),
          if (_reviewType == _ReviewType.matrix)
            _matrixFilters()
          else
            _benchmarkFilters(benchmarkSummary!),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: _reviewType == _ReviewType.matrix
                ? _NormalizationSummaryCard(summary: _normalizationSummary)
                : _BenchmarkNormalizationSummaryCard(
                    summary: _benchmarkNormalizationSummary!,
                    selectedResults: benchmarkSummary!.selected,
                  ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Selected for import: $selectedTotal',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  Text(
                    'Matrix: ${_includedCandidates.length} • '
                    'Benchmarks: ${_includedBenchmarkCandidates.length}',
                  ),
                  if (_isCheckingDuplicates)
                    const Text('Checking existing history…')
                  else ...[
                    if (_duplicateSummary case final summary?)
                      Text(
                        'Matrix new: ${summary.newWorkouts} • '
                        'Already imported: ${summary.duplicates}',
                      ),
                    if (_benchmarkDuplicateSummary case final summary?)
                      Text(
                        'Benchmarks new: ${summary.newAttempts} • '
                        'Already imported: ${summary.duplicates}',
                      ),
                  ],
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
            child: _reviewType == _ReviewType.matrix
                ? _matrixList(matrixCandidates)
                : _benchmarkList(benchmarkCandidates),
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
                        : 'Import $selectedTotal records',
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _matrixFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          _matrixFilterChip(
            label: 'All (${widget.summary.total})',
            status: null,
          ),
          _matrixFilterChip(
            label: 'Ready (${widget.summary.ready})',
            status: MisfitImportStatus.ready,
          ),
          _matrixFilterChip(
            label: 'Needs review (${widget.summary.review})',
            status: MisfitImportStatus.review,
          ),
          _matrixFilterChip(
            label: 'Deferred (${widget.summary.deferred})',
            status: MisfitImportStatus.tbdLater,
          ),
          _matrixFilterChip(
            label: 'Skipped (${widget.summary.skipped})',
            status: MisfitImportStatus.skip,
          ),
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text('Parse failed (${_normalizationSummary.failed})'),
              selected: _showMatrixParsingFailures,
              onSelected: (_) {
                setState(() {
                  _showMatrixParsingFailures = true;
                  _matrixFilter = MisfitImportStatus.ready;
                });
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _benchmarkFilters(MisfitBenchmarkCandidateSummary summary) {
    final normalization = _benchmarkNormalizationSummary!;

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: Row(
        children: [
          _benchmarkFilterChip('All (${summary.total})', _BenchmarkFilter.all),
          _benchmarkFilterChip(
            'Results (${summary.selected})',
            _BenchmarkFilter.selected,
          ),
          _benchmarkFilterChip(
            'Needs review (${summary.needsReview})',
            _BenchmarkFilter.needsReview,
          ),
          _benchmarkFilterChip(
            'Excluded (${summary.excluded})',
            _BenchmarkFilter.excluded,
          ),
          _benchmarkFilterChip(
            'No result (${summary.missing})',
            _BenchmarkFilter.missing,
          ),
          _benchmarkFilterChip(
            'Parse failed (${normalization.failed})',
            _BenchmarkFilter.parseFailed,
          ),
        ],
      ),
    );
  }

  Widget _matrixFilterChip({
    required String label,
    required MisfitImportStatus? status,
  }) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: !_showMatrixParsingFailures && _matrixFilter == status,
        onSelected: (_) {
          setState(() {
            _showMatrixParsingFailures = false;
            _matrixFilter = status;
          });
        },
      ),
    );
  }

  Widget _benchmarkFilterChip(String label, _BenchmarkFilter filter) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: _benchmarkFilter == filter,
        onSelected: (_) {
          setState(() {
            _benchmarkFilter = filter;
          });
        },
      ),
    );
  }

  bool _matchesBenchmarkFilter(MisfitBenchmarkCandidate candidate) {
    final normalization = _benchmarkNormalizationSummary?.attemptFor(candidate);

    return switch (_benchmarkFilter) {
      _BenchmarkFilter.all => true,
      _BenchmarkFilter.selected =>
        candidate.resultStatus == MisfitBenchmarkResultStatus.selected &&
            normalization?.error == null,
      _BenchmarkFilter.needsReview =>
        candidate.resultStatus == MisfitBenchmarkResultStatus.needsReview,
      _BenchmarkFilter.excluded =>
        candidate.resultStatus == MisfitBenchmarkResultStatus.excluded,
      _BenchmarkFilter.missing =>
        candidate.resultStatus == MisfitBenchmarkResultStatus.missing,
      _BenchmarkFilter.parseFailed => normalization?.error != null,
    };
  }

  Widget _matrixList(List<MisfitWorkoutCandidate> candidates) {
    if (candidates.isEmpty) {
      return const Center(child: Text('No workouts in this category.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: candidates.length,
      itemBuilder: (context, index) {
        final candidate = candidates[index];
        final attempt = _normalizationSummary.attemptFor(candidate);
        final isDuplicate = _duplicateSummary?.isDuplicate(candidate) ?? false;

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
    );
  }

  Widget _benchmarkList(List<MisfitBenchmarkCandidate> candidates) {
    if (candidates.isEmpty) {
      return const Center(child: Text('No benchmarks in this category.'));
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: candidates.length,
      itemBuilder: (context, index) {
        final candidate = candidates[index];
        final normalization = _benchmarkNormalizationSummary?.attemptFor(
          candidate,
        );
        final isDuplicate =
            _benchmarkDuplicateSummary?.isDuplicate(candidate) ?? false;

        return _BenchmarkCandidateCard(
          candidate: candidate,
          normalizationAttempt: normalization,
          isIncluded: _includedBenchmarkCandidates.contains(candidate),
          isDuplicate: isDuplicate,
          onIncludedChanged:
              normalization?.succeeded == true &&
                  !isDuplicate &&
                  !_isCheckingDuplicates
              ? (included) {
                  setState(() {
                    if (included) {
                      _includedBenchmarkCandidates.add(candidate);
                    } else {
                      _includedBenchmarkCandidates.remove(candidate);
                    }
                  });
                }
              : null,
        );
      },
    );
  }

  static String _plural(int count, String singular) {
    return count == 1 ? singular : '${singular}s';
  }
}

class _NormalizationSummaryCard extends StatelessWidget {
  final MisfitNormalizationSummary summary;

  const _NormalizationSummaryCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final hasFailures = summary.readyFailed > 0;
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
                'Result parsing: ${summary.readySuccessful} of '
                '${summary.readyTotal} ready workouts parsed'
                '${hasFailures ? ' • ${summary.readyFailed} failed' : ''}',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BenchmarkNormalizationSummaryCard extends StatelessWidget {
  final MisfitBenchmarkNormalizationSummary summary;
  final int selectedResults;

  const _BenchmarkNormalizationSummaryCard({
    required this.summary,
    required this.selectedResults,
  });

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
                'Benchmark parsing: ${summary.successful} of '
                '$selectedResults results parsed'
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
        leading: _ImportCheckbox(
          isIncluded: isIncluded,
          isDuplicate: isDuplicate,
          itemName: 'workout',
          onIncludedChanged: onIncludedChanged,
        ),
        title: Text('$prescription • $modality'),
        subtitle: Text(
          '$dateLabel\n'
          'Spreadsheet row ${candidate.sourceRow}, '
          'column ${candidate.sourceColumn}',
        ),
        trailing: isDuplicate
            ? const _LabelBadge(
                label: 'Already imported',
                color: Colors.blueGrey,
              )
            : normalizationAttempt?.error != null
            ? const _ParsingFailureBadge()
            : _WorkoutStatusBadge(status: candidate.importStatus),
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
            _ErrorBox(message: 'Result parsing failed: $error'),
          ],
          if (workout != null) ...[
            if (workout.scoringMetric case final metric?) ...[
              const SizedBox(height: 16),
              Text(
                'Scoring metric: ${_metricLabel(metric.storageKey)}',
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ],
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
          _SourceText(
            programmingText: candidate.programmingText,
            resultText: candidate.resultText,
          ),
        ],
      ),
    );
  }
}

class _BenchmarkCandidateCard extends StatelessWidget {
  final MisfitBenchmarkCandidate candidate;
  final MisfitBenchmarkNormalizationAttempt? normalizationAttempt;
  final bool isIncluded;
  final bool isDuplicate;
  final ValueChanged<bool>? onIncludedChanged;

  const _BenchmarkCandidateCard({
    required this.candidate,
    required this.normalizationAttempt,
    required this.isIncluded,
    required this.isDuplicate,
    required this.onIncludedChanged,
  });

  @override
  Widget build(BuildContext context) {
    final attempt = normalizationAttempt?.benchmarkAttempt;
    final modality = candidate.modality.isEmpty
        ? 'Unknown modality'
        : candidate.modality;
    final dateLabel = candidate.date.isEmpty
        ? candidate.dateHeader
        : '${candidate.date} • ${candidate.programDay}';

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: _ImportCheckbox(
          isIncluded: isIncluded,
          isDuplicate: isDuplicate,
          itemName: 'benchmark attempt',
          onIncludedChanged: onIncludedChanged,
        ),
        title: Text(candidate.benchmarkName),
        subtitle: Text(
          '$modality • $dateLabel\n'
          'Spreadsheet row ${candidate.sourceRow}, '
          'column ${candidate.sourceColumn}',
        ),
        trailing: isDuplicate
            ? const _LabelBadge(
                label: 'Already imported',
                color: Colors.blueGrey,
              )
            : normalizationAttempt?.error != null
            ? const _ParsingFailureBadge()
            : _BenchmarkStatusBadge(status: candidate.resultStatus),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            candidate.resultReason,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          if (normalizationAttempt?.error case final error?) ...[
            const SizedBox(height: 12),
            _ErrorBox(message: 'Result parsing failed: $error'),
          ],
          if (attempt != null) ...[
            const SizedBox(height: 12),
            Text(
              'Score: ${attempt.score}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text('Benchmark ID: ${attempt.benchmarkId}'),
          ],
          _SourceText(
            programmingText: candidate.programmingText,
            resultText: candidate.resultText,
          ),
        ],
      ),
    );
  }
}

class _ImportCheckbox extends StatelessWidget {
  final bool isIncluded;
  final bool isDuplicate;
  final String itemName;
  final ValueChanged<bool>? onIncludedChanged;

  const _ImportCheckbox({
    required this.isIncluded,
    required this.isDuplicate,
    required this.itemName,
    required this.onIncludedChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: isDuplicate
          ? 'Already imported'
          : onIncludedChanged == null
          ? 'This $itemName cannot currently be imported'
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
    );
  }
}

class _SourceText extends StatelessWidget {
  final String programmingText;
  final String resultText;

  const _SourceText({required this.programmingText, required this.resultText});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        const Text(
          'Programming',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        SelectableText(programmingText),
        const SizedBox(height: 16),
        const Text(
          'Recorded result',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 4),
        SelectableText(resultText.isEmpty ? 'No result recorded' : resultText),
      ],
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;

  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(message),
    );
  }
}

class _ParsingFailureBadge extends StatelessWidget {
  const _ParsingFailureBadge();

  @override
  Widget build(BuildContext context) {
    return _LabelBadge(
      label: 'Parse failed',
      color: Theme.of(context).colorScheme.error,
    );
  }
}

class _WorkoutStatusBadge extends StatelessWidget {
  final MisfitImportStatus status;

  const _WorkoutStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      MisfitImportStatus.ready => ('Ready', Colors.green),
      MisfitImportStatus.review => ('Review', Colors.orange),
      MisfitImportStatus.tbdLater => ('Deferred', Colors.blueGrey),
      MisfitImportStatus.skip => ('Skipped', Colors.grey),
    };

    return _LabelBadge(label: label, color: color);
  }
}

class _BenchmarkStatusBadge extends StatelessWidget {
  final MisfitBenchmarkResultStatus status;

  const _BenchmarkStatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      MisfitBenchmarkResultStatus.selected => ('Result found', Colors.green),
      MisfitBenchmarkResultStatus.needsReview => ('Review', Colors.orange),
      MisfitBenchmarkResultStatus.excluded => ('Excluded', Colors.grey),
      MisfitBenchmarkResultStatus.missing => ('No result', Colors.blueGrey),
    };

    return _LabelBadge(label: label, color: color);
  }
}

class _LabelBadge extends StatelessWidget {
  final String label;
  final Color color;

  const _LabelBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
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
