import 'database_service.dart';
import 'misfit_benchmark_candidate_reader.dart';
import 'misfit_benchmark_normalizer.dart';

typedef MisfitBenchmarkAttemptExistsLookup =
    Future<bool> Function({
      required String benchmarkId,
      required String date,
      required String sourceWorkbook,
      required String programDay,
    });

class MisfitBenchmarkDuplicateSummary {
  final List<MisfitBenchmarkCandidate> checkedCandidates;
  final Set<MisfitBenchmarkCandidate> duplicateCandidates;

  const MisfitBenchmarkDuplicateSummary({
    required this.checkedCandidates,
    required this.duplicateCandidates,
  });

  int get checked => checkedCandidates.length;
  int get duplicates => duplicateCandidates.length;
  int get newAttempts => checked - duplicates;

  bool isDuplicate(MisfitBenchmarkCandidate candidate) {
    return duplicateCandidates.contains(candidate);
  }
}

class MisfitBenchmarkDuplicateCheckService {
  final DatabaseService _databaseService;
  final MisfitBenchmarkAttemptExistsLookup? lookupOverride;

  MisfitBenchmarkDuplicateCheckService({
    DatabaseService? databaseService,
    this.lookupOverride,
  }) : _databaseService = databaseService ?? DatabaseService.instance;

  Future<MisfitBenchmarkDuplicateSummary> check({
    required MisfitBenchmarkNormalizationSummary normalizationSummary,
    required String sourceWorkbook,
  }) async {
    final checkedCandidates = <MisfitBenchmarkCandidate>[];
    final duplicateCandidates = <MisfitBenchmarkCandidate>{};
    final lookup = lookupOverride ?? _databaseService.benchmarkAttemptExists;

    for (final normalization in normalizationSummary.attempts) {
      final benchmarkAttempt = normalization.benchmarkAttempt;
      if (benchmarkAttempt == null) {
        continue;
      }

      final candidate = normalization.candidate;
      checkedCandidates.add(candidate);

      final exists = await lookup(
        benchmarkId: benchmarkAttempt.benchmarkId,
        date: candidate.date,
        sourceWorkbook: sourceWorkbook,
        programDay: candidate.programDay,
      );

      if (exists) {
        duplicateCandidates.add(candidate);
      }
    }

    return MisfitBenchmarkDuplicateSummary(
      checkedCandidates: List.unmodifiable(checkedCandidates),
      duplicateCandidates: Set.unmodifiable(duplicateCandidates),
    );
  }
}
