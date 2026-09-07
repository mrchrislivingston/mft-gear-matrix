// ignore_for_file: avoid_print

import 'dart:io';

import 'package:mft_gear_matrix/services/misfit_benchmark_candidate_reader.dart';
import 'package:mft_gear_matrix/services/misfit_benchmark_normalizer.dart';
import 'package:mft_gear_matrix/services/misfit_candidate_reader.dart';
import 'package:mft_gear_matrix/services/misfit_csv_service.dart';
import 'package:mft_gear_matrix/services/misfit_date_resolver.dart';
import 'package:mft_gear_matrix/services/misfit_normalization_preview_service.dart';
import 'package:mft_gear_matrix/services/misfit_workout_parser.dart';

const _inputDirectory = 'tools/historical_import/input';

const _orderedFiles = [
  'Chris Livingston - Remote Coaching - OffSZN 1 _ 2025.csv',
  'Chris Livingston - Remote Coaching - OffSZN2 _ 2025.csv',
  'Chris Livingston - Remote Coaching - The Summit Games 2025.csv',
  'Chris Livingston - Remote Coaching - Phase 1 2025.csv',
  'Chris Livingston - Remote Coaching - Phase II 2025_2026.csv',
  'Chris Livingston - Remote Coaching - Phase III 2026.csv',
  'Chris Livingston - Remote Coaching - Qtrs Prep 2026.csv',
  'Chris Livingston - Remote Coaching - Phase 0 _ 2026.csv',
  'Chris Livingston - Remote Coaching - OS1_2026.csv',
  'Chris Livingston - Remote Coaching - OS2_2026.csv',
];

String _preview(String value) {
  final compact = value.replaceAll(RegExp(r'\s+'), ' ').trim();

  if (compact.length <= 300) {
    return compact.isEmpty ? '(empty)' : compact;
  }

  return '${compact.substring(0, 300)}…';
}

