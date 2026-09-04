import '../models/workout_metric.dart';
import 'misfit_candidate_reader.dart';
import 'misfit_distance_interval_parser.dart';
import 'misfit_execution_plan_parser.dart';
import 'misfit_interval_parser.dart';
import 'misfit_interval_time_parser.dart';
import 'misfit_metric_parser.dart';
import 'misfit_pace_distance_interval_parser.dart';
import 'misfit_structured_interval_parser.dart';
import 'misfit_workout_parser.dart';

class MisfitNormalizedInterval {
  final int intervalNumber;
  final Map<String, String> values;

  const MisfitNormalizedInterval({
    required this.intervalNumber,
    required this.values,
  });
}

class MisfitNormalizedWorkoutPreview {
  final String prescriptionId;
  final String modality;
  final MisfitExecutionPlan executionPlan;
  final String duration;
  final WorkoutMetric? scoringMetric;
  final List<MisfitNormalizedInterval> intervals;

  const MisfitNormalizedWorkoutPreview({
    required this.prescriptionId,
    required this.modality,
    required this.executionPlan,
    required this.duration,
    this.scoringMetric,
    required this.intervals,
  });
}

class MisfitWorkoutNormalizer {
  final MisfitStructuredIntervalParser structuredParser;
  final MisfitPaceDistanceIntervalParser paceDistanceParser;
  final MisfitIntervalParser intervalParser;
  final MisfitDistanceIntervalParser distanceParser;
  final MisfitIntervalTimeParser intervalTimeParser;
  final MisfitMetricParser metricParser;

  const MisfitWorkoutNormalizer({
    this.structuredParser = const MisfitStructuredIntervalParser(),
    this.paceDistanceParser = const MisfitPaceDistanceIntervalParser(),
    this.intervalParser = const MisfitIntervalParser(),
    this.distanceParser = const MisfitDistanceIntervalParser(),
    this.intervalTimeParser = const MisfitIntervalTimeParser(),
    this.metricParser = const MisfitMetricParser(),
  });

  MisfitNormalizedWorkoutPreview normalize(MisfitWorkoutCandidate candidate) {
    final duration = _extractDuration(candidate);
    final executionPlan =
        candidate.executionPlan ?? _defaultExecutionPlan(candidate);

    var intervalValues = _extractIntervalValues(candidate);

    if (intervalValues.isEmpty &&
        candidate.workoutType == MisfitWorkoutType.zone &&
        metricParser.extractDuration(candidate.resultText).isNotEmpty) {
      intervalValues = [const <String, String>{}];
    }

    if (intervalValues.isEmpty) {
      throw const FormatException(
        'No supported workout metrics could be extracted',
      );
    }

    final intervals = [
      for (var index = 0; index < intervalValues.length; index++)
        MisfitNormalizedInterval(
          intervalNumber: index + 1,
          values: _canonicalizeIntervalValues(candidate, intervalValues[index]),
        ),
    ];

    return MisfitNormalizedWorkoutPreview(
      prescriptionId: candidate.prescription,
      modality: candidate.modality,
      executionPlan: executionPlan,
      duration: duration,
      scoringMetric: _scoringMetricFor(candidate),
      intervals: List.unmodifiable(intervals),
    );
  }

  String _extractDuration(MisfitWorkoutCandidate candidate) {
    if (candidate.workoutType != MisfitWorkoutType.zone) {
      return '';
    }

    if (candidate.prescription != 'Z1' && candidate.prescription != 'Z2') {
      throw const FormatException(
        'Zone candidate requires a Z1 or Z2 prescription',
      );
    }

    if (!{'bikeErg', 'run', 'row', 'echo'}.contains(candidate.modality)) {
      throw const FormatException('Unsupported Zone modality');
    }

    var duration = metricParser.extractDuration(candidate.resultText);

    if (duration.isEmpty) {
      duration = metricParser.extractDuration(candidate.programmingText);
    }

    if (duration.isEmpty) {
      throw const FormatException(
        'Zone workout duration could not be extracted',
      );
    }

    return duration;
  }

  List<Map<String, String>> _extractIntervalValues(
    MisfitWorkoutCandidate candidate,
  ) {
    final resultText = candidate.resultText;

    final structured = structuredParser.extract(resultText);
    if (structured.isNotEmpty) {
      return structured;
    }

    if (candidate.modality == 'echo' &&
        _scoringMetricFor(candidate) == WorkoutMetric.calories) {
      final calorieRounds = structuredParser.extractLabeledRoundCalories(
        resultText,
      );

      if (calorieRounds.isNotEmpty) {
        return calorieRounds;
      }
    }

    final paceDistance = paceDistanceParser.extract(resultText);
    if (paceDistance.isNotEmpty) {
      return paceDistance;
    }

    final paces = intervalParser.extractIntervalPaces(resultText);
    if (paces.isNotEmpty) {
      return [
        for (final pace in paces) {'primaryMetric': pace},
      ];
    }

    final distances = distanceParser.extract(resultText);
    if (distances.isNotEmpty) {
      return distances;
    }

    final times = intervalTimeParser.extract(resultText);
    if (times.isNotEmpty) {
      return [
        for (final time in times) {'primaryMetric': time},
      ];
    }

    final averages = metricParser.extractAverageMetrics(resultText);
    if (averages.isNotEmpty) {
      return [averages];
    }

    return const [];
  }

  Map<String, String> _canonicalizeIntervalValues(
    MisfitWorkoutCandidate candidate,
    Map<String, String> values,
  ) {
    final canonicalValues = Map<String, String>.from(values);

    return Map.unmodifiable(canonicalValues);
  }

  WorkoutMetric? _scoringMetricFor(MisfitWorkoutCandidate candidate) {
    if (candidate.modality != 'echo') {
      return null;
    }

    final programming = candidate.programmingText.toLowerCase();

    if (RegExp(r'\b(?:meters?|metres?|distance)\b').hasMatch(programming)) {
      return WorkoutMetric.distance;
    }

    if (RegExp(r'\bwatts?\b').hasMatch(programming)) {
      return WorkoutMetric.watts;
    }

    return WorkoutMetric.calories;
  }

  MisfitExecutionPlan _defaultExecutionPlan(MisfitWorkoutCandidate candidate) {
    final defaults = switch (candidate.prescription) {
      'G1' => const MisfitExecutionPlan(
        workDuration: '15:00',
        intervalCount: 2,
      ),
      'G2' => const MisfitExecutionPlan(
        workDuration: '13:00',
        intervalCount: 2,
      ),
      'G3' => const MisfitExecutionPlan(workDuration: '8:00', intervalCount: 3),
      'G4' => const MisfitExecutionPlan(workDuration: '6:00', intervalCount: 3),
      'G5' => const MisfitExecutionPlan(workDuration: '4:00', intervalCount: 4),
      'G6' => const MisfitExecutionPlan(workDuration: '3:30', intervalCount: 4),
      'G7' => const MisfitExecutionPlan(workDuration: '2:30', intervalCount: 5),
      'G8' => const MisfitExecutionPlan(workDuration: '1:30', intervalCount: 7),
      _ => const MisfitExecutionPlan(workDuration: '', intervalCount: 1),
    };

    return defaults;
  }
}
