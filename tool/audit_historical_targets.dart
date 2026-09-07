// ignore_for_file: avoid_print

import 'dart:io';

import 'package:mft_gear_matrix/services/misfit_candidate_reader.dart';
import 'package:mft_gear_matrix/services/misfit_csv_service.dart';
import 'package:mft_gear_matrix/services/misfit_date_resolver.dart';

const _inputDirectory = 'tools/historical_import/input';

const _orderedFiles = [
  'Chris Livingston - Remote Coaching - OffSZN 1 _ 2025.csv',
  'Chris Livingston - Remote Coaching - OffSZN2 _ 2025.csv',
  'Chris Livingston - Remote Coaching - The Summit Games 2025.csv',
  'Chris Livingston - Remote Coaching - Phase 1 2025.csv',
  'Chris Livingston - Remote Coaching - Phase II 2025_2026.csv',
  'Chris Livingston - Remote Coaching - Phase III 2026.csv',
  'Chris Livingston - Remote Coaching - Qtrs Prep 2026.csv',
  'Chris Livingston - Remote Coaching - OS1_2026.csv',
  'Chris Livingston - Remote Coaching - OS2_2026.csv',
  'Chris Livingston - Remote Coaching - Phase 0 _ 2026.csv',
];

final _unitOrTargetPattern = RegExp(
  r'\b(?:'
  r'target|targeting|pace|'
  r'min\s*/\s*mile|mile\s+pace|'
  r'min\s*/\s*(?:500|1000)m|'
  r'\/\s*(?:500|1000)m|'
  r'rpm|watts?|'
  r'cal(?:orie)?s?\s*\/\s*(?:hr|hour)|'
  r'bpm|heart\s*rate|'
  r'working\s+window|'
  r'aim\s+to\s+hold'
  r')\b',
  caseSensitive: false,
);

final _prescriptionValuePattern = RegExp(
  r'\b(?:G[1-8]|P[1-4]|[1-8](?:st|nd|rd|th)\s+Gear)'
  r'\s*[-:]\s*'
  r'(?:\d|:\d)',
  caseSensitive: false,
);

final _standaloneRangePattern = RegExp(
  r'^\s*'
  r'\d{1,2}:\d{2}(?:\.\d+)?'
  r'\s*[-–]\s*'
  r'\d{1,2}:\d{2}(?:\.\d+)?'
  r'\s*$',
);

String _clean(String value) {
  return value.replaceAll(RegExp(r'\s+'), ' ').trim();
}

String _tsv(String value) {
  return _clean(value).replaceAll('\t', ' ');
}

bool _isTargetEvidence(String line) {
  final cleaned = _clean(line);
  if (cleaned.isEmpty) {
    return false;
  }

  return _unitOrTargetPattern.hasMatch(cleaned) ||
      _prescriptionValuePattern.hasMatch(cleaned) ||
      _standaloneRangePattern.hasMatch(cleaned);
}

Iterable<String> _evidenceLines(String text) sync* {
  for (final line in text.split('\n')) {
    if (_isTargetEvidence(line)) {
      yield _clean(line);
    }
  }
}

String _metricHint(String modality, String line) {
  final lower = line.toLowerCase();

  if (lower.contains('rpm')) {
    return 'rpm';
  }
  if (lower.contains('watt')) {
    return 'watts';
  }
  if (lower.contains('cal/hr') ||
      lower.contains('cals/hr') ||
      lower.contains('calorie/hour') ||
      lower.contains('calories/hour')) {
    return 'caloriesPerHour';
  }
  if (lower.contains('bpm') || lower.contains('heart rate')) {
    return 'heartRateFormula';
  }

  return switch (modality) {
    'run' => 'minPerMile',
    'row' || 'ski' => 'minPer500m',
    'bikeErg' => 'minPer1000m',
    'echo' => 'rpm',
    _ => 'REVIEW',
  };
}

Future<void> main() async {
  const csvService = MisfitCsvService();
  const dateResolver = MisfitDateResolver();
  const candidateReader = MisfitCandidateReader();

  final emitted = <String>{};
  var evidenceCount = 0;

  print(
    'workbook\tdate\tprogram_day\trow\tcolumn\t'
    'prescription\tmodality\tmetric_hint\tsource\tevidence',
  );

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
    final summary = candidateReader.read(document, startYear: startYear);

    for (final candidate in summary.candidates) {
      final sources = <(String, String)>[
        ('PROGRAMMING', candidate.programmingText),
        ('RESULT', candidate.resultText),
      ];

      for (final source in sources) {
        for (final line in _evidenceLines(source.$2)) {
          final key = [
            fileName,
            candidate.sourceRow,
            candidate.sourceColumn,
            candidate.prescription,
            candidate.modality,
            source.$1,
            line,
          ].join('|');

          if (!emitted.add(key)) {
            continue;
          }

          evidenceCount++;

          print(
            [
              fileName.replaceFirst(
                RegExp(r'\.csv$', caseSensitive: false),
                '',
              ),
              candidate.date,
              candidate.programDay,
              candidate.sourceRow,
              candidate.sourceColumn,
              candidate.prescription,
              candidate.modality,
              _metricHint(candidate.modality, line),
              source.$1,
              line,
            ].map((value) => _tsv(value.toString())).join('\t'),
          );
        }
      }
    }
  }

  stderr.writeln('Target-evidence rows: $evidenceCount');

  if (exitCode != 0) {
    exit(exitCode);
  }
}
