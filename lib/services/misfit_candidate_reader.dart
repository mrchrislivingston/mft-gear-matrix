import 'misfit_csv_service.dart';
import 'misfit_date_resolver.dart';
import 'misfit_execution_plan_parser.dart';
import 'misfit_workout_parser.dart';

class MisfitWorkoutCandidate {
  final int sourceRow;
  final int sourceColumn;
  final String dateHeader;
  final String programDay;
  final String date;
  final MisfitDateStatus dateStatus;
  final MisfitWorkoutType workoutType;
  final String prescription;
  final String modality;
  final MisfitImportStatus importStatus;
  final String statusReason;
  final MisfitResultDetail resultDetail;
  final MisfitExecutionPlan? executionPlan;
  final String programmingText;
  final String resultText;

  const MisfitWorkoutCandidate({
    required this.sourceRow,
    required this.sourceColumn,
    required this.dateHeader,
    required this.programDay,
    this.date = '',
    this.dateStatus = MisfitDateStatus.unresolved,
    required this.workoutType,
    required this.prescription,
    required this.modality,
    required this.importStatus,
    required this.statusReason,
    required this.resultDetail,
    this.executionPlan,
    required this.programmingText,
    required this.resultText,
  });
}

class MisfitCandidateSummary {
  final List<MisfitWorkoutCandidate> candidates;

  const MisfitCandidateSummary({required this.candidates});

  int countFor(MisfitImportStatus status) {
    return candidates
        .where((candidate) => candidate.importStatus == status)
        .length;
  }

  int get total => candidates.length;

  int get ready => countFor(MisfitImportStatus.ready);

  int get review => countFor(MisfitImportStatus.review);

  int get deferred => countFor(MisfitImportStatus.tbdLater);

  int get skipped => countFor(MisfitImportStatus.skip);
}

class MisfitCandidateReader {
  final MisfitWorkoutParser parser;
  final MisfitDateResolver dateResolver;
  final MisfitExecutionPlanParser executionPlanParser;

  const MisfitCandidateReader({
    this.parser = const MisfitWorkoutParser(),
    this.dateResolver = const MisfitDateResolver(),
    this.executionPlanParser = const MisfitExecutionPlanParser(),
  });

  static final RegExp _writtenDatePattern = RegExp(
    r'\b(?:Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|'
    r'May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sep(?:tember)?|'
    r'Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?)\s+\d{1,2}\b',
    caseSensitive: false,
  );

  static final RegExp _numericDatePattern = RegExp(r'\b\d{1,2}/\d{1,2}\b');

  static final RegExp _weekDayPattern = RegExp(
    r'\bW(\d+)D(\d+)\b',
    caseSensitive: false,
  );

