import 'misfit_benchmark_registry.dart';
import 'misfit_csv_service.dart';
import 'misfit_date_resolver.dart';
import 'misfit_workout_parser.dart';

enum MisfitBenchmarkResultStatus { selected, needsReview, excluded, missing }

class MisfitBenchmarkCandidate {
  final int sourceRow;
  final int sourceColumn;
  final int resultSourceRow;
  final String dateHeader;
  final String programDay;
  final String date;
  final MisfitDateStatus dateStatus;
  final String benchmarkKey;
  final String benchmarkName;
  final String modality;
  final String programmingText;
  final String resultText;
  final MisfitBenchmarkResultStatus resultStatus;
  final String resultReason;

  const MisfitBenchmarkCandidate({
    required this.sourceRow,
    required this.sourceColumn,
    required this.resultSourceRow,
    required this.dateHeader,
    required this.programDay,
    required this.date,
    required this.dateStatus,
    required this.benchmarkKey,
    required this.benchmarkName,
    required this.modality,
    required this.programmingText,
    required this.resultText,
    required this.resultStatus,
    required this.resultReason,
  });
}

class MisfitBenchmarkCandidateSummary {
  final List<MisfitBenchmarkCandidate> candidates;

  const MisfitBenchmarkCandidateSummary({required this.candidates});

  int get total => candidates.length;

  int get selected => candidates
      .where(
        (candidate) =>
            candidate.resultStatus == MisfitBenchmarkResultStatus.selected,
      )
      .length;

  int get needsReview => candidates
      .where(
        (candidate) =>
            candidate.resultStatus == MisfitBenchmarkResultStatus.needsReview,
      )
      .length;

  int get excluded => candidates
      .where(
        (candidate) =>
            candidate.resultStatus == MisfitBenchmarkResultStatus.excluded,
      )
      .length;

  int get missing => candidates
      .where(
        (candidate) =>
            candidate.resultStatus == MisfitBenchmarkResultStatus.missing,
      )
      .length;
}

class MisfitBenchmarkCandidateReader {
  final MisfitBenchmarkRegistry registry;
  final MisfitDateResolver dateResolver;
  final MisfitWorkoutParser workoutParser;

  const MisfitBenchmarkCandidateReader({
    this.registry = const MisfitBenchmarkRegistry(),
    this.dateResolver = const MisfitDateResolver(),
    this.workoutParser = const MisfitWorkoutParser(),
  });

  static final RegExp _weekDayPattern = RegExp(
    r'\bW(\d+)D(\d+)\b',
    caseSensitive: false,
  );

  static final RegExp _weekResultPattern = RegExp(
    r'^\s*WEEK\s+(\d+)\s*$',
    caseSensitive: false,
  );

  static final RegExp _writtenDatePattern = RegExp(
    r'\b(?:Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|'
    r'May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|'
    r'Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)'
    r'\s+\d{1,2}(?:st|nd|rd|th)?\b',
    caseSensitive: false,
  );

  static final RegExp _numericDatePattern = RegExp(
    r'\b\d{1,2}/\d{1,2}(?:/\d{2,4})?\b',
  );

