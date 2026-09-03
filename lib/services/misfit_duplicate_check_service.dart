import 'database_service.dart';
import 'misfit_candidate_reader.dart';
import 'misfit_normalization_preview_service.dart';

typedef MisfitWorkoutExistsLookup =
    Future<bool> Function({
      required String prescriptionId,
      required String modality,
      required String date,
      required String workDuration,
      required int intervalCount,
      required String sourceWorkbook,
      required String programDay,
    });

class MisfitDuplicateSummary {
  final List<MisfitWorkoutCandidate> checkedCandidates;
  final Set<MisfitWorkoutCandidate> duplicateCandidates;

  const MisfitDuplicateSummary({
    required this.checkedCandidates,
    required this.duplicateCandidates,
  });

  int get checked => checkedCandidates.length;
  int get duplicates => duplicateCandidates.length;
  int get newWorkouts => checked - duplicates;

  bool isDuplicate(MisfitWorkoutCandidate candidate) {
    return duplicateCandidates.contains(candidate);
  }
}

class MisfitDuplicateCheckService {
  final DatabaseService _databaseService;
  final MisfitWorkoutExistsLookup? lookupOverride;

  MisfitDuplicateCheckService({
    DatabaseService? databaseService,
    this.lookupOverride,
  }) : _databaseService = databaseService ?? DatabaseService.instance;

  Future<MisfitDuplicateSummary> check({
    required MisfitNormalizationSummary normalizationSummary,
    required String sourceWorkbook,
  }) async {
    final checkedCandidates = <MisfitWorkoutCandidate>[];
    final duplicateCandidates = <MisfitWorkoutCandidate>{};
    final lookup = lookupOverride ?? _databaseService.workoutExists;

    for (final attempt in normalizationSummary.attempts) {
      final workout = attempt.workout;
      if (workout == null) {
        continue;
      }

      final candidate = attempt.candidate;
      if (candidate.date.isEmpty) {
        throw FormatException(
          '${candidate.programDay} has an unresolved workout date',
        );
      }

      checkedCandidates.add(candidate);

      final exists = await lookup(
        prescriptionId: workout.prescriptionId,
        modality: workout.modality,
        date: candidate.date,
        workDuration: workout.executionPlan.workDuration,
        intervalCount: workout.executionPlan.intervalCount,
        sourceWorkbook: sourceWorkbook,
        programDay: candidate.programDay,
      );

      if (exists) {
        duplicateCandidates.add(candidate);
      }
    }

    return MisfitDuplicateSummary(
      checkedCandidates: List.unmodifiable(checkedCandidates),
      duplicateCandidates: Set.unmodifiable(duplicateCandidates),
    );
  }
}
