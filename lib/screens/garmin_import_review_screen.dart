import 'package:flutter/material.dart';

import '../services/garmin_workout_import_service.dart';

typedef GarminImportCommitter =
    Future<List<GarminImportResult>> Function(GarminImportPlan plan);

class GarminImportReviewScreen extends StatefulWidget {
  final GarminImportPlan plan;
  final GarminImportCommitter committer;

  const GarminImportReviewScreen({
    super.key,
    required this.plan,
    required this.committer,
  });

  @override
  State<GarminImportReviewScreen> createState() {
    return _GarminImportReviewScreenState();
  }
}

class _GarminImportReviewScreenState extends State<GarminImportReviewScreen> {
  bool _acknowledged = false;
  bool _isCommitting = false;
  String? _errorMessage;
  List<GarminImportResult>? _results;

  int get _readyCount => widget.plan.items
      .where((item) => item.disposition == GarminImportDisposition.ready)
      .length;

  int get _duplicateCount => widget.plan.items
      .where(
        (item) => item.disposition == GarminImportDisposition.exactDuplicate,
      )
      .length;

  int get _conflictCount => widget.plan.items
      .where((item) => item.disposition == GarminImportDisposition.dateConflict)
      .length;

  Future<void> _commit() async {
    if (!_acknowledged || _readyCount == 0) {
      return;
    }

    setState(() {
      _isCommitting = true;
      _errorMessage = null;
      _results = null;
    });

    try {
      final results = await widget.committer(widget.plan);

      if (!mounted) {
        return;
      }

      setState(() {
        _results = results;
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
          _isCommitting = false;
        });
      }
    }
  }

  String _dispositionLabel(GarminImportDisposition disposition) {
    return switch (disposition) {
      GarminImportDisposition.ready => 'Ready to schedule',
      GarminImportDisposition.exactDuplicate =>
        'Already scheduled — will be skipped',
      GarminImportDisposition.dateConflict => 'Date conflict — will be blocked',
    };
  }

  IconData _dispositionIcon(GarminImportDisposition disposition) {
    return switch (disposition) {
      GarminImportDisposition.ready => Icons.check_circle_outline,
      GarminImportDisposition.exactDuplicate => Icons.event_available,
      GarminImportDisposition.dateConflict => Icons.warning_amber,
    };
  }

  String _resultLabel(GarminImportResultStatus status) {
    return switch (status) {
      GarminImportResultStatus.scheduled => 'Scheduled',
      GarminImportResultStatus.skippedDuplicate => 'Skipped duplicate',
      GarminImportResultStatus.blockedConflict => 'Blocked conflict',
      GarminImportResultStatus.failed => 'Failed',
    };
  }

  @override
  Widget build(BuildContext context) {
    final results = _results;

    return Scaffold(
      appBar: AppBar(title: const Text('Review Garmin Import')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            color: Theme.of(context).colorScheme.secondaryContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                '$_readyCount ready • '
                '$_duplicateCount already scheduled • '
                '$_conflictCount conflicts',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
          ),
          const SizedBox(height: 12),
          for (final item in widget.plan.items)
            Card(
              child: ListTile(
                leading: Icon(_dispositionIcon(item.disposition)),
                title: Text(item.workout.workoutName),
                subtitle: Text(
                  '${item.workout.date}\n'
                  '${_dispositionLabel(item.disposition)}',
                ),
                isThreeLine: true,
              ),
            ),
          const SizedBox(height: 12),
          if (_readyCount == 0)
            Card(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'There are no calendar-clear workouts to schedule. '
                  'Garmin will not be changed.',
                ),
              ),
            )
          else ...[
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: CheckboxListTile(
                key: const Key('garminImportAcknowledgement'),
                value: _acknowledged,
                onChanged: _isCommitting
                    ? null
                    : (value) {
                        setState(() {
                          _acknowledged = value ?? false;
                        });
                      },
                title: Text(
                  'I understand this will create and schedule '
                  '$_readyCount workout${_readyCount == 1 ? '' : 's'} '
                  'on Garmin.',
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
            ),
            const SizedBox(height: 12),
          ],
          FilledButton.icon(
            key: const Key('garminConfirmImportButton'),
            onPressed: _readyCount == 0 || !_acknowledged || _isCommitting
                ? null
                : _commit,
            icon: _isCommitting
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.cloud_upload_outlined),
            label: Text(
              _isCommitting
                  ? 'Scheduling…'
                  : 'Schedule $_readyCount workout'
                        '${_readyCount == 1 ? '' : 's'}',
            ),
          ),
          if (_errorMessage != null) ...[
            const SizedBox(height: 12),
            Card(
              color: Theme.of(context).colorScheme.errorContainer,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(_errorMessage!),
              ),
            ),
          ],
          if (results != null) ...[
            const SizedBox(height: 20),
            Text(
              'Import results',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            for (final result in results)
              Card(
                child: ListTile(
                  title: Text(result.workout.workoutName),
                  subtitle: Text(
                    '${_resultLabel(result.status)}\n${result.message}',
                  ),
                  isThreeLine: true,
                ),
              ),
          ],
        ],
      ),
    );
  }
}