Future<void> main() async {
  const csvService = MisfitCsvService();
  const dateResolver = MisfitDateResolver();
  const candidateReader = MisfitCandidateReader();
  const normalizationService = MisfitNormalizationPreviewService();
  const benchmarkReader = MisfitBenchmarkCandidateReader();
  const benchmarkNormalizer = MisfitBenchmarkNormalizer();

  var totalMatrixImportable = 0;
  var totalBenchmarkImportable = 0;
  var warningCount = 0;

  print('Historical Input Audit');
  print('=' * 100);

  for (final fileName in _orderedFiles) {
    final file = File('$_inputDirectory/$fileName');

    if (!await file.exists()) {
      stderr.writeln('MISSING: ${file.path}');
      exitCode = 1;
      continue;
    }

    final startYear = dateResolver.suggestedStartYear(fileName);

    if (startYear == null) {
      stderr.writeln('YEAR UNRESOLVED: $fileName');
      exitCode = 1;
      continue;
    }

    final document = csvService.decodeBytes(await file.readAsBytes());

    final matrix = candidateReader.read(document, startYear: startYear);
    final matrixNormalization = normalizationService.normalizeImportable(
      matrix,
    );

    final benchmarks = benchmarkReader.read(document, startYear: startYear);
    final benchmarkNormalization = benchmarkNormalizer.normalizeAll(
      benchmarks,
      sourceWorkbook: fileName.replaceFirst(
        RegExp(r'\.csv$', caseSensitive: false),
        '',
      ),
    );

    final matrixImportable = matrixNormalization.readySuccessful;
    final benchmarkImportable = benchmarkNormalization.successful;

    totalMatrixImportable += matrixImportable;
    totalBenchmarkImportable += benchmarkImportable;

    final hasWarnings =
        matrix.review > 0 ||
        matrix.deferred > 0 ||
        matrixNormalization.readyFailed > 0 ||
        benchmarks.needsReview > 0 ||
        benchmarkNormalization.failed > 0;

    if (hasWarnings) {
      warningCount++;
    }

    print(fileName);
    print(
      '  Year: $startYear | '
      'Rows: ${document.rowCount} | '
      'Columns: ${document.maximumColumnCount}',
    );
    print(
      '  Matrix: found ${matrix.total}, '
      'ready ${matrix.ready}, '
      'review ${matrix.review}, '
      'deferred ${matrix.deferred}, '
      'skipped ${matrix.skipped}',
    );
    print(
      '  Matrix parsing: '
      '${matrixNormalization.readySuccessful}/'
      '${matrixNormalization.readyTotal} ready parsed, '
      '${matrixNormalization.readyFailed} failed',
    );
    print(
      '  Benchmarks: found ${benchmarks.total}, '
      'results ${benchmarks.selected}, '
      'review ${benchmarks.needsReview}, '
      'excluded ${benchmarks.excluded}, '
      'missing ${benchmarks.missing}',
    );
    print(
      '  Benchmark parsing: '
      '${benchmarkNormalization.successful} parsed, '
      '${benchmarkNormalization.failed} failed',
    );
    print(
      '  EXPECTED IMPORT: '
      '$matrixImportable Matrix + '
      '$benchmarkImportable benchmarks',
    );

    for (final attempt in matrixNormalization.attempts) {
      if (attempt.error == null) {
        continue;
      }

      final candidate = attempt.candidate;
      print(
        '  MATRIX PARSE FAILURE: '
        '${candidate.date} ${candidate.programDay} | '
        '${candidate.prescription} ${candidate.modality} | '
        'row ${candidate.sourceRow}, column ${candidate.sourceColumn}',
      );
      print('    Error: ${attempt.error}');
      print('    Programming: ${_preview(candidate.programmingText)}');
      print('    Result: ${_preview(candidate.resultText)}');
    }

    for (final candidate in matrix.candidates) {
      if (candidate.importStatus != MisfitImportStatus.review &&
          candidate.importStatus != MisfitImportStatus.tbdLater) {
        continue;
      }

      print(
        '  MATRIX ${candidate.importStatus.name.toUpperCase()}: '
        '${candidate.date} ${candidate.programDay} | '
        '${candidate.prescription} ${candidate.modality} | '
        'row ${candidate.sourceRow}, column ${candidate.sourceColumn}',
      );
      print('    Reason: ${candidate.statusReason}');
      print('    Programming: ${_preview(candidate.programmingText)}');
      print('    Result: ${_preview(candidate.resultText)}');
    }

    for (final attempt in benchmarkNormalization.attempts) {
      if (attempt.error == null) {
        continue;
      }

      final candidate = attempt.candidate;
      print(
        '  BENCHMARK PARSE FAILURE: '
        '${candidate.date} ${candidate.programDay} | '
        '${candidate.benchmarkName} | '
        'row ${candidate.sourceRow}, column ${candidate.sourceColumn}',
      );
      print('    Error: ${attempt.error}');
      print('    Result: ${_preview(candidate.resultText)}');
    }

    for (final candidate in benchmarks.candidates) {
      if (candidate.resultStatus != MisfitBenchmarkResultStatus.needsReview) {
        continue;
      }

      print(
        '  BENCHMARK REVIEW: '
        '${candidate.date} ${candidate.programDay} | '
        '${candidate.benchmarkName} | '
        'row ${candidate.sourceRow}, column ${candidate.sourceColumn}',
      );
      print('    Reason: ${candidate.resultReason}');
      print('    Result: ${_preview(candidate.resultText)}');
    }

    if (hasWarnings) {
      print('  WARNING: This workbook requires closer review.');
    }

    print('-' * 100);
  }

  print('TOTAL EXPECTED IMPORT');
  print(
    '$totalMatrixImportable Matrix + '
    '$totalBenchmarkImportable benchmarks = '
    '${totalMatrixImportable + totalBenchmarkImportable} records',
  );
  print('Workbooks requiring closer review: $warningCount');

  if (exitCode != 0) {
    exit(exitCode);
  }
}