  MisfitBenchmarkCandidateSummary read(
    MisfitCsvDocument document, {
    required int startYear,
  }) {
    final rows = document.rows;
    final dateHeaders = rows.map(_dateHeader).toList(growable: false);
    final resolution = dateResolver.resolve(
      headers: dateHeaders,
      startYear: startYear,
    );
    final candidates = <MisfitBenchmarkCandidate>[];
    final previousResults = <String, Set<String>>{};

    for (var rowIndex = 0; rowIndex < rows.length; rowIndex++) {
      final row = rows[rowIndex];
      final dateHeader = _dateHeader(row);

      if (!_isProgrammingHeader(dateHeader)) {
        continue;
      }

      final programDay = _extractProgramDay(dateHeader);
      final resolvedDate = resolution.dateFor(programDay);

      for (var columnIndex = 1; columnIndex < row.length; columnIndex++) {
        final programmingText = _cell(row, columnIndex);
        if (programmingText.isEmpty) {
          continue;
        }

        final matches = registry.findMatches([programmingText]);
        if (matches.isEmpty) {
          continue;
        }

        final possibleResults = _resultRows(
          rows,
          programmingRowIndex: rowIndex,
          columnIndex: columnIndex,
        );

        final modality = workoutParser
            .detectCandidateModalities(
              programmingText: programmingText,
              resultText: possibleResults.map((row) => row.text).join('\n'),
            )
            .join('/');

        for (final benchmark in matches) {
          final resultKey = '${benchmark.key}|$modality';
          final knownResults = previousResults.putIfAbsent(
            resultKey,
            () => <String>{},
          );

          final rawSelection = _selectBenchmarkResult(
            rows,
            programmingRowIndex: rowIndex,
            programmingColumnIndex: columnIndex,
            benchmarkKey: benchmark.key,
            programDay: programDay,
            previousResults: knownResults,
          );
          final selection = _classifySelectedResult(
            benchmark.key,
            rawSelection,
          );

          if (selection.text.isNotEmpty) {
            knownResults.add(selection.text);
          }

          candidates.add(
            MisfitBenchmarkCandidate(
              sourceRow: rowIndex + 1,
              sourceColumn: columnIndex + 1,
              resultSourceRow: selection.rowNumber,
              dateHeader: dateHeader,
              programDay: programDay,
              date: resolvedDate?.date ?? '',
              dateStatus: resolvedDate?.status ?? MisfitDateStatus.unresolved,
              benchmarkKey: benchmark.key,
              benchmarkName: benchmark.displayName,
              modality: modality,
              programmingText: programmingText,
              resultText: selection.text,
              resultStatus: selection.status,
              resultReason: selection.reason,
            ),
          );
        }
      }
    }

    return MisfitBenchmarkCandidateSummary(
      candidates: List.unmodifiable(candidates),
    );
  }

  _ResultSelection _classifySelectedResult(
    String benchmarkKey,
    _ResultSelection selection,
  ) {
    if (selection.status != MisfitBenchmarkResultStatus.selected) {
      return selection;
    }

    final result = selection.text;

    if (RegExp(
      r"\bskip(?:ped|ping)?\s+(?:the\s+)?gym\b",
      caseSensitive: false,
    ).hasMatch(result)) {
      return _ResultSelection.excluded(
        result,
        selection.rowNumber,
        'Result indicates benchmark was not completed',
      );
    }

    if (benchmarkKey == 'enzo_gorlomi' &&
        RegExp(
          r'\breplaced\b.+\bwith\b',
          caseSensitive: false,
          dotAll: true,
        ).hasMatch(result)) {
      return _ResultSelection.excluded(
        result,
        selection.rowNumber,
        'Recorded workout was modified',
      );
    }

    if (benchmarkKey == 'speed_not_volume' &&
        !RegExp(
          r'\b(?:'
          r'\d+\s*(?:rds?|rounds?)?\s*\+\s*\d+|'
          r'\d+\s*(?:rds?|rounds?)\s+\d+\s*reps?'
          r')\b',
          caseSensitive: false,
        ).hasMatch(result)) {
      return _ResultSelection.excluded(
        result,
        selection.rowNumber,
        'No completed benchmark score was recorded',
      );
    }

    return selection;
  }

