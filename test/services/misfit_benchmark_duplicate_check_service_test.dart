import 'package:flutter_test/flutter_test.dart';

import 'package:mft_gear_matrix/services/misfit_benchmark_candidate_reader.dart';
import 'package:mft_gear_matrix/services/misfit_benchmark_duplicate_check_service.dart';
import 'package:mft_gear_matrix/services/misfit_benchmark_normalizer.dart';
import 'package:mft_gear_matrix/services/misfit_date_resolver.dart';

void main() {
  MisfitBenchmarkCandidate candidate({
    required String key,
    required String date,
  }) {
    return MisfitBenchmarkCandidate(
      sourceRow: 1,
      sourceColumn: 2,
      resultSourceRow: 2,
      dateHeader: 'W1D1 July 27',
      programDay: 'W1D1',
      date: date,
      dateStatus: MisfitDateStatus.exact,
      benchmarkKey: key,
      benchmarkName: key,
      modality: '',
      programmingText: key,
      resultText: '21:33',
      resultStatus: MisfitBenchmarkResultStatus.selected,
      resultReason: 'Selected',
    );
  }

  test('identifies existing benchmark attempts by import identity', () async {
    final existing = candidate(key: 'continental_drive_75', date: '2026-07-27');
    final fresh = candidate(key: 'chuckles_1_2', date: '2026-07-28');

    final normalizationSummary = MisfitBenchmarkNormalizationSummary(
      attempts: [
        MisfitBenchmarkNormalizationAttempt(
          candidate: existing,
          benchmarkAttempt: const MisfitBenchmarkNormalizer().normalize(
            existing,
            sourceWorkbook: 'Phase 0',
          ),
        ),
        MisfitBenchmarkNormalizationAttempt(
          candidate: fresh,
          benchmarkAttempt: const MisfitBenchmarkNormalizer().normalize(
            fresh,
            sourceWorkbook: 'Phase 0',
          ),
        ),
      ],
    );

    final checkedKeys = <String>[];
    final service = MisfitBenchmarkDuplicateCheckService(
      lookupOverride:
          ({
            required benchmarkId,
            required date,
            required sourceWorkbook,
            required programDay,
          }) async {
            checkedKeys.add(benchmarkId);
            return benchmarkId == 'continental_drive_75';
          },
    );

    final summary = await service.check(
      normalizationSummary: normalizationSummary,
      sourceWorkbook: 'Phase 0',
    );

    expect(checkedKeys, ['continental_drive_75', 'chuckles_1_2']);
    expect(summary.checked, 2);
    expect(summary.duplicates, 1);
    expect(summary.newAttempts, 1);
    expect(summary.isDuplicate(existing), isTrue);
    expect(summary.isDuplicate(fresh), isFalse);
  });
}
