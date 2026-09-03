import 'package:flutter/material.dart';

import '../services/misfit_candidate_reader.dart';
import '../services/misfit_workout_parser.dart';

class ImportCandidateReviewScreen extends StatefulWidget {
  final MisfitCandidateSummary summary;

  const ImportCandidateReviewScreen({required this.summary, super.key});

  @override
  State<ImportCandidateReviewScreen> createState() {
    return _ImportCandidateReviewScreenState();
  }
}

class _ImportCandidateReviewScreenState
    extends State<ImportCandidateReviewScreen> {
  MisfitImportStatus? _filter = MisfitImportStatus.ready;

  @override
  Widget build(BuildContext context) {
    final candidates = widget.summary.candidates.where((candidate) {
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
              ],
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
                      return _CandidateCard(candidate: candidates[index]);
                    },
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
        selected: _filter == status,
        onSelected: (_) {
          setState(() {
            _filter = status;
          });
        },
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  final MisfitWorkoutCandidate candidate;

  const _CandidateCard({required this.candidate});

  @override
  Widget build(BuildContext context) {
    final prescription = candidate.prescription.isEmpty
        ? candidate.workoutType.name
        : candidate.prescription;
    final modality = candidate.modality.isEmpty
        ? 'Unknown modality'
        : candidate.modality;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        title: Text('$prescription • $modality'),
        subtitle: Text(
          '${candidate.dateHeader}\n'
          'Spreadsheet row ${candidate.sourceRow}, '
          'column ${candidate.sourceColumn}',
        ),
        trailing: _StatusBadge(status: candidate.importStatus),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            candidate.statusReason,
            style: Theme.of(context).textTheme.labelLarge,
          ),
          if (candidate.executionPlan case final plan?) ...[
            const SizedBox(height: 12),
            Text(
              'Execution: ${plan.intervalCount} intervals '
              '× ${plan.workDuration}',
              style: Theme.of(context).textTheme.labelLarge,
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