  _ResultSelection _selectBenchmarkResult(
    List<List<String>> rows, {
    required int programmingRowIndex,
    required int programmingColumnIndex,
    required String benchmarkKey,
    required String programDay,
    required Set<String> previousResults,
  }) {
    final compatibleCells = _resultCells(rows, programmingRowIndex)
        .where((cell) => _isLikelyBenchmarkResult(benchmarkKey, cell.text))
        .toList();

    final targetWeek = _weekNumber(programDay);
    if (targetWeek != null) {
      final weekMatches = compatibleCells.where((cell) {
        final match = _weekResultPattern.firstMatch(cell.label);
        return match != null && int.parse(match.group(1)!) == targetWeek;
      }).toList();

      if (weekMatches.length == 1) {
        return _ResultSelection.selected(
          weekMatches.single.text,
          weekMatches.single.rowNumber,
          'Matched WEEK $targetWeek compatible result cell',
        );
      }

      if (weekMatches.length > 1) {
        return _ResultSelection.needsReview(
          'Multiple compatible WEEK $targetWeek result cells',
        );
      }
    }

    final sameColumn = compatibleCells
        .where((cell) => cell.columnIndex == programmingColumnIndex)
        .toList();

    if (sameColumn.length == 1) {
      return _ResultSelection.selected(
        sameColumn.single.text,
        sameColumn.single.rowNumber,
        'Compatible result found in programming column',
      );
    }

    final newCompatible = compatibleCells
        .where((cell) => !previousResults.contains(cell.text))
        .toList();

    if (newCompatible.length == 1) {
      return _ResultSelection.selected(
        newCompatible.single.text,
        newCompatible.single.rowNumber,
        newCompatible.length < compatibleCells.length
            ? 'Discarded an exact carried-forward result'
            : 'Compatible result found in another column',
      );
    }

    if (compatibleCells.length == 1) {
      return _ResultSelection.selected(
        compatibleCells.single.text,
        compatibleCells.single.rowNumber,
        'Compatible result found in another column',
      );
    }

    if (compatibleCells.length > 1) {
      return _ResultSelection.needsReview(
        'Multiple compatible benchmark result cells',
      );
    }

    return _selectSameColumnResult(
      _resultRows(
        rows,
        programmingRowIndex: programmingRowIndex,
        columnIndex: programmingColumnIndex,
      ),
      programDay: programDay,
      previousResults: previousResults,
    );
  }

  _ResultSelection _selectSameColumnResult(
    List<_ResultRow> rows, {
    required String programDay,
    required Set<String> previousResults,
  }) {
    final targetWeek = _weekNumber(programDay);

    if (targetWeek != null) {
      final weekMatches = rows.where((row) {
        final match = _weekResultPattern.firstMatch(row.label);
        return match != null && int.parse(match.group(1)!) == targetWeek;
      }).toList();

      if (weekMatches.length == 1) {
        return _ResultSelection.selected(
          weekMatches.single.text,
          weekMatches.single.rowNumber,
          'Matched WEEK $targetWeek result row',
        );
      }

      if (weekMatches.length > 1) {
        return _ResultSelection.needsReview(
          'Multiple WEEK $targetWeek result rows',
        );
      }
    }

    if (rows.length == 1) {
      return _ResultSelection.selected(
        rows.single.text,
        rows.single.rowNumber,
        'Single nonempty result row',
      );
    }

    if (rows.length > 1) {
      final newRows = rows
          .where((row) => !previousResults.contains(row.text))
          .toList();

      if (newRows.length == 1) {
        return _ResultSelection.selected(
          newRows.single.text,
          newRows.single.rowNumber,
          'Discarded an exact carried-forward result',
        );
      }

      return _ResultSelection.needsReview('Multiple possible result rows');
    }

    return const _ResultSelection.missing('No recorded benchmark result');
  }

  bool _isLikelyBenchmarkResult(String benchmarkKey, String resultText) {
    if (benchmarkKey == 'matt') {
      return RegExp(
        r'\bAvg(?:erage)?\s+Watts?\b|'
        r'\bTotal\s+Avg\b.*?\b\d+\s*w\b',
        caseSensitive: false,
        dotAll: true,
      ).hasMatch(resultText);
    }

    if (benchmarkKey.endsWith('_cube_test') || benchmarkKey == 'cube_steaked') {
      return RegExp(
        r'\bTotal\s+(?:Cals?|Calories?)\s*[-:]\s*\d+\b|'
        r'\bTotal\s*-\s*\d+\b',
        caseSensitive: false,
      ).hasMatch(resultText);
    }

    if (benchmarkKey.endsWith('_mount_doom')) {
      return RegExp(
        r'\bthrough\s+\d+\s+of\s+(?:the\s+)?'
        r'round\s+of\s+\d+\b',
        caseSensitive: false,
      ).hasMatch(resultText);
    }

    if (benchmarkKey == 'spiders_on_mars') {
      return RegExp(
        r'\b\d+\s+Cals?\b',
        caseSensitive: false,
      ).hasMatch(resultText);
    }

    if (benchmarkKey.startsWith('power_output_')) {
      return false;
    }

    return false;
  }

