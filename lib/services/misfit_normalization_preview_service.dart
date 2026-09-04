import 'misfit_candidate_reader.dart';
import 'misfit_workout_normalizer.dart';
import 'misfit_workout_parser.dart';

class MisfitNormalizationAttempt {
  final MisfitWorkoutCandidate candidate;
  final MisfitNormalizedWorkoutPreview? workout;
  final String? error;

  const MisfitNormalizationAttempt({
    required this.candidate,
    required this.workout,
    required this.error,
  });

  bool get succeeded => workout != null;
}

class MisfitNormalizationSummary {
  final List<MisfitNormalizationAttempt> attempts;

  const MisfitNormalizationSummary({required this.attempts});

  int get successful {
    return attempts.where((attempt) => attempt.succeeded).length;
  }

  int get failed => attempts.length - successful;

  int get readyTotal {
    return attempts
        .where(
          (attempt) =>
              attempt.candidate.importStatus == MisfitImportStatus.ready,
        )
        .length;
  }

  int get readySuccessful {
    return attempts
        .where(
          (attempt) =>
              attempt.candidate.importStatus == MisfitImportStatus.ready &&
              attempt.succeeded,
        )
        .length;
  }

  int get readyFailed => readyTotal - readySuccessful;

  MisfitNormalizationAttempt? attemptFor(MisfitWorkoutCandidate candidate) {
    for (final attempt in attempts) {
      if (identical(attempt.candidate, candidate)) {
        return attempt;
      }
    }

    return null;
  }
}

class MisfitNormalizationPreviewService {
  final MisfitWorkoutNormalizer normalizer;

  const MisfitNormalizationPreviewService({
    this.normalizer = const MisfitWorkoutNormalizer(),
  });

  MisfitNormalizationSummary normalizeImportable(
    MisfitCandidateSummary candidateSummary,
  ) {
    final attempts = <MisfitNormalizationAttempt>[];

    for (final candidate in candidateSummary.candidates) {
      if (candidate.importStatus != MisfitImportStatus.ready &&
          candidate.importStatus != MisfitImportStatus.review) {
        continue;
      }

      try {
        attempts.add(
          MisfitNormalizationAttempt(
            candidate: candidate,
            workout: normalizer.normalize(candidate),
            error: null,
          ),
        );
      } on FormatException catch (error) {
        attempts.add(
          MisfitNormalizationAttempt(
            candidate: candidate,
            workout: null,
            error: error.message.toString(),
          ),
        );
      }
    }

    return MisfitNormalizationSummary(attempts: List.unmodifiable(attempts));
  }
}