  MisfitCandidateSummary read(MisfitCsvDocument document, {int? startYear}) {
    final dateResolution = startYear == null
        ? null
        : dateResolver.resolve(
            headers: document.rows
                .where((row) => row.isNotEmpty)
                .map((row) => parser.normalizeText(row.first)),
            startYear: startYear,
          );

    final candidates = <MisfitWorkoutCandidate>[];

    for (var rowIndex = 0; rowIndex < document.rows.length; rowIndex++) {
      final programmingRow = document.rows[rowIndex];

      if (programmingRow.isEmpty) {
        continue;
      }

      final dateHeader = parser.normalizeText(programmingRow.first);

      if (!_hasSupportedHeader(dateHeader)) {
        continue;
      }

      final programDay = _extractProgramDay(dateHeader);
      final resolvedDate = dateResolution?.dateFor(programDay);

      final resultRowIndex = rowIndex + 1;

      if (resultRowIndex >= document.rows.length) {
        continue;
      }

      final resultRow = document.rows[resultRowIndex];
      final maximumColumns = programmingRow.length > resultRow.length
          ? programmingRow.length
          : resultRow.length;

      for (var columnIndex = 1; columnIndex < maximumColumns; columnIndex++) {
        final programmingText = parser.normalizeText(
          _cell(programmingRow, columnIndex),
        );

        if (programmingText.isEmpty ||
            !parser.isRelevantWorkout(programmingText)) {
          continue;
        }

        final resultText = parser.normalizeText(_cell(resultRow, columnIndex));

        final workoutType = parser.detectWorkoutType(programmingText);
        var classification = parser.classifyCandidate(
          programmingText: programmingText,
          resultText: resultText,
        );
        var modalities = parser.detectCandidateModalities(
          programmingText: programmingText,
          resultText: resultText,
        );

        final resolvedErgModality = _resolveAmbiguousErgModality(
          workoutType: workoutType,
          modalities: modalities,
          resultText: resultText,
        );

        if (resolvedErgModality != null) {
          modalities = [resolvedErgModality];

          if (classification.status == MisfitImportStatus.tbdLater) {
            classification = const MisfitClassification(
              status: MisfitImportStatus.ready,
              reason:
                  'Result duration, pace, and distance identify the modality',
            );
          }
        }

        final candidate = MisfitWorkoutCandidate(
          sourceRow: rowIndex + 1,
          sourceColumn: columnIndex + 1,
          dateHeader: dateHeader,
          programDay: programDay,
          date: resolvedDate?.date ?? '',
          dateStatus: resolvedDate?.status ?? MisfitDateStatus.unresolved,
          workoutType: workoutType,
          prescription: _prescriptionText(workoutType, programmingText),
          modality: modalities.join('/'),
          importStatus: classification.status,
          statusReason: classification.reason,
          resultDetail: parser.detectResultDetail(resultText),
          executionPlan: executionPlanParser.extract(programmingText),
          programmingText: programmingText,
          resultText: resultText,
        );

        candidates.addAll(_expandMixedGearCandidate(candidate));
      }
    }

    return MisfitCandidateSummary(candidates: List.unmodifiable(candidates));
  }

  List<MisfitWorkoutCandidate> _expandMixedGearCandidate(
    MisfitWorkoutCandidate candidate,
  ) {
    if (candidate.workoutType != MisfitWorkoutType.gear ||
        candidate.importStatus != MisfitImportStatus.tbdLater ||
        candidate.statusReason != 'Mixed-gear workout' ||
        candidate.modality.isEmpty ||
        candidate.modality.contains('/')) {
      return [candidate];
    }

    final gears = parser.detectGears(candidate.programmingText);
    final planMatches = RegExp(
      r'\bAMRAP\s+(\d{1,2}:\d{2})\s*[x×]\s*(\d+)\b',
      caseSensitive: false,
    ).allMatches(candidate.programmingText).toList();

    final hasSupportedHeader = RegExp(
      r'\bDist(?:ance)?\s*/\s*Watts?\s*/\s*Cals?\s*/\s*Pace\b',
      caseSensitive: false,
    ).hasMatch(candidate.resultText);

    final resultMatches = RegExp(
      r'^\s*(\d+(?:\.\d+)?)\s*/\s*(\d+)\s*/\s*(\d+)\s*/\s*'
      r'(\d{1,2}:\d{2}(?:\.\d+)?)\s*$',
      caseSensitive: false,
      multiLine: true,
    ).allMatches(candidate.resultText).toList();

    if (!hasSupportedHeader ||
        gears.length < 2 ||
        gears.length != planMatches.length) {
      return [candidate];
    }

    final expectedResultCount = planMatches.fold<int>(
      0,
      (total, match) => total + int.parse(match.group(2)!),
    );

    if (resultMatches.length != expectedResultCount) {
      return [candidate];
    }

    final trailingNotes = candidate.resultText
        .substring(resultMatches.last.end)
        .trim();
    final expanded = <MisfitWorkoutCandidate>[];
    var resultIndex = 0;

    for (var index = 0; index < gears.length; index++) {
      final planMatch = planMatches[index];
      final intervalCount = int.parse(planMatch.group(2)!);
      final selectedResults = resultMatches.sublist(
        resultIndex,
        resultIndex + intervalCount,
      );
      resultIndex += intervalCount;

      final splitResult = [
        'Dist/Watts/Cals/Pace',
        for (final match in selectedResults) match.group(0)!.trim(),
        if (trailingNotes.isNotEmpty) trailingNotes,
      ].join('\n');

      expanded.add(
        MisfitWorkoutCandidate(
          sourceRow: candidate.sourceRow,
          sourceColumn: candidate.sourceColumn,
          dateHeader: candidate.dateHeader,
          programDay: candidate.programDay,
          date: candidate.date,
          dateStatus: candidate.dateStatus,
          workoutType: candidate.workoutType,
          prescription: 'G${gears[index]}',
          modality: candidate.modality,
          importStatus: MisfitImportStatus.ready,
          statusReason: 'Split from a mixed-gear workout',
          resultDetail: MisfitResultDetail.intervalResults,
          executionPlan: MisfitExecutionPlan(
            intervalCount: intervalCount,
            workDuration: planMatch.group(1)!,
          ),
          programmingText: candidate.programmingText,
          resultText: splitResult,
        ),
      );
    }

    return expanded;
  }