  List<_ResultCell> _resultCells(
    List<List<String>> rows,
    int programmingRowIndex,
  ) {
    final values = <_ResultCell>[];

    for (
      var rowIndex = programmingRowIndex + 1;
      rowIndex < rows.length;
      rowIndex++
    ) {
      final row = rows[rowIndex];
      final label = _cell(row, 0);

      if (_isProgrammingHeader(_dateHeader(row))) {
        break;
      }

      for (var columnIndex = 1; columnIndex < row.length; columnIndex++) {
        final text = _cell(row, columnIndex);
        if (text.isNotEmpty) {
          values.add(
            _ResultCell(
              rowNumber: rowIndex + 1,
              label: label,
              columnIndex: columnIndex,
              text: text,
            ),
          );
        }
      }
    }

    return values;
  }

  List<_ResultRow> _resultRows(
    List<List<String>> rows, {
    required int programmingRowIndex,
    required int columnIndex,
  }) {
    final values = <_ResultRow>[];

    for (
      var rowIndex = programmingRowIndex + 1;
      rowIndex < rows.length;
      rowIndex++
    ) {
      final row = rows[rowIndex];

      if (_isProgrammingHeader(_dateHeader(row))) {
        break;
      }

      final text = _cell(row, columnIndex);
      if (text.isNotEmpty) {
        values.add(
          _ResultRow(rowNumber: rowIndex + 1, label: _cell(row, 0), text: text),
        );
      }
    }

    return values;
  }

  String _dateHeader(List<String> row) {
    final first = _cell(row, 0);
    final second = _cell(row, 1);

    if (!_weekDayPattern.hasMatch(first) && _weekDayPattern.hasMatch(second)) {
      return first.isEmpty ? second : '$first\n$second';
    }

    return first;
  }

  bool _isProgrammingHeader(String value) {
    return _weekDayPattern.hasMatch(value) ||
        _writtenDatePattern.hasMatch(value) ||
        _numericDatePattern.hasMatch(value);
  }

  String _extractProgramDay(String value) {
    final match = _weekDayPattern.firstMatch(value);
    if (match == null) {
      return '';
    }

    return 'W${int.parse(match.group(1)!)}'
        'D${int.parse(match.group(2)!)}';
  }

  int? _weekNumber(String programDay) {
    final match = RegExp(
      r'^W(\d+)D\d+$',
      caseSensitive: false,
    ).firstMatch(programDay);

    return match == null ? null : int.parse(match.group(1)!);
  }

  String _cell(List<String> row, int columnIndex) {
    if (columnIndex >= row.length) {
      return '';
    }

    return workoutParser.normalizeText(row[columnIndex]);
  }
}

class _ResultSelection {
  final String text;
  final int rowNumber;
  final MisfitBenchmarkResultStatus status;
  final String reason;

  const _ResultSelection({
    required this.text,
    required this.rowNumber,
    required this.status,
    required this.reason,
  });

  const _ResultSelection.selected(String text, int rowNumber, String reason)
    : this(
        text: text,
        rowNumber: rowNumber,
        status: MisfitBenchmarkResultStatus.selected,
        reason: reason,
      );

  const _ResultSelection.needsReview(String reason)
    : this(
        text: '',
        rowNumber: 0,
        status: MisfitBenchmarkResultStatus.needsReview,
        reason: reason,
      );

  const _ResultSelection.excluded(String text, int rowNumber, String reason)
    : this(
        text: text,
        rowNumber: rowNumber,
        status: MisfitBenchmarkResultStatus.excluded,
        reason: reason,
      );

  const _ResultSelection.missing(String reason)
    : this(
        text: '',
        rowNumber: 0,
        status: MisfitBenchmarkResultStatus.missing,
        reason: reason,
      );
}

class _ResultRow {
  final int rowNumber;
  final String label;
  final String text;

  const _ResultRow({
    required this.rowNumber,
    required this.label,
    required this.text,
  });
}

class _ResultCell {
  final int rowNumber;
  final String label;
  final int columnIndex;
  final String text;

  const _ResultCell({
    required this.rowNumber,
    required this.label,
    required this.columnIndex,
    required this.text,
  });
}
