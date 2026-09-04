import '../models/log_entry.dart';
import '../models/modality.dart';
import '../models/workout_metric.dart';
import 'misfit_candidate_reader.dart';
import 'misfit_normalization_preview_service.dart';

class MisfitLogEntryBuilder {
  const MisfitLogEntryBuilder();

  LogEntry build({
    required MisfitNormalizationAttempt attempt,
    required String sourceWorkbook,
  }) {
    final workout = attempt.workout;
    if (workout == null) {
      throw FormatException(
        '${attempt.candidate.programDay} has no normalized workout',
      );
    }

    final candidate = attempt.candidate;
    if (candidate.date.isEmpty) {
      throw FormatException(
        '${candidate.programDay} has an unresolved workout date',
      );
    }

    final modality = _modalityFor(workout.modality);

    final intervals = workout.intervals.map((interval) {
      final values = <WorkoutMetric, String>{};

      for (final entry in interval.values.entries) {
        values[_metricFor(entry.key)] = entry.value;
      }

      return IntervalResult(
        intervalNumber: interval.intervalNumber,
        values: Map.unmodifiable(values),
      );
    }).toList();

    return LogEntry.forPrescription(
      prescriptionId: workout.prescriptionId,
      modality: modality,
      date: DateTime.parse(candidate.date),
      sourceWorkbook: sourceWorkbook,
      programDay: candidate.programDay,
      duration: workout.duration,
      workDuration: workout.executionPlan.workDuration,
      intervalCount: workout.executionPlan.intervalCount,
      scoringMetric: workout.scoringMetric,
      notes: candidate.resultText,
      intervals: List.unmodifiable(intervals),
    );
  }

  List<LogEntry> buildSelected({
    required MisfitNormalizationSummary normalizationSummary,
    required Set<MisfitWorkoutCandidate> includedCandidates,
    required String sourceWorkbook,
  }) {
    final logs = <LogEntry>[];

    for (final attempt in normalizationSummary.attempts) {
      if (!includedCandidates.contains(attempt.candidate)) {
        continue;
      }

      logs.add(build(attempt: attempt, sourceWorkbook: sourceWorkbook));
    }

    return List.unmodifiable(logs);
  }

  Modality _modalityFor(String value) {
    for (final modality in Modality.values) {
      if (modality.name == value) {
        return modality;
      }
    }

    throw FormatException('Unsupported workout modality: $value');
  }

  WorkoutMetric _metricFor(String value) {
    for (final metric in WorkoutMetric.values) {
      if (metric.storageKey == value) {
        return metric;
      }
    }

    throw FormatException('Unsupported workout metric: $value');
  }
}