  String? _resolveAmbiguousErgModality({
    required MisfitWorkoutType workoutType,
    required List<String> modalities,
    required String resultText,
  }) {
    if (workoutType != MisfitWorkoutType.zone ||
        modalities.length != 2 ||
        !modalities.contains('row') ||
        !modalities.contains('bikeErg')) {
      return null;
    }

    final durationMatch = RegExp(
      r'\b(\d{1,3}):(\d{2})\s+in\s+(?:zone\s*)?z?2\b',
      caseSensitive: false,
    ).firstMatch(resultText);
    final paceMatch = RegExp(
      r'\bAvg\s+Pace\s*[-:]\s*(\d{1,2}):(\d{2}(?:\.\d+)?)\b',
      caseSensitive: false,
    ).firstMatch(resultText);
    final distanceMatch = RegExp(
      r'\bDistance\s*[-:]\s*(\d+(?:\.\d+)?)\s*KM\b',
      caseSensitive: false,
    ).firstMatch(resultText);

    if (durationMatch == null || paceMatch == null || distanceMatch == null) {
      return null;
    }

    final durationSeconds =
        int.parse(durationMatch.group(1)!) * 60 +
        int.parse(durationMatch.group(2)!);
    final paceSeconds =
        int.parse(paceMatch.group(1)!) * 60 + double.parse(paceMatch.group(2)!);
    final recordedKilometers = double.parse(distanceMatch.group(1)!);

    if (durationSeconds <= 0 || paceSeconds <= 0 || recordedKilometers <= 0) {
      return null;
    }

    final expectedBikeKilometers = durationSeconds / paceSeconds;
    final expectedRowKilometers = expectedBikeKilometers * 0.5;
    final bikeError =
        (recordedKilometers - expectedBikeKilometers).abs() /
        recordedKilometers;
    final rowError =
        (recordedKilometers - expectedRowKilometers).abs() / recordedKilometers;

    const tolerance = 0.08;

    if (bikeError <= tolerance && bikeError < rowError) {
      return 'bikeErg';
    }

    if (rowError <= tolerance && rowError < bikeError) {
      return 'row';
    }

    return null;
  }

  bool _hasSupportedHeader(String value) {
    return _writtenDatePattern.hasMatch(value) ||
        _numericDatePattern.hasMatch(value) ||
        _weekDayPattern.hasMatch(value);
  }

  String _extractProgramDay(String value) {
    final match = _weekDayPattern.firstMatch(value);

    if (match == null) {
      return '';
    }

    return 'W${int.parse(match.group(1)!)}'
        'D${int.parse(match.group(2)!)}';
  }

  String _prescriptionText(
    MisfitWorkoutType workoutType,
    String programmingText,
  ) {
    switch (workoutType) {
      case MisfitWorkoutType.gear:
        return parser
            .detectGears(programmingText)
            .map((number) => 'G$number')
            .join('/');
      case MisfitWorkoutType.power:
        return parser
            .detectPowerPrescriptions(programmingText)
            .map((number) => 'P$number')
            .join('/');
      case MisfitWorkoutType.zone:
        return parser
            .detectZonePrescriptions(programmingText)
            .map((number) => 'Z$number')
            .join('/');
      case MisfitWorkoutType.unknown:
        return '';
    }
  }

  String _cell(List<String> row, int columnIndex) {
    if (columnIndex >= row.length) {
      return '';
    }

    return row[columnIndex];
  }
}
